/**
 * 🗺️ **Location Utilities for Thailand**
 * ระบบหาจังหวัดและจัดการพิกัดสำหรับประเทศไทย
 * 
 * **ฟีเจอร์:**
 * - Reverse geocoding จาก lat/lng เป็นจังหวัด
 * - Distance calculation
 * - Province name normalization
 * - Radius topic generation
 */

const admin = require('firebase-admin');

/**
 * 🏛️ **ข้อมูลจังหวัดทั้ง 77 จังหวัด + กรุงเทพมหานคร**
 * รวมพิกัดกลางของแต่ละจังหวัดสำหรับการคำนวณ
 */
const THAI_PROVINCES = {
  // ภาคเหนือ
  'chiangmai': { name: 'เชียงใหม่', lat: 18.7883, lng: 98.9853, region: 'north' },
  'chiangrai': { name: 'เชียงราย', lat: 19.9105, lng: 99.8407, region: 'north' },
  'lamphun': { name: 'ลำพูน', lat: 18.5745, lng: 99.0096, region: 'north' },
  'lampang': { name: 'ลำปาง', lat: 18.2932, lng: 99.4956, region: 'north' },
  'mae_hong_son': { name: 'แม่ฮ่องสอน', lat: 19.3014, lng: 97.9676, region: 'north' },
  'nan': { name: 'น่าน', lat: 18.7793, lng: 100.7724, region: 'north' },
  'phayao': { name: 'พะเยา', lat: 19.1921, lng: 99.8956, region: 'north' },
  'phrae': { name: 'แพร่', lat: 18.1459, lng: 100.1410, region: 'north' },
  'uttaradit': { name: 'อุตรดิตถ์', lat: 17.6200, lng: 100.0992, region: 'north' },

  // ภาคตะวันออกเฉียงเหนือ
  'khon_kaen': { name: 'ขอนแก่น', lat: 16.4419, lng: 102.8360, region: 'northeast' },
  'nakhon_ratchasima': { name: 'นครราชสีมา', lat: 14.9799, lng: 102.0977, region: 'northeast' },
  'udon_thani': { name: 'อุดรธานี', lat: 17.4138, lng: 102.7859, region: 'northeast' },
  'buriram': { name: 'บุรีรัมย์', lat: 14.9930, lng: 103.1029, region: 'northeast' },
  'chaiyaphum': { name: 'ชัยภูมิ', lat: 15.8069, lng: 102.0317, region: 'northeast' },
  'kalasin': { name: 'กาฬสินธุ์', lat: 16.4322, lng: 103.5059, region: 'northeast' },
  'loei': { name: 'เลย', lat: 17.4860, lng: 101.7223, region: 'northeast' },
  'maha_sarakham': { name: 'มหาสารคาม', lat: 16.1840, lng: 103.3057, region: 'northeast' },
  'mukdahan': { name: 'มุกดาหาร', lat: 16.5419, lng: 104.7234, region: 'northeast' },
  'nakhon_phanom': { name: 'นครพนม', lat: 17.4085, lng: 104.7686, region: 'northeast' },
  'nong_bua_lam_phu': { name: 'หนองบัวลำภู', lat: 17.2044, lng: 102.4281, region: 'northeast' },
  'nong_khai': { name: 'หนองคาย', lat: 17.8782, lng: 102.7412, region: 'northeast' },
  'roi_et': { name: 'ร้อยเอ็ด', lat: 16.0544, lng: 103.6533, region: 'northeast' },
  'sakon_nakhon': { name: 'สกลนคร', lat: 17.1547, lng: 104.1486, region: 'northeast' },
  'si_sa_ket': { name: 'ศรีสะเกษ', lat: 15.1186, lng: 104.3220, region: 'northeast' },
  'surin': { name: 'สุรินทร์', lat: 14.8818, lng: 103.4941, region: 'northeast' },
  'ubon_ratchathani': { name: 'อุบลราชธานี', lat: 15.2286, lng: 104.8666, region: 'northeast' },
  'yasothon': { name: 'ยโสธร', lat: 15.7924, lng: 104.1450, region: 'northeast' },
  'amnat_charoen': { name: 'อำนาจเจริญ', lat: 15.8651, lng: 104.6259, region: 'northeast' },
  'bueng_kan': { name: 'บึงกาฬ', lat: 18.3609, lng: 103.6469, region: 'northeast' },

  // ภาคกลาง
  'bangkok': { name: 'กรุงเทพมหานคร', lat: 13.7563, lng: 100.5018, region: 'central' },
  'nonthaburi': { name: 'นนทบุรี', lat: 13.8621, lng: 100.5144, region: 'central' },
  'pathum_thani': { name: 'ปทุมธานี', lat: 14.0208, lng: 100.5250, region: 'central' },
  'samut_prakan': { name: 'สมุทรปราการ', lat: 13.5990, lng: 100.5998, region: 'central' },
  'samut_sakhon': { name: 'สมุทรสาคร', lat: 13.5476, lng: 100.2740, region: 'central' },
  'samut_songkhram': { name: 'สมุทรสงคราม', lat: 13.4105, lng: 100.0020, region: 'central' },
  'nakhon_pathom': { name: 'นครปฐม', lat: 13.8199, lng: 100.0617, region: 'central' },
  'ayutthaya': { name: 'พระนครศรีอยุธยา', lat: 14.3532, lng: 100.5754, region: 'central' },
  'ang_thong': { name: 'อ่างทอง', lat: 14.5896, lng: 100.4548, region: 'central' },
  'lopburi': { name: 'ลพบุรี', lat: 14.7995, lng: 100.6534, region: 'central' },
  'sing_buri': { name: 'สิงห์บุรี', lat: 14.8936, lng: 100.3967, region: 'central' },
  'chai_nat': { name: 'ชัยนาท', lat: 15.1851, lng: 100.1248, region: 'central' },
  'suphan_buri': { name: 'สุพรรณบุรี', lat: 14.4746, lng: 100.1217, region: 'central' },
  'uthai_thani': { name: 'อุทัยธานี', lat: 15.3794, lng: 100.0244, region: 'central' },
  'kanchanaburi': { name: 'กาญจนบุรี', lat: 14.0227, lng: 99.5328, region: 'central' },
  'ratchaburi': { name: 'ราชบุรี', lat: 13.5282, lng: 99.8134, region: 'central' },
  'phetchaburi': { name: 'เพชรบุรี', lat: 13.1119, lng: 99.9398, region: 'central' },
  'prachuap_khiri_khan': { name: 'ประจวบคีรีขันธ์', lat: 11.8103, lng: 99.7971, region: 'central' },

  // ภาคตะวันออก
  'chonburi': { name: 'ชลบุรี', lat: 13.3611, lng: 100.9847, region: 'east' },
  'rayong': { name: 'ระยอง', lat: 12.6807, lng: 101.2818, region: 'east' },
  'chanthaburi': { name: 'จันทบุรี', lat: 12.6117, lng: 102.1038, region: 'east' },
  'trat': { name: 'ตราด', lat: 12.2436, lng: 102.5152, region: 'east' },
  'sa_kaeo': { name: 'สระแก้ว', lat: 13.8240, lng: 102.0645, region: 'east' },
  'prachinburi': { name: 'ปราจีนบุรี', lat: 14.0426, lng: 101.3703, region: 'east' },
  'nakhon_nayok': { name: 'นครนายก', lat: 14.2069, lng: 101.2130, region: 'east' },

  // ภาคใต้
  'chumphon': { name: 'ชุมพร', lat: 10.4930, lng: 99.1800, region: 'south' },
  'ranong': { name: 'ระนอง', lat: 9.9558, lng: 98.6353, region: 'south' },
  'surat_thani': { name: 'สุราษฎร์ธานี', lat: 9.1382, lng: 99.3215, region: 'south' },
  'phang_nga': { name: 'พังงา', lat: 8.4504, lng: 98.5254, region: 'south' },
  'phuket': { name: 'ภูเก็ต', lat: 7.8804, lng: 98.3923, region: 'south' },
  'krabi': { name: 'กระบี่', lat: 8.0863, lng: 98.9063, region: 'south' },
  'nakhon_si_thammarat': { name: 'นครศรีธรรมราช', lat: 8.4304, lng: 99.9631, region: 'south' },
  'phatthalung': { name: 'พัทลุง', lat: 7.6166, lng: 100.0714, region: 'south' },
  'trang': { name: 'ตรัง', lat: 7.5563, lng: 99.6114, region: 'south' },
  'satun': { name: 'สตูล', lat: 6.6231, lng: 100.0673, region: 'south' },
  'songkhla': { name: 'สงขลา', lat: 7.1756, lng: 100.6135, region: 'south' },
  'pattani': { name: 'ปัตตานี', lat: 6.8693, lng: 101.2502, region: 'south' },
  'yala': { name: 'ยะลา', lat: 6.5410, lng: 101.2802, region: 'south' },
  'narathiwat': { name: 'นราธิวาส', lat: 6.4254, lng: 101.8253, region: 'south' },

  // ภาคตะวันตก
  'tak': { name: 'ตาก', lat: 16.8839, lng: 99.1256, region: 'west' },
  'mae_sot': { name: 'แม่สอด', lat: 16.7161, lng: 98.5445, region: 'west' },
  'kamphaeng_phet': { name: 'กำแพงเพชร', lat: 16.4823, lng: 99.5225, region: 'west' },
  'nakhon_sawan': { name: 'นครสวรรค์', lat: 15.7047, lng: 100.1378, region: 'west' },
  'phichit': { name: 'พิจิตร', lat: 16.4387, lng: 100.3489, region: 'west' },
  'phitsanulok': { name: 'พิษณุโลก', lat: 16.8211, lng: 100.2659, region: 'west' },
  'sukhothai': { name: 'สุโขทัย', lat: 17.0061, lng: 99.8230, region: 'west' }
};

/**
 * 📏 **คำนวณระยะทางระหว่าง 2 จุด (Haversine Formula)**
 * @param {number} lat1 - Latitude จุดที่ 1
 * @param {number} lng1 - Longitude จุดที่ 1
 * @param {number} lat2 - Latitude จุดที่ 2
 * @param {number} lng2 - Longitude จุดที่ 2
 * @returns {number} ระยะทางเป็นกิโลเมตร
 */
function calculateDistance(lat1, lng1, lat2, lng2) {
  const R = 6371; // รัศมีโลกเป็นกิโลเมตร
  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);
  
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
           Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
           Math.sin(dLng / 2) * Math.sin(dLng / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * 🔄 **แปลงองศาเป็น Radians**
 */
function toRadians(degrees) {
  return degrees * (Math.PI / 180);
}

/**
 * 🗺️ **หาจังหวัดจากพิกัด (Reverse Geocoding)**
 * @param {number} latitude - ละติจูด
 * @param {number} longitude - ลองจิจูด
 * @returns {string} ชื่อจังหวัดภาษาอังกฤษ (เช่น 'bangkok', 'chiang_mai')
 */
async function getProvinceFromCoords(latitude, longitude) {
  try {
    let nearestProvince = null;
    let minDistance = Infinity;

    // หาจังหวัดที่ใกล้ที่สุด
    for (const [key, province] of Object.entries(THAI_PROVINCES)) {
      const distance = calculateDistance(
        latitude, longitude,
        province.lat, province.lng
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestProvince = key;
      }
    }

    console.log(`📍 Location: ${latitude}, ${longitude} → Province: ${nearestProvince} (${minDistance.toFixed(2)} km)`);
    return nearestProvince;
    
  } catch (error) {
    console.error('❌ Error in reverse geocoding:', error);
    // Default fallback เป็นกรุงเทพ
    return 'bangkok';
  }
}

/**
 * 🏷️ **สร้าง Topics สำหรับ Location-based Notifications**
 * @param {number} latitude - ละติจูด
 * @param {number} longitude - ลองจิจูด
 * @param {number} radiusKm - รัศมีเป็นกิโลเมตร (default: 30)
 * @returns {Object} { provinceTopics: string[], radiusTopics: string[] }
 */
async function generateLocationTopics(latitude, longitude, radiusKm = 30) {
  try {
    // 1. หาจังหวัดปัจจุบัน
    const province = await getProvinceFromCoords(latitude, longitude);
    
    // 2. สร้าง Province Topic
    const provinceTopic = `${province}_notifications`;
    
    // 3. สร้าง Radius Topic (precision 4 ตำแหน่ง ≈ 10m accuracy)
    const lat = latitude.toFixed(4);
    const lng = longitude.toFixed(4);
    const radiusTopic = `radius_${radiusKm}km_${lat}_${lng}`;
    
    // 4. หา Cross-province topics (จังหวัดข้างเคียงในรัศมี)
    const nearbyProvinces = [];
    for (const [key, provinceData] of Object.entries(THAI_PROVINCES)) {
      if (key === province) continue; // ข้ามจังหวัดปัจจุบัน
      
      const distance = calculateDistance(
        latitude, longitude,
        provinceData.lat, provinceData.lng
      );
      
      // ถ้าใจกลางจังหวัดอยู่ในรัศมี ให้เพิ่มเข้าไป
      if (distance <= radiusKm) {
        nearbyProvinces.push(`${key}_notifications`);
      }
    }

    const result = {
      primary: provinceTopic,
      radius: radiusTopic,
      crossProvince: nearbyProvinces,
      allTopics: [provinceTopic, radiusTopic, ...nearbyProvinces],
      location: {
        province: THAI_PROVINCES[province]?.name || 'ไม่ทราบ',
        region: THAI_PROVINCES[province]?.region || 'unknown'
      }
    };

    console.log(`🎯 Generated Topics:`, result);
    return result;
    
  } catch (error) {
    console.error('❌ Error generating location topics:', error);
    
    // Fallback topics
    return {
      primary: 'bangkok_notifications',
      radius: `radius_${radiusKm}km_13.7563_100.5018`,
      crossProvince: [],
      allTopics: ['bangkok_notifications', `radius_${radiusKm}km_13.7563_100.5018`],
      location: {
        province: 'กรุงเทพมหานคร',
        region: 'central'
      }
    };
  }
}

/**
 * 🔍 **ตรวจสอบว่าผู้ใช้อยู่ในรัศมีของโพสหรือไม่**
 * @param {number} userLat - ละติจูดผู้ใช้
 * @param {number} userLng - ลองจิจูดผู้ใช้
 * @param {number} postLat - ละติจูดโพส
 * @param {number} postLng - ลองจิจูดโพส
 * @param {number} radiusKm - รัศมีเป็นกิโลเมตร
 * @returns {boolean} true ถ้าอยู่ในรัศมี
 */
function isWithinRadius(userLat, userLng, postLat, postLng, radiusKm) {
  const distance = calculateDistance(userLat, userLng, postLat, postLng);
  return distance <= radiusKm;
}

/**
 * 📊 **ข้อมูลสถิติการใช้งาน Location Topics**
 */
async function getLocationTopicsStats() {
  try {
    const stats = {
      totalProvinces: Object.keys(THAI_PROVINCES).length,
      regions: {},
      sampleTopics: [
        'bangkok_notifications',
        'chiang_mai_notifications',
        'radius_30km_13.7563_100.5018',
        'radius_30km_18.7883_98.9853'
      ]
    };

    // นับจำนวนจังหวัดแต่ละภาค
    for (const province of Object.values(THAI_PROVINCES)) {
      stats.regions[province.region] = (stats.regions[province.region] || 0) + 1;
    }

    console.log('📊 Location Topics Statistics:', stats);
    return stats;
    
  } catch (error) {
    console.error('❌ Error getting location stats:', error);
    return null;
  }
}

module.exports = {
  getProvinceFromCoords,
  generateLocationTopics,
  calculateDistance,
  isWithinRadius,
  getLocationTopicsStats,
  THAI_PROVINCES
};
