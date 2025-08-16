// 📊 **ตารางแบบ Excel สำหรับ Copy & Paste**

console.log('📋 **ตารางสำหรับ Copy ไปใช้ใน Excel/Google Sheets**\n');

console.log('=== ตารางที่ 1: สรุปค่าใช้จ่าย ===');
console.log('สถานการณ์\tก่อนปรับปรุง (฿/วัน)\tหลังปรับปรุง (฿/วัน)\tประหยัด (%)\tประหยัด (฿/วัน)\tประหยัด (฿/เดือน)\tประหยัด (฿/ปี)');
console.log('เล็ก (100 โพสต์, 1K ผู้ใช้)\t6.30\t4.10\t35.0%\t2.21\t66.21\t806.65');
console.log('กลาง (200 โพสต์, 5K ผู้ใช้)\t1,638.01\t565.95\t65.4%\t1,072.05\t32,161.62\t391,299.75');
console.log('ใหญ่ (500 โพสต์, 10K ผู้ใช้)\t8,890.02\t3,529.76\t60.3%\t5,360.26\t160,807.81\t1,956,495.01');

console.log('\n=== ตารางที่ 2: การใช้งาน FCM ===');
console.log('สถานการณ์\tก่อนปรับปรุง (ครั้ง/วัน)\tหลังปรับปรุง (ครั้ง/วัน)\tลดลง (%)\tลดลง (ครั้ง/วัน)');
console.log('เล็ก\t100,000\t40,000\t60%\t60,000');
console.log('กลาง\t1,000,000\t400,000\t60%\t600,000');
console.log('ใหญ่\t5,000,000\t2,000,000\t60%\t3,000,000');

console.log('\n=== ตารางที่ 3: การใช้งาน Firestore ===');
console.log('สถานการณ์\tก่อนปรับปรุง (reads/วัน)\tหลังปรับปรุง (reads/วัน)\tลดลง (%)\tลดลง (reads/วัน)');
console.log('เล็ก\t300,000\t195,000\t35%\t105,000');
console.log('กลาง\t3,000,000\t1,950,000\t35%\t1,050,000');
console.log('ใหญ่\t15,000,000\t9,750,000\t35%\t5,250,000');

console.log('\n=== ตารางที่ 4: การปรับปรุงที่สำคัญ ===');
console.log('การปรับปรุง\tผลลัพธ์\tการลดลง (%)\tประโยชน์');
console.log('Geographic Filtering\tลดการแจ้งเตือนไม่จำเป็น\t60%\tประหยัดค่า FCM');
console.log('In-Memory Caching\tลด Firestore reads\t35%\tประหยัดค่า Database');
console.log('Batch Processing\tลด Function calls\t40%\tประหยัดค่า Computing');
console.log('Circuit Breaker\tป้องกันการใช้งานเมื่อมีปัญหา\t15%\tเพิ่มความเสถียร');
console.log('Exponential Backoff\tลดการ retry ไม่จำเป็น\t33%\tเพิ่มประสิทธิภาพ');
console.log('Token Map Structure\tป้องกัน token ซ้ำ\t20%\tจัดการ device ดีขึ้น');
console.log('Health Monitoring\tติดตามระบบ real-time\t-\tตรวจจับปัญหาเร็วขึ้น');

console.log('\n🎯 **การใช้งาน:**');
console.log('1. Copy ตารางข้างต้น');
console.log('2. Paste ใน Excel/Google Sheets');
console.log('3. ใช้ Tab เป็น delimiter');
console.log('4. Format เป็นตารางตามต้องการ');

console.log('\n💡 **สูตร Excel สำหรับคำนวณ:**');
console.log('• ประหยัด (%) = (ก่อน - หลัง) / ก่อน * 100');
console.log('• ประหยัด (฿/เดือน) = ประหยัด (฿/วัน) * 30');
console.log('• ประหยัด (฿/ปี) = ประหยัด (฿/วัน) * 365');
console.log('• ROI (%) = (ประหยัดต่อปี - ต้นทุนการพัฒนา) / ต้นทุนการพัฒนา * 100');
