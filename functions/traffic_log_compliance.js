const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin (ถ้ายังไม่ได้ initialize)
if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

/**
 * Cloud Function สำหรับทำความสะอาด Traffic Logs เก่า
 * ตาม พ.ร.บ.คอมพิวเตอร์ 2560 มาตรา 26 - เก็บไว้ 90 วัน
 * 
 * Schedule: ทุกวันตี 2 นาฬิกา (เวลาไทย)
 */
exports.cleanupTrafficLogs = functions
  .region('asia-southeast1') // ใช้ region เอเชียตะวันออกเฉียงใต้
  .pubsub
  .schedule('0 2 * * *') // ทุกวันตี 2
  .timeZone('Asia/Bangkok')
  .onRun(async (context) => {
    console.log('🧹 Starting traffic logs cleanup process...');
    
    try {
      // คำนวณวันที่ cutoff (90 วันที่แล้ว)
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - 90);
      
      console.log(`📅 Cutoff date: ${cutoffDate.toISOString()}`);
      console.log(`🗓️ Will delete logs older than: ${cutoffDate.toLocaleDateString('th-TH')}`);
      
      // Query logs ที่เก่ากว่า 90 วัน
      const oldLogsQuery = firestore
        .collection('traffic_logs')
        .where('timestamp', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
        .limit(500); // จำกัดการลบทีละ 500 records เพื่อป้องกัน timeout
      
      const oldLogsSnapshot = await oldLogsQuery.get();
      
      if (oldLogsSnapshot.empty) {
        console.log('✅ No old traffic logs found - cleanup not needed');
        return null;
      }
      
      console.log(`🗑️ Found ${oldLogsSnapshot.size} old traffic logs to delete`);
      
      // ใช้ batch delete เพื่อประสิทธิภาพ
      const batch = firestore.batch();
      let deleteCount = 0;
      
      oldLogsSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
        deleteCount++;
      });
      
      // Execute batch delete
      await batch.commit();
      
      console.log(`✅ Successfully deleted ${deleteCount} old traffic logs`);
      
      // สร้าง audit log สำหรับการลบข้อมูล
      const auditLogEntry = {
        action: 'traffic_logs_cleanup',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        deleted_count: deleteCount,
        cutoff_date: admin.firestore.Timestamp.fromDate(cutoffDate),
        function_name: 'cleanupTrafficLogs',
        status: 'success',
        compliance_note: 'พ.ร.บ.คอมพิวเตอร์ 2560 มาตรา 26 - เก็บข้อมูล 90 วัน',
      };
      
      await firestore.collection('audit_logs').add(auditLogEntry);
      console.log('📝 Audit log created for cleanup operation');
      
      // ถ้ายังมี logs เก่าอยู่ ให้ schedule การรันครั้งต่อไป
      if (oldLogsSnapshot.size === 500) {
        console.log('⏰ More old logs detected - will run again in next schedule');
      }
      
      return null;
      
    } catch (error) {
      console.error('❌ Error during traffic logs cleanup:', error);
      
      // สร้าง error audit log
      const errorAuditEntry = {
        action: 'traffic_logs_cleanup',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        status: 'error',
        error_message: error.message,
        function_name: 'cleanupTrafficLogs',
      };
      
      try {
        await firestore.collection('audit_logs').add(errorAuditEntry);
      } catch (auditError) {
        console.error('❌ Failed to create error audit log:', auditError);
      }
      
      throw new functions.https.HttpsError('internal', 'Traffic logs cleanup failed');
    }
  });

/**
 * Cloud Function สำหรับดูสถิติ Traffic Logs (Admin only)
 */
exports.getTrafficLogsStats = functions
  .region('asia-southeast1')
  .https
  .onCall(async (data, context) => {
    // ตรวจสอบการ authentication และ admin role
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    // ตรวจสอบว่าเป็น admin หรือไม่ (ปรับตาม business logic ของคุณ)
    const userDoc = await firestore.collection('users').doc(context.auth.uid).get();
    const userData = userDoc.data();
    
    if (!userData || userData.role !== 'admin') {
      throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }
    
    try {
      const { startDate, endDate } = data;
      
      // Default period: ล่าสุด 30 วัน
      const defaultEndDate = new Date();
      const defaultStartDate = new Date();
      defaultStartDate.setDate(defaultStartDate.getDate() - 30);
      
      const queryStartDate = startDate ? new Date(startDate) : defaultStartDate;
      const queryEndDate = endDate ? new Date(endDate) : defaultEndDate;
      
      console.log(`📊 Getting stats for period: ${queryStartDate.toISOString()} to ${queryEndDate.toISOString()}`);
      
      // Query traffic logs ในช่วงเวลาที่กำหนด
      const logsSnapshot = await firestore
        .collection('traffic_logs')
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(queryStartDate))
        .where('timestamp', '<=', admin.firestore.Timestamp.fromDate(queryEndDate))
        .get();
      
      // วิเคราะห์ข้อมูล
      const stats = {
        total_events: logsSnapshot.size,
        unique_users: new Set(),
        action_breakdown: {},
        platform_breakdown: { android: 0, ios: 0, unknown: 0 },
        daily_breakdown: {},
      };
      
      logsSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        
        // นับ unique users
        if (data.user_id_hash && data.user_id_hash !== 'anonymous') {
          stats.unique_users.add(data.user_id_hash);
        }
        
        // นับ actions
        if (data.action) {
          stats.action_breakdown[data.action] = (stats.action_breakdown[data.action] || 0) + 1;
        }
        
        // นับ platforms
        const platform = data.device_info?.platform || 'unknown';
        stats.platform_breakdown[platform] = (stats.platform_breakdown[platform] || 0) + 1;
        
        // นับรายวัน
        if (data.timestamp) {
          const day = data.timestamp.toDate().toISOString().split('T')[0];
          stats.daily_breakdown[day] = (stats.daily_breakdown[day] || 0) + 1;
        }
      });
      
      // แปลง Set เป็น number
      stats.unique_users = stats.unique_users.size;
      
      // เพิ่มข้อมูล metadata
      stats.query_period = {
        start: queryStartDate.toISOString(),
        end: queryEndDate.toISOString(),
        days: Math.ceil((queryEndDate - queryStartDate) / (1000 * 60 * 60 * 24)),
      };
      
      stats.compliance_info = {
        law: 'พ.ร.บ.คอมพิวเตอร์ 2560 มาตรา 26',
        retention_period_days: 90,
        data_anonymization: 'User IDs และ Device IDs ถูก hash',
        location_privacy: 'พิกัดถูกปัดเศษเป็นระดับเขต/อำเภอ',
      };
      
      console.log(`✅ Generated stats: ${stats.total_events} events, ${stats.unique_users} unique users`);
      
      return stats;
      
    } catch (error) {
      console.error('❌ Error getting traffic logs stats:', error);
      throw new functions.https.HttpsError('internal', 'Failed to get traffic logs statistics');
    }
  });

/**
 * Cloud Function สำหรับการ Export Traffic Logs (Admin only, for legal compliance)
 */
exports.exportTrafficLogs = functions
  .region('asia-southeast1')
  .https
  .onCall(async (data, context) => {
    // ตรวจสอบการ authentication และ admin role
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const userDoc = await firestore.collection('users').doc(context.auth.uid).get();
    const userData = userDoc.data();
    
    if (!userData || userData.role !== 'admin') {
      throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }
    
    try {
      const { startDate, endDate, requestReason } = data;
      
      if (!requestReason) {
        throw new functions.https.HttpsError('invalid-argument', 'Request reason is required');
      }
      
      // Log การ export เพื่อ audit trail
      const exportAuditEntry = {
        action: 'traffic_logs_export_request',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        requested_by: context.auth.uid,
        request_reason: requestReason,
        date_range: { startDate, endDate },
        compliance_note: 'Export ตามคำร้องขอของหน่วยงานราชการ',
      };
      
      await firestore.collection('audit_logs').add(exportAuditEntry);
      
      // ส่งกลับข้อมูลที่จำเป็นเท่านั้น (ไม่ include sensitive data)
      const exportData = {
        message: 'Export request logged successfully',
        audit_trail_id: exportAuditEntry.id,
        note: 'ข้อมูลจริงจะถูกส่งผ่านช่องทางปลอดภัยตามขั้นตอนของกฎหมาย',
        contact_info: {
          email: 'admin@checkdarn.app',
          phone: '+66-xxx-xxx-xxxx',
        },
      };
      
      console.log(`📤 Export request logged by user: ${context.auth.uid}, reason: ${requestReason}`);
      
      return exportData;
      
    } catch (error) {
      console.error('❌ Error processing export request:', error);
      throw new functions.https.HttpsError('internal', 'Failed to process export request');
    }
  });
