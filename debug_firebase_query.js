// ตรวจสอบข้อมูลใน Firebase สำหรับโพสต์ที่แสดงผลผิด
// รันใน Firebase Console หรือใน Cloud Functions

// 1. ดูข้อมูล reports ทั้งหมดที่มี location = "อำเภอพานทอง จังหวัดชลบุรี"
db.collection('reports')
  .where('location', '==', 'อำเภอพานทอง จังหวัดชลบุรี')
  .get()
  .then((querySnapshot) => {
    console.log(`พบ ${querySnapshot.size} โพสต์ที่แสดง "อำเภอพานทอง จังหวัดชลบุรี"`);
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      console.log('Document ID:', doc.id);
      console.log('Coordinates:', data.lat, data.lng);
      console.log('Location:', data.location);
      console.log('District:', data.district);
      console.log('Province:', data.province);
      console.log('Timestamp:', data.timestamp);
      console.log('---');
    });
  });

// 2. ดูข้อมูล reports ที่มี district = "พานทอง"
db.collection('reports')
  .where('district', '==', 'พานทอง')
  .get()
  .then((querySnapshot) => {
    console.log(`พบ ${querySnapshot.size} โพสต์ที่มี district = "พานทอง"`);
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      console.log('Document ID:', doc.id);
      console.log('Coordinates:', data.lat, data.lng);
      console.log('---');
    });
  });

// 3. ดู reports ล่าสุด 10 อัน
db.collection('reports')
  .orderBy('timestamp', 'desc')
  .limit(10)
  .get()
  .then((querySnapshot) => {
    console.log('โพสต์ล่าสุด 10 อัน:');
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      console.log('ID:', doc.id);
      console.log('Location:', data.location);
      console.log('Coordinates:', data.lat, data.lng);
      console.log('District:', data.district);
      console.log('Province:', data.province);
      console.log('---');
    });
  });

// 4. ดูพิกัดที่เป็นปัญหา - ตรวจสอบว่ามีพิกัด (13.0827, 101.0028) หรือไม่
db.collection('reports')
  .where('lat', '>=', 13.082)
  .where('lat', '<=', 13.083)
  .get()
  .then((querySnapshot) => {
    console.log(`พบ ${querySnapshot.size} โพสต์ที่มีพิกัด lat ใกล้เคียง 13.0827`);
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      console.log('ID:', doc.id);
      console.log('Coordinates:', data.lat, data.lng);
      console.log('Location:', data.location);
      console.log('---');
    });
  });
