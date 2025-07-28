const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// ========== Camera Report Management Functions ==========

/**
 * จัดการการโหวตและอัปเดต confidence score
 */
exports.onVoteSubmitted = functions.firestore
  .document('camera_votes/{voteId}')
  .onCreate(async (snap, context) => {
    const vote = snap.data();
    const reportId = vote.reportId;
    
    try {
      await db.runTransaction(async (transaction) => {
        const reportRef = db.collection('camera_reports').doc(reportId);
        const reportDoc = await transaction.get(reportRef);
        
        if (!reportDoc.exists) {
          throw new Error('Report not found');
        }
        
        const report = reportDoc.data();
        
        // คำนวณคะแนนโหวตใหม่
        const newUpvotes = vote.voteType === 'upvote' ? (report.upvotes || 0) + 1 : (report.upvotes || 0);
        const newDownvotes = vote.voteType === 'downvote' ? (report.downvotes || 0) + 1 : (report.downvotes || 0);
        const totalVotes = newUpvotes + newDownvotes;
        const confidenceScore = totalVotes > 0 ? newUpvotes / totalVotes : 0;
        
        // กำหนดสถานะใหม่
        let newStatus = report.status || 'pending';
        let verifiedAt = null;
        let verifiedBy = null;
        
        // Auto-verification rules
        if (totalVotes >= 5) {
          if (confidenceScore >= 0.8) {
            newStatus = 'verified';
            verifiedAt = admin.firestore.FieldValue.serverTimestamp();
            verifiedBy = 'auto_system';
          } else if (confidenceScore <= 0.2) {
            newStatus = 'rejected';
            verifiedAt = admin.firestore.FieldValue.serverTimestamp();
            verifiedBy = 'auto_system';
          }
        }
        
        // อัปเดตรายงาน
        const updateData = {
          upvotes: newUpvotes,
          downvotes: newDownvotes,
          confidenceScore: confidenceScore,
          status: newStatus,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };
        
        if (verifiedAt) {
          updateData.verifiedAt = verifiedAt;
          updateData.verifiedBy = verifiedBy;
        }
        
        transaction.update(reportRef, updateData);
        
        // อัปเดตสถิติผู้ใช้
        const userStatsRef = db.collection('user_report_stats').doc(vote.userId);
        transaction.set(userStatsRef, {
          votes_submitted: admin.firestore.FieldValue.increment(1),
          total_contributions: admin.firestore.FieldValue.increment(1),
          last_activity: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
        
        console.log(`Vote processed for report ${reportId}: ${vote.voteType}, new confidence: ${confidenceScore.toFixed(2)}, status: ${newStatus}`);
        
        // ถ้า verified แล้วให้ promote ไปยัง main database
        if (newStatus === 'verified' && report.type === 'newCamera') {
          await promoteToMainDatabase(report, reportId, transaction);
        }
      });
      
    } catch (error) {
      console.error('Error processing vote:', error);
      throw error;
    }
  });

/**
 * จัดการการส่งรายงานใหม่
 */
exports.onReportSubmitted = functions.firestore
  .document('camera_reports/{reportId}')
  .onCreate(async (snap, context) => {
    const report = snap.data();
    const userId = report.reportedBy;
    
    try {
      // อัปเดตสถิติผู้ใช้
      const userStatsRef = db.collection('user_report_stats').doc(userId);
      await userStatsRef.set({
        reports_submitted: admin.firestore.FieldValue.increment(1),
        total_contributions: admin.firestore.FieldValue.increment(1),
        last_activity: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      
      // ตรวจสอบ duplicate reports
      await checkDuplicateReports(report, context.params.reportId);
      
      console.log(`New report submitted: ${context.params.reportId} by ${userId}`);
      
    } catch (error) {
      console.error('Error processing new report:', error);
    }
  });

/**
 * Promote verified report to main speed camera database
 */
async function promoteToMainDatabase(report, reportId, transaction) {
  if (report.type !== 'newCamera') return;
  
  const speedCameraRef = db.collection('speed_cameras').doc();
  const speedCameraData = {
    id: speedCameraRef.id,
    latitude: report.latitude,
    longitude: report.longitude,
    speedLimit: report.speedLimit,
    roadName: report.roadName,
    type: 'fixed',
    isActive: true,
    description: `Community verified camera (${(report.confidenceScore * 100).toFixed(0)}% confidence)`,
    source: 'community_verified',
    sourceReportId: reportId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };
  
  transaction.set(speedCameraRef, speedCameraData);
  
  console.log(`Promoted report ${reportId} to main database as camera ${speedCameraRef.id}`);
}

/**
 * ตรวจสอบรายงานที่ซ้ำกัน
 */
async function checkDuplicateReports(newReport, newReportId) {
  const nearbyReports = await db.collection('camera_reports')
    .where('latitude', '>=', newReport.latitude - 0.001)
    .where('latitude', '<=', newReport.latitude + 0.001)
    .get();
  
  for (const doc of nearbyReports.docs) {
    if (doc.id === newReportId) continue;
    
    const report = doc.data();
    const distance = calculateDistance(
      newReport.latitude, newReport.longitude,
      report.latitude, report.longitude
    );
    
    // ถ้าใกล้กันเกินไป (50 เมตร) ให้ mark เป็น duplicate
    if (distance < 50) {
      await db.collection('camera_reports').doc(newReportId).update({
        status: 'duplicate',
        duplicateOf: doc.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`Report ${newReportId} marked as duplicate of ${doc.id}`);
      break;
    }
  }
}

/**
 * คำนวณระยะทางระหว่างสองจุด (เมตร)
 */
function calculateDistance(lat1, lng1, lat2, lng2) {
  const earthRadius = 6371000; // รัศมีโลกเป็นเมตร
  
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
           Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
           Math.sin(dLng / 2) * Math.sin(dLng / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadius * c;
}

// ========== Maintenance Functions ==========

/**
 * ล้างข้อมูลเก่าที่ไม่จำเป็น (รันทุก 24 ชั่วโมง)
 */
exports.dailyCleanup = functions.pubsub
  .schedule('0 2 * * *') // 02:00 น. ทุกวัน
  .timeZone('Asia/Bangkok')
  .onRun(async (context) => {
    try {
      // ลบ reports ที่ถูก reject และเก่ากว่า 30 วัน
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const oldRejectedReports = await db.collection('camera_reports')
        .where('status', '==', 'rejected')
        .where('reportedAt', '<', thirtyDaysAgo)
        .get();
      
      const batch = db.batch();
      oldRejectedReports.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      if (oldRejectedReports.docs.length > 0) {
        await batch.commit();
        console.log(`Cleaned up ${oldRejectedReports.docs.length} old rejected reports`);
      }
      
      // ลบ votes ที่เกี่ยวข้องกับ reports ที่ถูกลบ
      await cleanupOrphanedVotes();
      
    } catch (error) {
      console.error('Error in daily cleanup:', error);
    }
  });

/**
 * ลบ votes ที่ไม่มี report แล้ว
 */
async function cleanupOrphanedVotes() {
  const allVotes = await db.collection('camera_votes').get();
  const reportIds = new Set();
  
  // รวบรวม report IDs ที่มีอยู่
  const reports = await db.collection('camera_reports').select('id').get();
  reports.docs.forEach(doc => reportIds.add(doc.id));
  
  const batch = db.batch();
  let orphanedCount = 0;
  
  allVotes.docs.forEach(voteDoc => {
    const vote = voteDoc.data();
    if (!reportIds.has(vote.reportId)) {
      batch.delete(voteDoc.ref);
      orphanedCount++;
    }
  });
  
  if (orphanedCount > 0) {
    await batch.commit();
    console.log(`Cleaned up ${orphanedCount} orphaned votes`);
  }
}

// ========== Analytics Functions ==========

/**
 * สร้างรายงานสถิติรายวัน
 */
exports.generateDailyStats = functions.pubsub
  .schedule('0 23 * * *') // 23:00 น. ทุกวัน
  .timeZone('Asia/Bangkok')
  .onRun(async (context) => {
    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);
      
      // นับรายงานใหม่วันนี้
      const newReports = await db.collection('camera_reports')
        .where('reportedAt', '>=', today)
        .where('reportedAt', '<', tomorrow)
        .get();
      
      // นับ votes วันนี้
      const newVotes = await db.collection('camera_votes')
        .where('votedAt', '>=', today)
        .where('votedAt', '<', tomorrow)
        .get();
      
      // นับ verifications วันนี้
      const verifiedReports = await db.collection('camera_reports')
        .where('verifiedAt', '>=', today)
        .where('verifiedAt', '<', tomorrow)
        .where('status', '==', 'verified')
        .get();
      
      // บันทึกสถิติ
      const statsRef = db.collection('daily_stats').doc(today.toISOString().split('T')[0]);
      await statsRef.set({
        date: today,
        newReports: newReports.size,
        newVotes: newVotes.size,
        verifiedReports: verifiedReports.size,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`Daily stats generated: ${newReports.size} reports, ${newVotes.size} votes, ${verifiedReports.size} verified`);
      
    } catch (error) {
      console.error('Error generating daily stats:', error);
    }
  });

// ========== Admin Functions ==========

/**
 * ฟังก์ชันสำหรับ admin ในการ force verify/reject
 */
exports.adminUpdateReportStatus = functions.https.onCall(async (data, context) => {
  // ตรวจสอบสิทธิ์ admin
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }
  
  const { reportId, status, reason } = data;
  
  if (!reportId || !status) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }
  
  try {
    const reportRef = db.collection('camera_reports').doc(reportId);
    await reportRef.update({
      status: status,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      verifiedBy: context.auth.uid,
      adminReason: reason || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log(`Admin ${context.auth.uid} updated report ${reportId} to ${status}`);
    
    return { success: true };
    
  } catch (error) {
    console.error('Error updating report status:', error);
    throw new functions.https.HttpsError('internal', 'Failed to update report status');
  }
});
