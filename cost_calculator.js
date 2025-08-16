/**
 * 💰 Firebase Cost Calculator
 * คำนวณค่าใช้จ่าย Firebase แบบ real-time
 */

// 💵 ราคา Firebase (USD)
const FIREBASE_PRICING = {
  fcm: {
    perMessage: 0.0001 // $0.0001 per message
  },
  firestore: {
    read: 0.00006,    // $0.00006 per document read
    write: 0.00018,   // $0.00018 per document write
    delete: 0.00002   // $0.00002 per document delete
  },
  storage: {
    perGB: 0.020,     // $0.020 per GB stored
    downloadGB: 0.12, // $0.12 per GB downloaded
    operations: 0.0004 // $0.0004 per 1000 operations
  },
  functions: {
    invocation: 0.0000004, // $0.0000004 per invocation
    gbSecond: 0.0000025,   // $0.0000025 per GB-second
    networking: 0.12       // $0.12 per GB networking
  }
};

// 🏷️ อัตราแลกเปลี่ยน (สมมติ)
const THB_RATE = 35; // 1 USD = 35 THB

/**
 * 📊 คำนวณค่าใช้จ่าย FCM
 */
function calculateFCMCost(messagesPerDay, days = 30) {
  const totalMessages = messagesPerDay * days;
  const costUSD = totalMessages * FIREBASE_PRICING.fcm.perMessage;
  const costTHB = costUSD * THB_RATE;
  
  return {
    totalMessages,
    costUSD: Number(costUSD.toFixed(4)),
    costTHB: Math.round(costTHB),
    perDay: {
      messages: messagesPerDay,
      costUSD: Number((costUSD / days).toFixed(4)),
      costTHB: Math.round(costTHB / days)
    }
  };
}

/**
 * 🗃️ คำนวณค่าใช้จ่าย Firestore
 */
function calculateFirestoreCost(operations, days = 30) {
  const { reads, writes, deletes } = operations;
  
  const readCostUSD = (reads * days) * FIREBASE_PRICING.firestore.read;
  const writeCostUSD = (writes * days) * FIREBASE_PRICING.firestore.write;
  const deleteCostUSD = (deletes * days) * FIREBASE_PRICING.firestore.delete;
  
  const totalCostUSD = readCostUSD + writeCostUSD + deleteCostUSD;
  const totalCostTHB = totalCostUSD * THB_RATE;
  
  return {
    operations: {
      reads: reads * days,
      writes: writes * days,
      deletes: deletes * days
    },
    costs: {
      reads: { USD: Number(readCostUSD.toFixed(4)), THB: Math.round(readCostUSD * THB_RATE) },
      writes: { USD: Number(writeCostUSD.toFixed(4)), THB: Math.round(writeCostUSD * THB_RATE) },
      deletes: { USD: Number(deleteCostUSD.toFixed(4)), THB: Math.round(deleteCostUSD * THB_RATE) },
      total: { USD: Number(totalCostUSD.toFixed(4)), THB: Math.round(totalCostTHB) }
    }
  };
}

/**
 * 🗄️ คำนวณค่าใช้จ่าย Storage
 */
function calculateStorageCost(storageGB, downloadGB, operations) {
  const storageCostUSD = storageGB * FIREBASE_PRICING.storage.perGB;
  const downloadCostUSD = downloadGB * FIREBASE_PRICING.storage.downloadGB;
  const operationsCostUSD = (operations / 1000) * FIREBASE_PRICING.storage.operations;
  
  const totalCostUSD = storageCostUSD + downloadCostUSD + operationsCostUSD;
  const totalCostTHB = totalCostUSD * THB_RATE;
  
  return {
    storage: { GB: storageGB, costUSD: Number(storageCostUSD.toFixed(4)), costTHB: Math.round(storageCostUSD * THB_RATE) },
    download: { GB: downloadGB, costUSD: Number(downloadCostUSD.toFixed(4)), costTHB: Math.round(downloadCostUSD * THB_RATE) },
    operations: { count: operations, costUSD: Number(operationsCostUSD.toFixed(4)), costTHB: Math.round(operationsCostUSD * THB_RATE) },
    total: { USD: Number(totalCostUSD.toFixed(4)), THB: Math.round(totalCostTHB) }
  };
}

/**
 * ⚙️ คำนวณค่าใช้จ่าย Cloud Functions
 */
function calculateFunctionsCost(invocations, gbSeconds, networkingGB, days = 30) {
  const invocationCostUSD = (invocations * days) * FIREBASE_PRICING.functions.invocation;
  const computeCostUSD = (gbSeconds * days) * FIREBASE_PRICING.functions.gbSecond;
  const networkingCostUSD = (networkingGB * days) * FIREBASE_PRICING.functions.networking;
  
  const totalCostUSD = invocationCostUSD + computeCostUSD + networkingCostUSD;
  const totalCostTHB = totalCostUSD * THB_RATE;
  
  return {
    invocations: { count: invocations * days, costUSD: Number(invocationCostUSD.toFixed(4)), costTHB: Math.round(invocationCostUSD * THB_RATE) },
    compute: { gbSeconds: gbSeconds * days, costUSD: Number(computeCostUSD.toFixed(6)), costTHB: Math.round(computeCostUSD * THB_RATE) },
    networking: { GB: networkingGB * days, costUSD: Number(networkingCostUSD.toFixed(4)), costTHB: Math.round(networkingCostUSD * THB_RATE) },
    total: { USD: Number(totalCostUSD.toFixed(4)), THB: Math.round(totalCostTHB) }
  };
}

/**
 * 📊 คำนวณค่าใช้จ่ายรวมทั้งหมด
 */
function calculateTotalCost(config, days = 30) {
  const fcm = calculateFCMCost(config.fcmMessagesPerDay, days);
  const firestore = calculateFirestoreCost(config.firestoreOperationsPerDay, days);
  const storage = calculateStorageCost(config.storageGB, config.downloadGB, config.storageOperations);
  const functions = calculateFunctionsCost(
    config.functionsInvocationsPerDay, 
    config.functionsGBSecondsPerDay, 
    config.functionsNetworkingGBPerDay, 
    days
  );
  
  const totalUSD = fcm.costUSD + firestore.costs.total.USD + storage.total.USD + functions.total.USD;
  const totalTHB = Math.round(totalUSD * THB_RATE);
  
  return {
    period: `${days} days`,
    breakdown: { fcm, firestore, storage, functions },
    total: { USD: Number(totalUSD.toFixed(2)), THB: totalTHB },
    perDay: { USD: Number((totalUSD / days).toFixed(2)), THB: Math.round(totalTHB / days) }
  };
}

/**
 * 🎯 ตัวอย่างการใช้งาน - CheckDarn App
 */
function checkDarnCostExample() {
  // ⚙️ การตั้งค่าปัจจุบัน (หลังปรับปรุง)
  const currentConfig = {
    fcmMessagesPerDay: 5000,        // จำกัดโควต้า
    firestoreOperationsPerDay: {
      reads: 7150,                  // ดึงข้อมูลผู้ใช้ + โพสต์
      writes: 471,                  // โพสต์ใหม่ + คอมเมนต์ + counters
      deletes: 30                   // cleanup เก่า + invalid tokens
    },
    storageGB: 50,                  // รูปภาพทั้งหมด
    downloadGB: 500,                // ดาวน์โหลดรูปภาพ
    storageOperations: 10000,       // upload/download operations
    functionsInvocationsPerDay: 5500, // การเรียกใช้ functions
    functionsGBSecondsPerDay: 50,   // compute time
    functionsNetworkingGBPerDay: 1  // networking
  };
  
  // ⚠️ การตั้งค่าก่อนปรับปรุง (สำหรับเปรียบเทียบ)
  const oldConfig = {
    ...currentConfig,
    fcmMessagesPerDay: 100000,      // ส่งไม่จำกัด (100 โพสต์ × 1000 ผู้ใช้)
    firestoreOperationsPerDay: {
      reads: 50000,                 // อ่านมากกว่า
      writes: 1000,                 // เขียนมากกว่า
      deletes: 10                   // ลบน้อยกว่า
    }
  };
  
  console.log('💰 CheckDarn App - Cost Calculation');
  console.log('=====================================\n');
  
  // 📊 คำนวณต้นทุนปัจจุบัน
  const currentCost = calculateTotalCost(currentConfig, 30);
  console.log('✅ ปัจจุบัน (หลังปรับปรุง):');
  console.log(`   รายวัน: $${currentCost.perDay.USD} (${currentCost.perDay.THB.toLocaleString()} บาท)`);
  console.log(`   รายเดือน: $${currentCost.total.USD} (${currentCost.total.THB.toLocaleString()} บาท)\n`);
  
  // 📊 คำนวณต้นทุนเก่า
  const oldCost = calculateTotalCost(oldConfig, 30);
  console.log('❌ ก่อนปรับปรุง:');
  console.log(`   รายวัน: $${oldCost.perDay.USD} (${oldCost.perDay.THB.toLocaleString()} บาท)`);
  console.log(`   รายเดือน: $${oldCost.total.USD} (${oldCost.total.THB.toLocaleString()} บาท)\n`);
  
  // 💰 คำนวณการประหยัด
  const savingsUSD = oldCost.total.USD - currentCost.total.USD;
  const savingsTHB = oldCost.total.THB - currentCost.total.THB;
  const savingsPercent = ((savingsUSD / oldCost.total.USD) * 100).toFixed(1);
  
  console.log('💵 การประหยัด:');
  console.log(`   จำนวน: $${savingsUSD.toFixed(2)} (${savingsTHB.toLocaleString()} บาท)`);
  console.log(`   เปอร์เซ็นต์: ${savingsPercent}%\n`);
  
  // 📋 รายละเอียดการใช้งาน
  console.log('📋 รายละเอียดต้นทุนปัจจุบัน:');
  console.log(`🔔 FCM: $${currentCost.breakdown.fcm.costUSD} (${currentCost.breakdown.fcm.costTHB.toLocaleString()} บาท)`);
  console.log(`🗃️ Firestore: $${currentCost.breakdown.firestore.costs.total.USD} (${currentCost.breakdown.firestore.costs.total.THB.toLocaleString()} บาท)`);
  console.log(`🗄️ Storage: $${currentCost.breakdown.storage.total.USD} (${currentCost.breakdown.storage.total.THB.toLocaleString()} บาท)`);
  console.log(`⚙️ Functions: $${currentCost.breakdown.functions.total.USD} (${currentCost.breakdown.functions.total.THB.toLocaleString()} บาท)`);
  
  return {
    current: currentCost,
    old: oldCost,
    savings: { USD: savingsUSD, THB: savingsTHB, percent: savingsPercent }
  };
}

/**
 * 🎯 การทำนายต้นทุนตามจำนวนผู้ใช้
 */
function predictCostByUsers(baseConfig, userCounts = [1000, 5000, 10000, 50000]) {
  console.log('\n🎯 การทำนายต้นทุนตามจำนวนผู้ใช้:');
  console.log('==========================================');
  
  userCounts.forEach(users => {
    // สมมติว่าการใช้งานเพิ่มขึ้นตามจำนวนผู้ใช้
    const scaleFactor = users / 1000; // base = 1000 users
    
    const scaledConfig = {
      ...baseConfig,
      firestoreOperationsPerDay: {
        reads: Math.round(baseConfig.firestoreOperationsPerDay.reads * scaleFactor),
        writes: Math.round(baseConfig.firestoreOperationsPerDay.writes * scaleFactor),
        deletes: Math.round(baseConfig.firestoreOperationsPerDay.deletes * scaleFactor)
      },
      storageGB: Math.round(baseConfig.storageGB * scaleFactor * 0.7), // ไม่เพิ่มเต็มตาม user
      downloadGB: Math.round(baseConfig.downloadGB * scaleFactor),
      storageOperations: Math.round(baseConfig.storageOperations * scaleFactor),
      functionsInvocationsPerDay: Math.round(baseConfig.functionsInvocationsPerDay * scaleFactor),
      functionsGBSecondsPerDay: Math.round(baseConfig.functionsGBSecondsPerDay * scaleFactor * 0.8),
      functionsNetworkingGBPerDay: Math.round(baseConfig.functionsNetworkingGBPerDay * scaleFactor * 0.9)
    };
    
    const cost = calculateTotalCost(scaledConfig, 30);
    console.log(`👥 ${users.toLocaleString()} ผู้ใช้: $${cost.total.USD}/เดือน (${cost.total.THB.toLocaleString()} บาท)`);
  });
}

// 🚀 เรียกใช้งาน
if (require.main === module) {
  const results = checkDarnCostExample();
  
  // ทำนายต้นทุนตามจำนวนผู้ใช้
  const baseConfig = {
    fcmMessagesPerDay: 5000,
    firestoreOperationsPerDay: {
      reads: 7150,
      writes: 471,
      deletes: 30
    },
    storageGB: 50,
    downloadGB: 500,
    storageOperations: 10000,
    functionsInvocationsPerDay: 5500,
    functionsGBSecondsPerDay: 50,
    functionsNetworkingGBPerDay: 1
  };
  
  predictCostByUsers(baseConfig);
}

module.exports = {
  calculateFCMCost,
  calculateFirestoreCost,
  calculateStorageCost,
  calculateFunctionsCost,
  calculateTotalCost,
  checkDarnCostExample,
  predictCostByUsers,
  FIREBASE_PRICING,
  THB_RATE
};
