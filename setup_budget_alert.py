#!/usr/bin/env python3
"""
Firebase Budget Alert Setup Script
สำหรับตั้งค่า Budget Alert ใน Firebase Blaze Plan อัตโนมัติ
"""

import json
import subprocess
import sys
from typing import Dict, List

def check_firebase_cli():
    """ตรวจสอบว่ามี Firebase CLI ติดตั้งแล้วหรือไม่"""
    try:
        result = subprocess.run(['firebase', '--version'], 
                              capture_output=True, text=True, check=True)
        print(f"✅ Firebase CLI พบแล้ว: {result.stdout.strip()}")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ Firebase CLI ไม่พบ กรุณาติดตั้งก่อน:")
        print("npm install -g firebase-tools")
        return False

def check_firebase_login():
    """ตรวจสอบสถานะการล็อกอิน Firebase"""
    try:
        result = subprocess.run(['firebase', 'projects:list'], 
                              capture_output=True, text=True, check=True)
        print("✅ Firebase login สำเร็จ")
        return True
    except subprocess.CalledProcessError:
        print("❌ ยังไม่ได้ล็อกอิน Firebase")
        print("กรุณารันคำสั่ง: firebase login")
        return False

def get_project_info():
    """ดึงข้อมูล project ปัจจุบัน"""
    try:
        # อ่านจากไฟล์ .firebaserc
        with open('.firebaserc', 'r') as f:
            config = json.load(f)
            project_id = config.get('projects', {}).get('default')
            if project_id:
                print(f"📋 Project ID: {project_id}")
                return project_id
    except FileNotFoundError:
        pass
    
    # ถ้าไม่มีไฟล์ ให้ใช้ firebase use
    try:
        result = subprocess.run(['firebase', 'use'], 
                              capture_output=True, text=True, check=True)
        # Parse output เพื่อหา active project
        lines = result.stdout.split('\n')
        for line in lines:
            if 'currently using' in line.lower():
                project_id = line.split()[-1].strip('()')
                print(f"📋 Project ID: {project_id}")
                return project_id
    except subprocess.CalledProcessError:
        pass
    
    print("❌ ไม่พบ Firebase project")
    return None

def create_budget_alerts_config(project_id: str) -> Dict:
    """สร้าง config สำหรับ Budget Alerts"""
    
    # กำหนด budget thresholds ตามการใช้งาน
    budgets = [
        {
            "name": "firebase-storage-budget-warning",
            "amount": 10.0,  # $10 USD
            "currency": "USD",
            "threshold_percent": 50,  # แจ้งเตือนที่ 50%
            "description": "แจ้งเตือนเมื่อใช้ Firebase Storage ครึ่งหนึ่งของ budget"
        },
        {
            "name": "firebase-storage-budget-critical", 
            "amount": 10.0,  # $10 USD
            "currency": "USD",
            "threshold_percent": 80,  # แจ้งเตือนที่ 80%
            "description": "แจ้งเตือนเมื่อใช้ Firebase Storage เกือบเต็ม budget"
        },
        {
            "name": "firebase-firestore-budget",
            "amount": 5.0,   # $5 USD
            "currency": "USD", 
            "threshold_percent": 75,  # แจ้งเตือนที่ 75%
            "description": "แจ้งเตือนเมื่อใช้ Firestore เกิน budget"
        },
        {
            "name": "firebase-total-monthly-budget",
            "amount": 25.0,  # $25 USD รวมทั้งหมด
            "currency": "USD",
            "threshold_percent": 90,  # แจ้งเตือนที่ 90%
            "description": "แจ้งเตือนเมื่อใช้ Firebase รวมเกือบเต็ม budget รายเดือน"
        }
    ]
    
    return {
        "project_id": project_id,
        "budgets": budgets,
        "notification_emails": [
            # เพิ่ม email ที่ต้องการให้แจ้งเตือน
            "admin@checkdarn.com",  # แทนที่ด้วย email จริง
            "kritchapon1989@gmail.com",  # อีเมล์หลักสำหรับแจ้งเตือน budget
        ],
        "slack_webhook": None,  # เพิ่ม Slack webhook ถ้าต้องการ
    }

def generate_cloud_functions_budget_monitor():
    """สร้าง Cloud Functions สำหรับ monitor budget"""
    
    cloud_function_code = '''
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { PubSub } = require('@google-cloud/pubsub');

admin.initializeApp();

// Budget alert handler
exports.budgetAlert = functions.pubsub.topic('budget-alerts').onPublish(async (message) => {
  const budgetData = message.json;
  
  console.log('📊 Budget Alert Received:', budgetData);
  
  // ตรวจสอบระดับการใช้งาน
  const usagePercent = (budgetData.costAmount / budgetData.budgetAmount) * 100;
  
  if (usagePercent >= 90) {
    // ฉุกเฉิน - ปิดการ upload รูปชั่วคราว
    await admin.firestore().collection('app_settings').doc('storage_control').set({
      upload_enabled: false,
      reason: 'budget_exceeded',
      disabled_at: admin.firestore.FieldValue.serverTimestamp(),
      usage_percent: usagePercent
    });
    
    console.log('🔴 EMERGENCY: Upload disabled due to budget limit');
    
  } else if (usagePercent >= 80) {
    // เตือน - เปิดโหมดประหยัด
    await admin.firestore().collection('app_settings').doc('storage_control').set({
      compression_mode: 'emergency',
      auto_delete_days: 30,
      warning_level: 'critical',
      usage_percent: usagePercent
    });
    
    console.log('🟡 WARNING: Enabled aggressive compression mode');
    
  } else if (usagePercent >= 50) {
    // แจ้งเตือน - โหมดประหยัด
    await admin.firestore().collection('app_settings').doc('storage_control').set({
      compression_mode: 'aggressive', 
      warning_level: 'moderate',
      usage_percent: usagePercent
    });
    
    console.log('🟠 NOTICE: Enabled moderate compression mode');
  }
  
  // ส่ง notification ไป app
  await sendBudgetNotificationToApp(budgetData, usagePercent);
});

async function sendBudgetNotificationToApp(budgetData, usagePercent) {
  try {
    // บันทึก budget alert ลง Firestore
    await admin.firestore().collection('budget_alerts').add({
      cost_amount: budgetData.costAmount,
      budget_amount: budgetData.budgetAmount,
      usage_percent: usagePercent,
      alert_level: getAlertLevel(usagePercent),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      project_id: budgetData.projectId || 'unknown'
    });
    
    console.log('💾 Budget alert saved to Firestore');
    
  } catch (error) {
    console.error('❌ Error saving budget alert:', error);
  }
}

function getAlertLevel(usagePercent) {
  if (usagePercent >= 90) return 'emergency';
  if (usagePercent >= 80) return 'critical';
  if (usagePercent >= 50) return 'warning';
  return 'info';
}

// Storage usage monitor (รันทุกชั่วโมง)
exports.monitorStorageUsage = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
  try {
    // ดึงข้อมูลการใช้งาน Storage
    const cameraReports = await admin.firestore()
      .collection('camera_reports')
      .where('imageUrl', '!=', null)
      .get();
    
    const totalImages = cameraReports.size;
    const estimatedSizeGB = (totalImages * 200 * 1024) / (1024 * 1024 * 1024); // 200KB per image
    
    // บันทึกสถิติ
    await admin.firestore().collection('storage_stats').add({
      total_images: totalImages,
      estimated_size_gb: estimatedSizeGB,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      cost_estimate_usd: estimatedSizeGB * 0.026 // $0.026 per GB
    });
    
    console.log(`📊 Storage monitored: ${totalImages} images, ${estimatedSizeGB.toFixed(2)} GB`);
    
  } catch (error) {
    console.error('❌ Error monitoring storage:', error);
  }
});
'''
    
    return cloud_function_code

def create_budget_monitoring_files():
    """สร้างไฟล์สำหรับ budget monitoring"""
    
    # สร้าง functions/package.json
    package_json = {
        "name": "checkdarn-budget-monitor",
        "version": "1.0.0",
        "description": "Budget monitoring for CheckDarn app",
        "main": "index.js",
        "dependencies": {
            "firebase-admin": "^12.0.0",
            "firebase-functions": "^4.5.0",
            "@google-cloud/pubsub": "^4.0.0"
        },
        "scripts": {
            "deploy": "firebase deploy --only functions"
        }
    }
    
    # สร้าง directory functions/ ถ้าไม่มี
    import os
    os.makedirs('functions', exist_ok=True)
    
    # เขียนไฟล์
    with open('functions/package.json', 'w') as f:
        json.dump(package_json, f, indent=2)
    
    with open('functions/index.js', 'w') as f:
        f.write(generate_cloud_functions_budget_monitor())
    
    print("✅ สร้างไฟล์ Cloud Functions สำเร็จ")

def print_manual_setup_instructions(config: Dict):
    """แสดงคำแนะนำการตั้งค่า Budget Alert แบบ manual"""
    
    print("\n" + "="*60)
    print("📋 คำแนะนำการตั้งค่า Budget Alert ใน Firebase Console")
    print("="*60)
    
    print(f"\n🎯 Project: {config['project_id']}")
    
    print("\n📍 ขั้นตอนการตั้งค่า:")
    print("1. เปิด Firebase Console: https://console.firebase.google.com")
    print(f"2. เลือก project: {config['project_id']}")
    print("3. ไป Settings > Project settings > Billing")
    print("4. คลิก 'Set up billing budgets and alerts'")
    
    print("\n💰 Budget Alert ที่แนะนำ:")
    for i, budget in enumerate(config['budgets'], 1):
        print(f"\n{i}. {budget['name']}")
        print(f"   💵 จำนวน: ${budget['amount']} {budget['currency']}")
        print(f"   ⚠️  แจ้งเตือนที่: {budget['threshold_percent']}%")
        print(f"   📝 รายละเอียด: {budget['description']}")
    
    print(f"\n📧 Notification Emails:")
    for email in config['notification_emails']:
        print(f"   • {email}")
    
    print("\n🔗 Google Cloud Console Budget:")
    print("1. เปิด https://console.cloud.google.com/billing/budgets")
    print(f"2. เลือก project: {config['project_id']}")
    print("3. คลิก 'CREATE BUDGET'")
    print("4. ตั้งค่าตาม budget ข้างต้น")
    
    print("\n📊 การติดตาม:")
    print("• Firebase Console > Usage and billing")
    print("• Google Cloud Console > Billing")
    print("• Cloud Functions จะ monitor อัตโนมัติ")
    
    print("\n⚡ Cloud Functions Deployment:")
    print("cd functions && npm install")
    print("firebase deploy --only functions")

def main():
    """ฟังก์ชันหลัก"""
    print("🚀 Firebase Budget Alert Setup")
    print("="*40)
    
    # ตรวจสอบ prerequisites
    if not check_firebase_cli():
        return False
    
    if not check_firebase_login():
        return False
    
    # ดึงข้อมูล project
    project_id = get_project_info()
    if not project_id:
        print("❌ ไม่สามารถหา Firebase project ได้")
        return False
    
    # สร้าง config
    config = create_budget_alerts_config(project_id)
    
    # สร้าง Cloud Functions
    create_budget_monitoring_files()
    
    # บันทึก config
    with open('budget-alert-config.json', 'w') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ สร้าง budget-alert-config.json สำเร็จ")
    
    # แสดงคำแนะนำ
    print_manual_setup_instructions(config)
    
    print("\n🎉 Setup เสร็จสิ้น!")
    print("กรุณาทำตามคำแนะนำข้างต้นเพื่อเปิดใช้งาน Budget Alert")
    
    return True

if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n❌ ยกเลิกการตั้งค่า")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ เกิดข้อผิดพลาด: {e}")
        sys.exit(1)
