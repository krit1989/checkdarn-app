#!/bin/bash

echo "🚀 Starting Camera Report System Test"
echo "======================================"

echo "📱 Running test app to create sample data..."
echo "กำลังเปิดแอปทดสอบสำหรับสร้างข้อมูลตัวอย่าง"

cd /Users/kritchaponprommali/checkdarn

# Run the test app
flutter run lib/test_create_sample_data.dart

echo "✅ Test completed!"
echo "ทดสอบเสร็จสิ้น!"
