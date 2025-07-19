#!/bin/bash

echo "🔍 ตรวจสอบ SHA-1 Fingerprint สำหรับ Debug Keystore"
echo "================================================"

# ตรวจสอบ debug keystore
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"

if [ -f "$DEBUG_KEYSTORE" ]; then
    echo "✅ พบ debug keystore: $DEBUG_KEYSTORE"
    echo ""
    echo "📝 SHA-1 Fingerprint:"
    
    # ใช้ keytool จาก Java
    if command -v keytool &> /dev/null; then
        keytool -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android | grep SHA1
    else
        echo "❌ ไม่พบ keytool - กรุณาติดตั้ง Java Development Kit (JDK)"
        echo ""
        echo "📥 วิธีติดตั้ง JDK บน macOS:"
        echo "brew install openjdk"
        echo "หรือ"
        echo "brew install adoptopenjdk"
    fi
else
    echo "❌ ไม่พบ debug keystore"
    echo "กรุณารันคำสั่ง: flutter run หรือ flutter build apk ก่อน"
fi

echo ""
echo "📋 วิธีอัปเดต Firebase Console:"
echo "1. เข้า https://console.firebase.google.com"
echo "2. เลือกโปรเจค CheckDarn"
echo "3. ไป Project Settings > General > Your apps > Android app"
echo "4. เพิ่ม SHA-1 fingerprint ที่ได้ข้างต้น"
echo "5. ดาวน์โหลด google-services.json ใหม่"
