// 📊 **คำนวณค่าใช้จ่าย FCM Notification**

// 💰 ราคา FCM (ตามราคาปัจจุบันของ Google)
const FCM_PRICING = {
  free_tier: 100000,      // ฟรี 100,000 ข้อความต่อวัน
  cost_per_message: 0.000050, // $0.000050 ต่อข้อความ (หลังจากเกิน free tier)
  usd_to_thb: 35         // ประมาณ 35 บาทต่อดอลลาร์
};

// 📱 สถานการณ์จำลอง
const scenarios = [
  { name: "สถานการณ์ปกติ", posts: 100, users: 500 },
  { name: "สถานการณ์กลาง", posts: 200, users: 1000 },
  { name: "สถานการณ์หนัก", posts: 300, users: 2000 }
];

console.log('🧮 **การคำนวณค่าใช้จ่าย FCM Notification**\n');

scenarios.forEach(scenario => {
  console.log(`📊 **${scenario.name}**`);
  console.log(`   📝 โพสต์ต่อวัน: ${scenario.posts.toLocaleString()} โพสต์`);
  console.log(`   👥 ผู้ใช้ในระบบ: ${scenario.users.toLocaleString()} คน`);
  
  // คำนวณการแจ้งเตือนต่อวัน
  const notifications_per_day = scenario.posts * scenario.users;
  
  console.log(`   🔔 แจ้งเตือนต่อวัน: ${notifications_per_day.toLocaleString()} ข้อความ`);
  
  // คำนวณค่าใช้จ่าย
  let cost_usd = 0;
  if (notifications_per_day > FCM_PRICING.free_tier) {
    const paid_messages = notifications_per_day - FCM_PRICING.free_tier;
    cost_usd = paid_messages * FCM_PRICING.cost_per_message;
  }
  
  const cost_thb = cost_usd * FCM_PRICING.usd_to_thb;
  const cost_monthly = cost_thb * 30;
  const cost_yearly = cost_thb * 365;
  
  console.log(`   💰 ค่าใช้จ่ายต่อวัน:`);
  console.log(`      - USD: $${cost_usd.toFixed(4)}`);
  console.log(`      - THB: ฿${cost_thb.toFixed(2)}`);
  console.log(`   📅 ค่าใช้จ่ายต่อเดือน: ฿${cost_monthly.toFixed(2)}`);
  console.log(`   📅 ค่าใช้จ่ายต่อปี: ฿${cost_yearly.toFixed(2)}\n`);
});

// 🎯 การปรับปรุงด้วย Geographic Filtering
console.log('🎯 **การประหยัดด้วย Geographic Filtering**\n');

const filtering_scenarios = [
  { name: "ไม่กรอง", radius: "ทั้งประเทศ", reduction: 0 },
  { name: "กรอง 50km", radius: "50 กม.", reduction: 0.7 },
  { name: "กรอง 30km", radius: "30 กม.", reduction: 0.8 },
  { name: "กรอง 10km", radius: "10 กม.", reduction: 0.9 }
];

const base_scenario = { posts: 200, users: 1000 }; // สถานการณ์กลาง

filtering_scenarios.forEach(filter => {
  const effective_users = base_scenario.users * (1 - filter.reduction);
  const notifications = base_scenario.posts * effective_users;
  
  let cost_usd = 0;
  if (notifications > FCM_PRICING.free_tier) {
    const paid_messages = notifications - FCM_PRICING.free_tier;
    cost_usd = paid_messages * FCM_PRICING.cost_per_message;
  }
  
  const cost_thb_daily = cost_usd * FCM_PRICING.usd_to_thb;
  const cost_thb_monthly = cost_thb_daily * 30;
  
  console.log(`📍 **${filter.name}** (รัศมี: ${filter.radius})`);
  console.log(`   👥 ผู้ใช้ที่ได้รับแจ้งเตือน: ${effective_users.toLocaleString()} คน`);
  console.log(`   🔔 แจ้งเตือนต่อวัน: ${notifications.toLocaleString()} ข้อความ`);
  console.log(`   💰 ค่าใช้จ่ายต่อวัน: ฿${cost_thb_daily.toFixed(2)}`);
  console.log(`   📅 ค่าใช้จ่ายต่อเดือน: ฿${cost_thb_monthly.toFixed(2)}`);
  console.log(`   💡 ประหยัด: ${(filter.reduction * 100).toFixed(0)}%\n`);
});

// 🚨 คำแนะนำ
console.log('🚨 **คำแนะนำ**');
console.log('1. �� เปิด Geographic Filtering ทันที (ENABLE_GEOGRAPHIC_FILTER: true)');
console.log('2. 🔧 ปรับ MAX_RADIUS_KM เป็น 30-50km เพื่อสมดุลระหว่างความครอบคลุมและต้นทุน');
console.log('3. 📊 ติดตาม usage ผ่าน Firebase Console');
console.log('4. 🎛️ พิจารณาเพิ่มระบบ user preferences (emergency only, category filter)');
console.log('5. ⏰ พิจารณา rate limiting สำหรับ high-traffic periods');
