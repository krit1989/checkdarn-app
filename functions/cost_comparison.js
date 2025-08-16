// 📊 **เปรียบเทียบค่าใช้จ่ายก่อนและหลังการปรับปรุง**

console.log('💰 **การเปรียบเทียบค่าใช้จ่าย BEFORE vs AFTER**\n');

const scenarios = [
  { name: "100 โพสต์, 500 ผู้ใช้", posts: 100, users: 500 },
  { name: "200 โพสต์, 1,000 ผู้ใช้", posts: 200, users: 1000 },
  { name: "300 โพสต์, 2,000 ผู้ใช้", posts: 300, users: 2000 }
];

scenarios.forEach(scenario => {
  console.log(`📊 **${scenario.name}**`);
  
  // BEFORE (ไม่กรองพื้นที่)
  const notificationsBefore = scenario.posts * scenario.users;
  const fcmCostBefore = Math.max(0, (notificationsBefore - 100000) * 0.000050);
  
  // AFTER (กรองพื้นที่ 30km ลดผู้ใช้ 70%)
  const effectiveUsers = Math.round(scenario.users * 0.3); // เหลือ 30%
  const notificationsAfter = scenario.posts * effectiveUsers;
  const fcmCostAfter = Math.max(0, (notificationsAfter - 100000) * 0.000050);
  
  // Firestore costs
  const firestoreReadsBefore = scenario.posts * scenario.users * 2; // 2 reads/notification
  const firestoreReadsAfter = scenario.posts * effectiveUsers * 1.5; // cache ลด 25%
  
  const firestoreCostBefore = (firestoreReadsBefore / 100000) * 0.06; // $0.06 per 100K reads
  const firestoreCostAfter = (firestoreReadsAfter / 100000) * 0.06;
  
  // Function invocations
  const functionsBefore = scenario.posts * 2; // 2 functions/post
  const functionsAfter = scenario.posts * 1.5; // batch processing ลด 25%
  
  const functionsCostBefore = (functionsBefore / 1000000) * 0.4; // $0.4 per 1M invocations
  const functionsCostAfter = (functionsAfter / 1000000) * 0.4;
  
  const totalCostBefore = (fcmCostBefore + firestoreCostBefore + functionsCostBefore) * 35; // บาท
  const totalCostAfter = (fcmCostAfter + firestoreCostAfter + functionsCostAfter) * 35;
  
  const savings = ((totalCostBefore - totalCostAfter) / totalCostBefore) * 100;
  
  console.log(`   🔴 BEFORE: ฿${totalCostBefore.toFixed(2)}/วัน`);
  console.log(`   🟢 AFTER:  ฿${totalCostAfter.toFixed(2)}/วัน`);
  console.log(`   💰 ประหยัด: ${savings.toFixed(1)}% (฿${(totalCostBefore - totalCostAfter).toFixed(2)}/วัน)`);
  console.log(`   📅 ประหยัดต่อเดือน: ฿${((totalCostBefore - totalCostAfter) * 30).toFixed(2)}`);
  console.log(`   📊 การใช้งาน:`);
  console.log(`      - FCM: ${notificationsBefore.toLocaleString()} → ${notificationsAfter.toLocaleString()}`);
  console.log(`      - Firestore Reads: ${firestoreReadsBefore.toLocaleString()} → ${firestoreReadsAfter.toLocaleString()}`);
  console.log(`      - Function Calls: ${functionsBefore.toLocaleString()} → ${functionsAfter.toLocaleString()}\n`);
});

console.log('🚀 **การปรับปรุงเพิ่มเติม:**');
console.log('1. ✅ Geographic Filtering (ลด 70% notifications)');
console.log('2. ✅ Caching (ลด 25% Firestore reads)');
console.log('3. ✅ Batch Processing (ลด 25% function calls)');
console.log('4. ✅ Retry Logic ปรับปรุง (ลด infinite loops)');
console.log('5. ✅ Scheduled Functions ลดเป็น 10 นาที');
console.log('6. ✅ Token Management ปรับปรุง');
console.log('7. ✅ Field Selection (select เฉพาะที่จำเป็น)');
console.log('8. ✅ Batch Size เพิ่มเป็น 100 tokens');
