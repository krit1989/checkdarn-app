#!/bin/bash

# Deployment script สำหรับ Traffic Log Compliance Cloud Functions
# ตาม พ.ร.บ.คอมพิวเตอร์ 2560 มาตรา 26

echo "🚀 Deploying Traffic Log Compliance Cloud Functions..."
echo "📋 This includes functions for พ.ร.บ.คอมพิวเตอร์ 2560 มาตรา 26 compliance"

# ตรวจสอบว่าอยู่ใน functions directory หรือไม่
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the functions directory."
    exit 1
fi

# ตรวจสอบว่า Firebase CLI ติดตั้งแล้วหรือไม่
if ! command -v firebase &> /dev/null; then
    echo "❌ Error: Firebase CLI not found. Please install it first:"
    echo "   npm install -g firebase-tools"
    exit 1
fi

# ตรวจสอบว่า login แล้วหรือไม่
if ! firebase projects:list &> /dev/null; then
    echo "❌ Error: Not logged in to Firebase. Please run:"
    echo "   firebase login"
    exit 1
fi

echo "✅ Prerequisites check passed"

# ติดตั้ง dependencies
echo "📦 Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed successfully"

# Deploy Cloud Functions
echo "🚀 Deploying Cloud Functions..."
echo "   - cleanupTrafficLogs (scheduled daily cleanup)"
echo "   - getTrafficLogsStats (admin statistics)"
echo "   - exportTrafficLogs (legal compliance export)"

firebase deploy --only functions:cleanupTrafficLogs,functions:getTrafficLogsStats,functions:exportTrafficLogs

if [ $? -eq 0 ]; then
    echo "✅ Cloud Functions deployed successfully!"
    echo ""
    echo "📋 Deployment Summary:"
    echo "   ✅ cleanupTrafficLogs - จะทำงานทุกวันตี 2 นาฬิกา"
    echo "   ✅ getTrafficLogsStats - สำหรับดูสถิติการใช้งาน"
    echo "   ✅ exportTrafficLogs - สำหรับ export ข้อมูลตามคำร้องขอ"
    echo ""
    echo "🔒 Security Notes:"
    echo "   - Traffic logs ถูก hash เพื่อปกป้องข้อมูลส่วนตัว"
    echo "   - เก็บข้อมูลไว้ 90 วันตามกฎหมาย"
    echo "   - Admin เท่านั้นที่เข้าถึงข้อมูลได้"
    echo ""
    echo "📞 Support: admin@checkdarn.app"
else
    echo "❌ Deployment failed. Please check the error messages above."
    exit 1
fi
