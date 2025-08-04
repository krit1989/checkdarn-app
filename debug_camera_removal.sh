#!/bin/bash

# Debug script สำหรับตรวจสอบปัญหา AUTO-PROMOTION
# ใช้ตรวจสอบว่าทำไมกล้องไม่หายจากแผนที่

echo "🔍 === CAMERA REMOVAL DEBUG CHECKLIST ==="
echo ""

echo "📋 Step 1: ตรวจสอบ Firebase Console"
echo "   1. เปิด Firebase Console → Firestore Database"
echo "   2. ดู collection 'camera_reports'"  
echo "   3. หารายงานที่มี status = 'verified'"
echo "   4. ตรวจสอบว่ามี selectedCameraId หรือไม่"
echo "   5. ดู collection 'camera_removal_failures' (ถ้ามี error)"
echo ""

echo "📋 Step 2: ตรวจสอบ speed_cameras collection" 
echo "   1. เปิด Firebase Console → speed_cameras collection"
echo "   2. หากล้องที่ควรถูกลบ (ตามตำแหน่งที่โหวต)"
echo "   3. ถ้ายังมี = AUTO-PROMOTION ล้มเหลว"
echo "   4. ถ้าไม่มีแล้ว = ปัญหา UI refresh"
echo ""

echo "📋 Step 3: ตรวจสอบ Logs ใน Console"
echo "   เปิด VS Code → Terminal → flutter logs หรือ adb logcat"
echo "   หาข้อความเหล่านี้:"
echo "   ✅ '🚀 AUTO-PROMOTION: Report auto-verified, promoting to main database...'"
echo "   ✅ '🗑️ === ATOMIC CAMERA REMOVAL PROTOCOL ==='"
echo "   ✅ '✅ Atomic Camera Removal completed successfully'"
echo "   ❌ '❌ AUTO-PROMOTION FAILED:' (ถ้ามี error)"
echo ""

echo "📋 Step 4: ตรวจสอบ selectedCameraId"
echo "   ปัญหาที่พบบ่อย: รายงานไม่มี selectedCameraId"
echo "   → ต้องใช้ location-based search"
echo "   → อาจหากล้องไม่เจอในรัศมี 100m"
echo ""

echo "📋 Step 5: Debug Commands"
echo "   Run these commands to check:"
echo "   1. flutter logs --verbose"
echo "   2. adb logcat | grep -E 'AUTO-PROMOTION|CAMERA REMOVAL'"
echo "   3. Force close + restart app"
echo "   4. Clear app cache/data"
echo ""

echo "🎯 === MOST LIKELY CAUSES ==="
echo "   1. selectedCameraId = null → location search fails"
echo "   2. Firebase permissions denied for speed_cameras"  
echo "   3. Network timeout during deletion"
echo "   4. App cache not refreshing after deletion"
echo ""

echo "🔧 === QUICK FIXES ==="
echo "   1. Restart app completely (force close + reopen)"
echo "   2. Check internet connection"
echo "   3. Clear app cache in Android settings"
echo "   4. Re-install APK if problem persists"
echo ""

echo "✅ === VERIFICATION ==="
echo "   Camera successfully removed when:"
echo "   1. Report has status = 'verified' ✅"
echo "   2. Report has processedAt timestamp ✅"
echo "   3. Camera removed from speed_cameras collection ✅"
echo "   4. Map refreshes and shows no camera ✅"
echo ""

echo "🏁 Next steps: Check Firebase Console first!"
