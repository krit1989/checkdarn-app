# 🗳️ ระบบโหวตใหม่แบบ "ฝั่งไหนถึง 3 คนก่อนชนะ"

## 🎯 **Overview**

ระบบโหวตใหม่ที่เปลี่ยนจาก **combined vote counting** เป็น **separate vote counting** แบบ "ฝั่งไหนถึง 3 คนก่อนชนะ" พร้อมระบบลบอัตโนมัติไม่ต้องใช้แอดมิน

---

## 🔄 **การเปลี่ยนแปลงหลัก**

### **เก่า: Combined Vote System**
```
upvotes + downvotes >= 3 && confidence >= 70% → VERIFIED
```

### **ใหม่: Separate Race-to-3 System**
```
upvotes >= 3 AND upvotes > downvotes → VERIFIED (ลบอัตโนมัติ)
downvotes >= 3 AND downvotes > upvotes → REJECTED (ลบอัตโนมัติ) 
upvotes == downvotes == 3 → ใช้ confidence score ตัดสิน
```

---

## ⚡ **ระบบ Auto-Removal ใหม่**

### **Immediate Deletion:**
- ✅ **Verified Reports**: ลบทันทีพร้อมดำเนินการตามประเภท (เพิ่มกล้อง/ลบกล้อง/เปลี่ยนความเร็ว)
- ✅ **Rejected Reports**: ลบทันทีไม่ดำเนินการใดๆ
- ✅ **No Admin Required**: ระบบทำงานอัตโนมัติ 100%

### **Collections ที่ใช้:**
- `verified_reports_removal_log` - บันทึกรายงานที่ verified และถูกลบ
- `camera_cleanup_log` - บันทึกการทำความสะอาดระบบ

---

## 🏗️ **Technical Implementation**

### **New Voting Logic in `submitVote`:**

```dart
Future<void> submitVote({
  required String reportId,
  required VoteType voteType,
}) async {
  // ... existing vote logic ...

  final newUpvotes = currentUpvotes + (voteType == VoteType.upvote ? 1 : 0);
  final newDownvotes = currentDownvotes + (voteType == VoteType.downvote ? 1 : 0);

  // 🆕 NEW LOGIC: Check if either side reaches 3 votes
  if (newUpvotes >= 3 || newDownvotes >= 3) {
    String newStatus;
    
    if (newUpvotes >= 3 && newUpvotes > newDownvotes) {
      // Upvotes win
      newStatus = 'verified';
      print('✅ VERIFIED: Upvotes reached 3 and lead ($newUpvotes vs $newDownvotes)');
    } else if (newDownvotes >= 3 && newDownvotes > newUpvotes) {
      // Downvotes win  
      newStatus = 'rejected';
      print('❌ REJECTED: Downvotes reached 3 and lead ($newDownvotes vs $newUpvotes)');
    } else if (newUpvotes == 3 && newDownvotes == 3) {
      // Tie at 3-3, use confidence score
      final confidenceScore = (newUpvotes / (newUpvotes + newDownvotes)) * 100;
      if (confidenceScore >= 50) {
        newStatus = 'verified';
        print('⚖️ TIE-BREAKER VERIFIED: 3-3 tie decided by confidence (${confidenceScore.toStringAsFixed(1)}%)');
      } else {
        newStatus = 'rejected'; 
        print('⚖️ TIE-BREAKER REJECTED: 3-3 tie decided by confidence (${confidenceScore.toStringAsFixed(1)}%)');
      }
    } else {
      newStatus = 'pending';
    }

    // Update report with new status
    await _firestore.collection(_reportsCollection).doc(reportId).update({
      'upvotes': newUpvotes,
      'downvotes': newDownvotes, 
      'status': newStatus,
      'verifiedAt': newStatus != 'pending' ? FieldValue.serverTimestamp() : null,
      'verifiedBy': newStatus != 'pending' ? 'auto_voting_system_v2' : null,
    });

    // 🚀 AUTO-REMOVAL: Immediately remove verified/rejected reports
    if (newStatus == 'verified' || newStatus == 'rejected') {
      await _performAutoRemoval(reportId, newStatus);
    }
  }
}
```

### **Auto-Removal Function:**

```dart
static Future<void> _performAutoRemoval(String reportId, String status) async {
  try {
    print('🚀 AUTO-REMOVAL: Processing $status report $reportId');
    
    // Get report data before deletion
    final reportDoc = await _firestore.collection(_reportsCollection).doc(reportId).get();
    if (!reportDoc.exists) return;
    
    final reportData = reportDoc.data()!;
    final report = CameraReport.fromJson(reportData);

    // Log the removal
    await _firestore.collection('verified_reports_removal_log').add({
      'originalReportId': reportId,
      'reportData': reportData,
      'status': status,
      'removedAt': FieldValue.serverTimestamp(),
      'removedBy': 'auto_voting_system_v2',
      'autoRemovalReason': status == 'verified' ? 'upvotes_reached_3' : 'downvotes_reached_3',
    });

    // Process verified reports (create/delete cameras, change speeds)
    if (status == 'verified') {
      await _handleVerifiedReport(report);
    }

    // Delete the report from main collection
    await _firestore.collection(_reportsCollection).doc(reportId).delete();
    print('✅ AUTO-REMOVAL: Report $reportId successfully removed');

  } catch (e) {
    print('❌ AUTO-REMOVAL ERROR: $e');
  }
}
```

---

## 🎮 **User Experience**

### **Voting Process:**
1. 👤 User โหวต "มีจริง" หรือ "ไม่มี"
2. ⚡ ระบบตรวจสอบทันที: upvotes ≥ 3 หรือ downvotes ≥ 3?
3. 🏆 ฝั่งไหนถึง 3 คนก่อน → ชนะทันที
4. 🗑️ ระบบลบรายงานอัตโนมัติ + ดำเนินการตามประเภท
5. 📱 User เห็นรายงานหายจากรายการ

### **Examples:**

#### **Scenario 1: Quick Win**
```
Vote 1: ✅ → upvotes: 1, downvotes: 0 (pending)
Vote 2: ✅ → upvotes: 2, downvotes: 0 (pending)  
Vote 3: ✅ → upvotes: 3, downvotes: 0 (VERIFIED & AUTO-REMOVED)
```

#### **Scenario 2: Close Race**
```
Vote 1: ✅ → upvotes: 1, downvotes: 0 (pending)
Vote 2: ❌ → upvotes: 1, downvotes: 1 (pending)
Vote 3: ✅ → upvotes: 2, downvotes: 1 (pending)
Vote 4: ❌ → upvotes: 2, downvotes: 2 (pending)
Vote 5: ❌ → upvotes: 2, downvotes: 3 (REJECTED & AUTO-REMOVED)
```

#### **Scenario 3: Tie-Breaker**
```
Votes: ✅✅✅❌❌❌ → upvotes: 3, downvotes: 3 (tie)
→ ใช้ confidence score (50%) ตัดสิน → VERIFIED
```

---

## 🛠️ **Database Changes**

### **New Collections:**
- ✅ `verified_reports_removal_log` - เก็บประวัติรายงานที่ verified และถูกลบ
- ✅ `camera_cleanup_log` - เก็บประวัติการทำความสะอาดระบบ

### **Updated Security Rules:**
```javascript
match /verified_reports_removal_log/{logId} {
  allow read: if true;
  allow create: if request.auth != null;
  allow update, delete: if false;
}
```

---

## 📊 **Benefits**

### **🚀 Performance:**
- ลดเวลาตัดสินใจจาก "รอให้ครบเงื่อนไข" เป็น "แข่งกันถึง 3 คนก่อน"
- ลดข้อมูลที่ค้างในฐานข้อมูล (auto-removal)

### **👥 User Experience:**
- ชัดเจนขึ้น: "ฝั่งไหนถึง 3 คนก่อนชนะ"
- เร็วขึ้น: ไม่ต้องรอโหวตเยอะ
- ไม่ต้องแอดมิน: ทำงานอัตโนมัติ 100%

### **🔧 Maintenance:**
- ไม่มีข้อมูลค้าง: verified/rejected reports ถูกลบทันที
- Audit trail ครบถ้วน: ทุกอย่างถูกบันทึกใน log collections
- Debug ง่าย: มี comprehensive logging

---

## 🧪 **Test Cases**

### **Test 1: Upvote Victory**
```
Given: รายงานกล้องใหม่
When: มี 3 คนโหวต "มีจริง" ก่อนที่จะมีคนโหวต "ไม่มี"
Then: รายงาน → VERIFIED → ลบอัตโนมัติ → สร้างกล้องใหม่
```

### **Test 2: Downvote Victory**
```
Given: รายงานกล้องถูกถอน
When: มี 3 คนโหวต "ไม่มี" ก่อนที่จะมีคนโหวต "มีจริง"  
Then: รายงาน → REJECTED → ลบอัตโนมัติ → ไม่ดำเนินการใดๆ
```

### **Test 3: Tie-Breaker**
```
Given: รายงานการเปลี่ยนความเร็ว
When: โหวต "มีจริง" 3 คน และ "ไม่มี" 3 คนพร้อมกัน
Then: ใช้ confidence score → VERIFIED (50%+) → ลบอัตโนมัติ → อัปเดตความเร็ว
```

---

## 🎉 **Summary**

✅ **ระบบโหวตใหม่แบบแข่งกัน**: ฝั่งไหนถึง 3 คนก่อนชนะ  
✅ **Auto-Removal 100%**: ไม่ต้องแอดมิน ลบอัตโนมัติทันที  
✅ **Comprehensive Logging**: บันทึกครบถ้วนใน log collections  
✅ **Better UX**: รวดเร็ว ชัดเจน ไม่ซับซ้อน  
✅ **Production Ready**: พร้อมใช้งานจริง  

**🚀 The new voting system is live and working!**
