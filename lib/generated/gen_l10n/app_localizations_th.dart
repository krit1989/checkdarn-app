// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get searchingPostsInArea => 'กำลังค้นหาโพสในบริเวณนี้...';

  @override
  String movedToViewPosts(String locationName) {
    return 'ย้ายไปดูโพสในบริเวณ: $locationName';
  }

  @override
  String get selectedLocation => 'ตำแหน่งที่เลือก';

  @override
  String get cannotLoadImage => 'ไม่สามารถโหลดรูปภาพได้';

  @override
  String get comments => 'ความคิดเห็น';

  @override
  String get noTitle => 'ไม่มีหัวข้อ';

  @override
  String get anonymousUser => 'ผู้ใช้ไม่ระบุชื่อ';

  @override
  String get myLocationTooltip => 'กลับมาตำแหน่งจริงของฉัน';

  @override
  String eventsInArea(int count) {
    return 'เหตุการณ์ในบริเวณนี้ ($count รายการ)';
  }

  @override
  String get kilometerShort => 'กม.';

  @override
  String cannotGetLocationInfo(String error) {
    return 'ไม่สามารถดึงข้อมูลตำแหน่งได้: $error';
  }

  @override
  String get unknownLocation => 'ตำแหน่งที่ไม่ทราบ';

  @override
  String get zoomIn => 'ขยายเข้า';

  @override
  String get zoomOut => 'ขยายออก';

  @override
  String cannotLoadData(String error) {
    return 'ไม่สามารถโหลดข้อมูลได้: $error';
  }

  @override
  String get tryAgain => 'ลองใหม่';

  @override
  String get emergency => 'ฉุกเฉิน';

  @override
  String get category => 'ประเภท';

  @override
  String get reportWhat => 'แจ้งอะไร?';

  @override
  String get nearMe => 'ใกล้ฉัน';

  @override
  String get speedCamera => 'กล้อง';

  @override
  String get emergencyNumbers => 'เบอร์ฉุกเฉิน';

  @override
  String get police => 'ตำรวจ';

  @override
  String get traffic => 'จราจร';

  @override
  String get highway => 'กรมทางหลวง';

  @override
  String get ruralRoad => 'ทางหลวงชนบท';

  @override
  String get fireDepartment => 'ดับเพลิง';

  @override
  String get emergencyMedical => 'หน่วยแพทย์ฉุกเฉิน (EMS)';

  @override
  String get erawanCenter => 'ศูนย์เอราวัณ (กทม.)';

  @override
  String get disasterAlert => 'เตือนภัยพิบัติ';

  @override
  String get bombThreatTerrorism => 'วางเพลิง / ก่อการร้าย';

  @override
  String get diseaseControl => 'ศูนย์ควบคุมโรค';

  @override
  String get disasterPrevention => 'ป้องกันและบรรเทาสาธารณภัย (ปภ.)';

  @override
  String get ruamkatanyu => 'มูลนิธิร่วมกตัญญู';

  @override
  String get pohtecktung => 'มูลนิธิป่อเต็กตึ๊ง';

  @override
  String get cyberCrimeHotline => 'สายด่วนไซเบอร์';

  @override
  String get consumerProtection => 'สำนักงานคุ้มครองผู้บริโภค (สคบ.)';

  @override
  String get js100 => 'จส.100';

  @override
  String get touristPolice => 'ตำรวจท่องเที่ยว';

  @override
  String get tourismAuthority => 'การท่องเที่ยวแห่งประเทศไทย (ททท.)';

  @override
  String get harborDepartment => 'กรมเจ้าท่า';

  @override
  String get waterAccident => 'อุบัติเหตุทางน้ำ';

  @override
  String get expressway => 'การทางพิเศษแห่งประเทศไทย (ทางด่วน)';

  @override
  String get transportCooperative => 'ขสมก.';

  @override
  String get busVan => 'รถโดยสาร / รถตู้';

  @override
  String get taxiGrab => 'แท็กซี่ / Grab';

  @override
  String get meaElectricity => 'การไฟฟ้านครหลวง (MEA)';

  @override
  String get peaElectricity => 'การไฟฟ้าส่วนภูมิภาค (PEA)';

  @override
  String cannotCallPhone(String phoneNumber) {
    return 'ไม่สามารถโทรหาเบอร์ $phoneNumber ได้\nกรุณาตรวจสอบว่าอุปกรณ์รองรับการโทรออก';
  }

  @override
  String get selectCategory => 'เลือกประเภท';

  @override
  String selectedOfTotal(int selected, int total) {
    return '$selected จาก $total รายการ';
  }

  @override
  String get categoryCheckpoint => 'ด่านตรวจ';

  @override
  String get categoryAccident => 'อุบัติเหตุ';

  @override
  String get categoryFire => 'ไฟไหม้';

  @override
  String get categoryFloodRain => 'ฝนตก/น้ำท่วม';

  @override
  String get categoryTsunami => 'สึนามิ';

  @override
  String get categoryEarthquake => 'แผ่นดินไหว';

  @override
  String get categoryAnimalLost => 'สัตว์เลี้ยงหาย';

  @override
  String get categoryQuestion => 'คำถามทั่วไป';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get notifications => 'การแจ้งเตือน';

  @override
  String get speedCameraSoundAlert => 'เสียงเตือนกล้องจับความเร็ว';

  @override
  String get enableNotifications => 'เปิดการแจ้งเตือน';

  @override
  String get enableNotificationsDesc => 'แจ้งเตือนเมื่อมีเหตุการณ์ใหม่';

  @override
  String get general => 'ทั่วไป';

  @override
  String get thaiVoice => 'เสียงไทย';

  @override
  String get language => 'ภาษา';

  @override
  String get selectLanguage => 'เลือกภาษา';

  @override
  String get thai => 'ไทย';

  @override
  String get english => 'English';

  @override
  String get currentlySelected => 'ถูกเลือกอยู่แล้ว';

  @override
  String get comingSoon => 'เร็ว ๆ นี้!';

  @override
  String get close => 'ปิด';

  @override
  String get shareApp => 'แชร์แอป';

  @override
  String get shareAppDesc => 'แชร์แอปกับเพื่อน ๆ';

  @override
  String get reviewApp => 'รีวิวแอป';

  @override
  String get reviewAppDesc => 'ให้คะแนนแอปใน App Store';

  @override
  String get aboutApp => 'เกี่ยวกับแอป';

  @override
  String get version => 'เวอร์ชัน';

  @override
  String get termsOfService => 'ข้อกำหนดการใช้งาน';

  @override
  String get privacyPolicy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get contactUs => 'ติดต่อเรา';

  @override
  String get sendFeedbackOrReport => 'ส่งข้อเสนอแนะหรือรายงานปัญหา';

  @override
  String get email => 'อีเมล';

  @override
  String get openEmailApp => 'เปิดแอปอีเมล';

  @override
  String get reportProblem => 'รายงานปัญหา';

  @override
  String get reportProblemDesc => 'แจ้งปัญหาการใช้งาน';

  @override
  String get reportFeatureComingSoon => 'ฟีเจอร์รายงานปัญหาเร็ว ๆ นี้!';

  @override
  String get logoutTitle => 'ออกจากระบบ';

  @override
  String get logoutMessage => 'คุณต้องการออกจากระบบหรือไม่?';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get securityValidationFailed => 'การตรวจสอบความปลอดภัยล้มเหลว';

  @override
  String get logoutFailed => 'การออกจากระบบล้มเหลว';

  @override
  String get welcomeTo => 'ยินดีต้อนรับสู่';

  @override
  String get termsOfServiceTitle => 'เงื่อนไขการใช้งาน';

  @override
  String get termsOfServiceHeader => '📋 เงื่อนไขการใช้งาน CheckDarn';

  @override
  String get lastUpdated => 'อัปเดตล่าสุด: 8 สิงหาคม 2568';

  @override
  String get acceptanceOfTermsTitle => '1. การยอมรับเงื่อนไข';

  @override
  String get acceptanceOfTermsContent =>
      'การใช้งานแอปพลิเคชัน CheckDarn ถือว่าท่านยอมรับและตกลงที่จะปฏิบัติตามเงื่อนไขการใช้งานทั้งหมด หากท่านไม่ยอมรับเงื่อนไขเหล่านี้ กรุณาหยุดใช้งานแอปพลิเคชันทันที';

  @override
  String get purposeOfUseTitle => '2. วัตถุประสงค์การใช้งาน';

  @override
  String get purposeOfUseContent =>
      'CheckDarn เป็นแอปพลิเคชันสำหรับรายงานและแจ้งเตือนเหตุการณ์ต่างๆ ในพื้นที่ เช่น การจราจร อุบัติเหตุ หรือเหตุการณ์สำคัญอื่นๆ เพื่อช่วยให้ชุมชนได้รับข้อมูลข่าวสารที่เป็นประโยชน์';

  @override
  String get appropriateUseTitle => '3. การใช้งานที่เหมาะสม';

  @override
  String get appropriateUseContent =>
      'ผู้ใช้ต้องใช้งานแอปพลิเคชันด้วยความรับผิดชอบ ไม่โพสต์ข้อมูลที่เป็นเท็จ หยาบคาย หรือผิดกฎหมาย ข้อมูลที่รายงานควรเป็นข้อเท็จจริงและเป็นประโยชน์ต่อส่วนรวม';

  @override
  String get privacyTitle => '4. ความเป็นส่วนตัว';

  @override
  String get privacyContent =>
      'เราให้ความสำคัญกับความเป็นส่วนตัวของผู้ใช้ ข้อมูลส่วนบุคคลจะถูกเก็บรักษาอย่างปลอดภัยและใช้เฉพาะเพื่อการพัฒนาและปรับปรุงบริการเท่านั้น';

  @override
  String get responsibilityTitle => '5. การรับผิดชอบ';

  @override
  String get responsibilityContent =>
      'ผู้พัฒนาแอปพลิเคชันไม่รับผิดชอบต่อความเสียหายใดๆ ที่เกิดจากการใช้งานแอปพลิเคชัน ผู้ใช้ต้องใช้วิจารณญาณในการตัดสินใจจากข้อมูลที่ได้รับ';

  @override
  String get modificationsTitle => '6. การแก้ไขเงื่อนไข';

  @override
  String get modificationsContent =>
      'เราสงวนสิทธิ์ในการแก้ไขเงื่อนไขการใช้งานได้ตลอดเวลา การแก้ไขจะมีผลทันทีหลังจากประกาศในแอปพลิเคชัน';

  @override
  String get contactTitle => '7. การติดต่อ';

  @override
  String get contactContent =>
      'หากมีข้อสงสัยหรือต้องการติดต่อเกี่ยวกับเงื่อนไขการใช้งาน สามารถติดต่อผ่านทางแอปพลิเคชันหรือช่องทางที่กำหนด';

  @override
  String get thankYouForUsing => '✅ ขอบคุณที่ใช้งาน CheckDarn';

  @override
  String get communityMessage =>
      'ร่วมสร้างชุมชนที่ปลอดภัยและมีข้อมูลข่าวสารที่ดี';

  @override
  String get privacyPolicyTitle => 'นโยบายความเป็นส่วนตัว';

  @override
  String get privacyPolicyHeader => '🔒 นโยบายความเป็นส่วนตัว CheckDarn';

  @override
  String get effectiveFrom => 'มีผลตั้งแต่: 8 สิงหาคม 2568';

  @override
  String get dataCollectionTitle => '1. ข้อมูลที่เราเก็บรวบรวม';

  @override
  String get dataCollectionContent =>
      'เราเก็บรวบรวมข้อมูลเมื่อคุณใช้งานแอปพลิเคชัน CheckDarn ประกอบด้วย:\n\n• ข้อมูลบัญชี: อีเมล ชื่อผู้ใช้ รูปโปรไฟล์\n• ข้อมูลตำแหน่ง: GPS location เพื่อแสดงและรายงานเหตุการณ์\n• ข้อมูลการใช้งาน: เวลาการเข้าใช้ ประเภทการรายงาน\n• ข้อมูลอุปกรณ์: รุ่นมือถือ ระบบปฏิบัติการ';

  @override
  String get dataUsageTitle => '2. วัตถุประสงค์การใช้ข้อมูล';

  @override
  String get dataUsageContent =>
      'เราใช้ข้อมูลของคุณเพื่อ:\n\n• ให้บริการรายงานและแจ้งเตือนเหตุการณ์\n• แสดงเหตุการณ์บนแผนที่ตามตำแหน่งที่เหมาะสม\n• ปรับปรุงและพัฒนาคุณภาพแอปพลิเคชัน\n• ส่งการแจ้งเตือนที่จำเป็นและเกี่ยวข้อง\n• รักษาความปลอดภัยและป้องกันการใช้งานที่ผิดต้อง';

  @override
  String get dataSharingTitle => '3. การแบ่งปันข้อมูล';

  @override
  String get dataSharingContent =>
      'เราไม่ขายหรือให้เช่าข้อมูลส่วนบุคคลของคุณแก่บุคคลที่สาม\n\nเราอาจแบ่งปันข้อมูลในกรณีต่อไปนี้:\n\n• เมื่อได้รับความยินยอมจากคุณ\n• เพื่อปฏิบัติตามกฎหมายหรือคำสั่งศาล\n• เพื่อปกป้องสิทธิและความปลอดภัยของผู้ใช้\n• ข้อมูลที่เปิดเผยต่อสาธารณะ (รายงานที่ผู้ใช้เลือกแชร์)';

  @override
  String get dataSecurityTitle => '4. ความปลอดภัยของข้อมูล';

  @override
  String get dataSecurityContent =>
      'เราให้ความสำคัญกับการปกป้องข้อมูลของคุณ:\n\n• ใช้การเข้ารหัสข้อมูลขณะส่งและจัดเก็บ\n• มีระบบยืนยันตัวตนที่ปลอดภัย\n• จำกัดการเข้าถึงข้อมูลเฉพาะบุคลากรที่จำเป็น\n• ตรวจสอบและอัพเดตระบบความปลอดภัยอย่างสม่ำเสมอ';

  @override
  String get userRightsTitle => '5. สิทธิของผู้ใช้';

  @override
  String get userRightsContent =>
      'คุณมีสิทธิต่อข้อมูลส่วนบุคคลของคุณ:\n\n• สิทธิเข้าถึง: ขอดูข้อมูลที่เราเก็บรวบรวม\n• สิทธิแก้ไข: ขอแก้ไขข้อมูลที่ไม่ถูกต้อง\n• สิทธิลบ: ขอลบข้อมูลส่วนบุคคล\n• สิทธิถอนความยินยอม: ยกเลิกการใช้บริการได้ตลอดเวลา\n• สิทธิร้องเรียน: แจ้งปัญหาเกี่ยวกับการใช้ข้อมูล';

  @override
  String get cookiesTitle => '6. Cookies และเทคโนโลยีติดตาม';

  @override
  String get cookiesContent =>
      'แอปพลิเคชันอาจใช้เทคโนโลยีเหล่านี้:\n\n• Local Storage: เก็บการตั้งค่าและข้อมูลชั่วคราว\n• Analytics: วิเคราะห์การใช้งานเพื่อปรับปรุงแอป\n• Push Notifications: ส่งการแจ้งเตือนที่จำเป็น\n• Firebase Services: บริการคลาวด์สำหรับจัดเก็บข้อมูล';

  @override
  String get policyChangesTitle => '7. การเปลี่ยนแปลงนโยบาย';

  @override
  String get policyChangesContent =>
      'เราอาจปรับปรุงนโยบายความเป็นส่วนตัวเป็นครั้งคราว\n\n• จะแจ้งให้ทราบล่วงหน้าหากมีการเปลี่ยนแปลงสำคัญ\n• การใช้งานต่อไปถือว่ายอมรับนโยบายใหม่\n• ควรตรวจสอบนโยบายอัพเดตอย่างสม่ำเสมอ';

  @override
  String get contactPrivacyTitle => '8. การติดต่อ';

  @override
  String get contactPrivacyContent =>
      'หากมีคำถามเกี่ยวกับนโยบายความเป็นส่วนตัว:\n\n• ติดต่อผ่านแอปพลิเคชัน\n• ส่งอีเมลไปยังทีมสนับสนุน\n• ใช้ฟีเจอร์ \"ติดต่อเรา\" ในหน้าการตั้งค่า';

  @override
  String get respectPrivacy => '🛡️ เราเคารพความเป็นส่วนตัวของคุณ';

  @override
  String get securityMessage =>
      'ข้อมูลของคุณได้รับการปกป้องด้วยมาตรฐานความปลอดภัยสูงสุด';

  @override
  String get cannotOpenEmailApp => 'ไม่สามารถเปิดแอปอีเมลได้ กรุณาลองวิธีอื่น';

  @override
  String get emailAppOpened => 'กำลังเปิดแอปอีเมล...';

  @override
  String get nearMeTitle => 'ใกล้ฉัน';

  @override
  String get allCategories => 'ทั้งหมด';

  @override
  String get myPosts => 'โพสต์ของฉัน';

  @override
  String get noReportsYet => 'ยังไม่มีรายการแจ้งเหตุ';

  @override
  String get startWithFirstReport => 'เริ่มต้นด้วยการแจ้งเหตุครั้งแรกของคุณ';

  @override
  String get postStatistics => 'สถิติโพสต์';

  @override
  String totalPosts(int count) {
    return 'โพสต์ทั้งหมด: $count รายการ';
  }

  @override
  String freshPosts(int count) {
    return 'โพสต์สดใหม่ (24 ชม.): $count รายการ';
  }

  @override
  String oldPosts(int count) {
    return 'โพสต์เก่า: $count รายการ';
  }

  @override
  String get autoDeleteNotice =>
      'โพสต์จะถูกลบอัตโนมัติหลัง 24 ชั่วโมง\nเพื่อรักษาความสดใหม่ของข้อมูล';

  @override
  String get deleteOldPostsNow => 'ลบโพสต์เก่าตอนนี้';

  @override
  String get deletingOldPosts => 'กำลังลบโพสต์เก่า...';

  @override
  String deleteComplete(int count) {
    return 'ลบเสร็จแล้ว! เหลือโพสต์สดใหม่ $count รายการ';
  }

  @override
  String deleteError(String error) {
    return 'เกิดข้อผิดพลาดในการลบ: $error';
  }

  @override
  String generalError(String error) {
    return 'เกิดข้อผิดพลาด: $error';
  }

  @override
  String get viewMap => 'ดูแผนที่';

  @override
  String get clickToViewImage => 'คลิกดูรูปภาพ';

  @override
  String get devOnly => 'ดูสถิติโพสต์ (Dev Only)';

  @override
  String get meters => 'ม.';

  @override
  String get kilometers => 'กม.';

  @override
  String get reportScreenTitle => 'แจ้งอะไร?';

  @override
  String get selectEventType => 'เลือกประเภทเหตุการณ์ *';

  @override
  String get detailsField => 'รายละเอียด *';

  @override
  String get clickToSelectLocation => 'คลิกเพื่อเลือกตำแหน่ง';

  @override
  String get willTakeToCurrentLocation => 'จะพาไปที่ตำแหน่งปัจจุบันของคุณ *';

  @override
  String get findingCurrentLocation => 'กำลังค้นหาตำแหน่งปัจจุบัน...';

  @override
  String get loadingAddressInfo => 'กำลังโหลดข้อมูลที่อยู่...';

  @override
  String get tapToChangeLocation => 'แตะเพื่อเปลี่ยนตำแหน่ง';

  @override
  String get imageOnlyForLostAnimals =>
      'สามารถแนบรูปภาพได้เฉพาะในหัวข้อ \"สัตว์เลี้ยงหาย\" เท่านั้น\nเพื่อป้องกันเนื้อหาที่ไม่เหมาะสม';

  @override
  String get selectImageSource => 'เลือกแหล่งรูปภาพ';

  @override
  String get gallery => 'แกลเลอรี่';

  @override
  String get camera => 'กล้อง';

  @override
  String get addImage => 'เพิ่มรูปภาพ (ไม่บังคับ)';

  @override
  String get change => 'เปลี่ยน';

  @override
  String get save => 'ส่ง';

  @override
  String get sending => 'กำลังส่ง...';

  @override
  String get securityValidationFailedImage =>
      'การตรวจสอบความปลอดภัยล้มเหลว ไม่สามารถอัปโหลดรูปภาพได้';

  @override
  String get webpCompression => 'WebP Compression...';

  @override
  String get imageUploadSuccess => 'อัพโหลดรูปภาพสำเร็จ!';

  @override
  String get cannotProcessImage => 'ไม่สามารถประมวลผลรูปภาพได้';

  @override
  String imageSelectionError(String error) {
    return 'เกิดข้อผิดพลาดในการเลือกรูปภาพ: $error';
  }

  @override
  String get securityValidationFailedGeneral =>
      'การตรวจสอบความปลอดภัยล้มเหลว กรุณาลองใหม่อีกครั้ง';

  @override
  String pleaseSelectCoordinates(String field) {
    return 'กรุณาเลือกพิกัด: $field';
  }

  @override
  String pleaseFillData(String field) {
    return 'กรุณากรอกข้อมูล: $field';
  }

  @override
  String get eventLocation => 'ตำแหน่งเหตุการณ์';

  @override
  String get userNotFound => 'ไม่พบข้อมูลผู้ใช้ กรุณาล็อกอินใหม่';

  @override
  String get dailyLimitExceeded => 'เกินขีดจำกัด 5 โพสต์ต่อวัน กรุณารอ 24 ชม.';

  @override
  String get cannotGetLocation =>
      'ไม่สามารถระบุตำแหน่งได้ กรุณาเลือกตำแหน่งด้วยตนเอง';

  @override
  String get success => 'ส่งสำเร็จ';

  @override
  String get submitTimeoutError =>
      'ส่งรายงานไม่สำเร็จ: เกินเวลารอคอย กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';

  @override
  String get submitError => 'เกิดข้อผิดพลาดในการส่งรายงาน';

  @override
  String get networkError => 'ปัญหาการเชื่อมต่อเครือข่าย กรุณาตรวจสอบ WiFi/4G';

  @override
  String get permissionError =>
      'ไม่มีสิทธิ์ในการอัพโหลด กรุณาติดต่อผู้ดูแลระบบ';

  @override
  String get storageError => 'ปัญหาการอัพโหลดไฟล์ กรุณาลองส่งโดยไม่มีรูปภาพ';

  @override
  String get fileSizeError => 'ไฟล์รูปใหญ่เกินไป กรุณาลองถ่ายรูปใหม่';

  @override
  String get persistentError => 'หากปัญหายังคงอยู่ ลองส่งโดยไม่มีรูปภาพ';

  @override
  String get tryAgainAction => 'ลองใหม่';

  @override
  String get pleaseSelectEventType => 'กรุณาเลือกประเภทเหตุการณ์';

  @override
  String get pleaseFillDetails => 'กรุณากรอกรายละเอียด';

  @override
  String get selectLocation => 'เลือกตำแหน่ง';

  @override
  String get tapOnMapToSelectLocation => 'หรือแตะบนแผนที่เพื่อเลือกตำแหน่ง';

  @override
  String get currentLocation => 'ตำแหน่งปัจจุบัน';

  @override
  String get addressInformation => 'ข้อมูลที่อยู่';

  @override
  String get roadName => 'ชื่อถนน:';

  @override
  String get subDistrict => 'ตำบล/แขวง:';

  @override
  String get district => 'อำเภอ/เขต:';

  @override
  String get province => 'จังหวัด:';

  @override
  String get coordinates => 'พิกัด';

  @override
  String get manualCoordinateEntry => 'กรอกพิกัดด้วยตนเอง';

  @override
  String get latitude => 'ละติจูด';

  @override
  String get longitude => 'ลองติจูด';

  @override
  String get apply => 'นำไป';

  @override
  String get coordinatesOutOfRange => 'พิกัดต้องอยู่ในช่วงที่ถูกต้อง';

  @override
  String get invalidCoordinateFormat => 'รูปแบบพิกัดไม่ถูกต้อง';

  @override
  String get confirmLocation => 'ยืนยันตำแหน่ง';

  @override
  String get cancelAction => 'ยกเลิก';

  @override
  String get roadNameHint => 'ชื่อถนนจะแสดงอัตโนมัติ หรือพิมพ์เอง';

  @override
  String get reportComment => 'รายงานความคิดเห็น';

  @override
  String get reportCommentConfirm =>
      'คุณต้องการรายงานความคิดเห็นนี้ว่าไม่เหมาะสมหรือไม่?';

  @override
  String get reportCommentSuccess => 'รายงานความคิดเห็นเรียบร้อยแล้ว';

  @override
  String get commentsTitle => 'ความคิดเห็น';

  @override
  String get noCommentsYet => 'ยังไม่มีความคิดเห็น';

  @override
  String get beFirstToComment => 'เป็นคนแรกที่แสดงความคิดเห็น!';

  @override
  String get addCommentHint => 'เพิ่มความคิดเห็น...';

  @override
  String get pleaseEnterComment => 'กรุณาพิมพ์ความคิดเห็น';

  @override
  String get commentSentSuccess => 'ส่งความคิดเห็นสำเร็จ';

  @override
  String get typeCommentHint => 'พิมพ์ความคิดเห็น...';

  @override
  String get soundSettingsTitle => 'ตั้งค่าเสียงแจ้งเตือน';

  @override
  String get enableSoundNotifications => 'เปิดใช้งานเสียงแจ้งเตือน';

  @override
  String get enableDisableSoundDesc => 'เปิด/ปิดเสียงแจ้งเตือนทั้งหมด';

  @override
  String get selectSoundType => '🔊 เลือกประเภทเสียงแจ้งเตือน';

  @override
  String get testSound => 'ทดสอบเสียง';

  @override
  String get soundTips => '💡 คำแนะนำ';

  @override
  String get soundTipsDescription =>
      '• เสียงพูด: อ่านข้อความเป็นเสียงพูดภาษาไทย ให้ข้อมูลละเอียดและชัดเจน\n• ปิดเสียง: ไม่มีเสียงแจ้งเตือน เหมาะสำหรับสถานที่เงียบ';

  @override
  String get noSoundDescription => 'ไม่มีเสียงแจ้งเตือน เงียบสนิท';

  @override
  String get beepSoundDescription => 'เสียงบี๊บสั้นๆ (เลิกใช้แล้ว)';

  @override
  String get warningSoundDescription => 'เสียงเตือนภัยแบบไซเรน (เลิกใช้แล้ว)';

  @override
  String get ttsSoundDescription => 'อ่านข้อความเป็นเสียงพูดภาษาไทย - แนะนำ';

  @override
  String get noSoundDisplayName => 'ปิดเสียง';

  @override
  String get thaiVoiceDisplayName => 'เสียงพูดภาษาไทย';

  @override
  String testSoundSuccess(String soundType) {
    return 'ทดสอบเสียง: $soundType';
  }

  @override
  String cannotPlaySound(String error) {
    return 'ไม่สามารถเล่นเสียงได้: $error';
  }

  @override
  String get cameraReportTitle => 'เพิ่มกล้องจับความเร็ว';

  @override
  String get switchToNearbyView => 'เปลี่ยนเป็นดูเฉพาะใกล้เคียง';

  @override
  String get switchToNationwideView => 'เปลี่ยนเป็นดูทั่วประเทศ';

  @override
  String get newReportTab => 'เพิ่มใหม่';

  @override
  String get votingTab => 'โหวต';

  @override
  String get statisticsTab => 'สถิติ';

  @override
  String get howToReportTitle => 'วิธีการรายงาน';

  @override
  String get howToReportDescription =>
      '• รายงานกล้องใหม่ที่คุณพบเจอ\n• รายงานการเปลี่ยนจำกัดความเร็ว\n• ข้อมูลจะถูกตรวจสอบโดยชุมชน\n• เมื่อได้รับการยืนยัน ระบบจะดำเนินการอัตโนมัติ\n• คุณไม่สามารถโหวตรายงานของตัวเองได้';

  @override
  String get reportSubmittedSuccess =>
      'ส่งรายงานเรียบร้อยแล้ว! ตรวจสอบในแท็บโหวต';

  @override
  String get showingNationwidePosts => 'แสดงโพสต์จากทั่วประเทศ';

  @override
  String get showingNearbyPosts => 'แสดงโพสต์ใกล้เคียง';

  @override
  String radiusKm(int radius) {
    return 'รัศมี: $radius กม.';
  }

  @override
  String totalPostsCount(int count) {
    return 'โพสต์ทั้งหมด: $count';
  }

  @override
  String nearbyPostsCount(int count) {
    return 'โพสต์ใกล้เคียง: $count';
  }

  @override
  String get nearby => 'ใกล้เคียง';

  @override
  String get nationwide => 'ทั่วประเทศ';

  @override
  String get loginRequiredToVote => 'จำเป็นต้องล็อกอินเพื่อโหวต';

  @override
  String get loginThroughMapProfile => 'กรุณาล็อกอินผ่านโปรไฟล์ในหน้าแผนที่';

  @override
  String get tapProfileButtonOnMap => 'แตะที่ปุ่มโปรไฟล์มุมขวาบนของแผนที่';

  @override
  String get loadingData => 'กำลังโหลดข้อมูล...';

  @override
  String get noPendingReports => 'ไม่มีรายงานที่รอการโหวต';

  @override
  String get thankYouForVerifying => 'ขอบคุณที่ช่วยตรวจสอบข้อมูล!';

  @override
  String get voting => 'กำลังโหวต...';

  @override
  String get voteUpvoteSuccess => 'โหวต \"มีจริง\" เรียบร้อยแล้ว';

  @override
  String get voteDownvoteSuccess => 'โหวต \"ไม่มี\" เรียบร้อยแล้ว';

  @override
  String get alreadyVoted => 'คุณได้โหวตรายงานนี้แล้ว';

  @override
  String get voteSuccessfullyRecorded =>
      'โหวตเรียบร้อยแล้ว!\n(ระบบตรวจสอบว่าคุณได้โหวตแล้ว)';

  @override
  String get noPermissionToVote =>
      'ไม่มีสิทธิ์ในการโหวต\nลองออกจากระบบและล็อกอินใหม่';

  @override
  String get reportNotFound => 'ไม่พบรายงานนี้ อาจถูกลบไปแล้ว';

  @override
  String get connectionProblem =>
      'ปัญหาการเชื่อมต่อ\nกรุณาตรวจสอบอินเทอร์เน็ตและลองใหม่';

  @override
  String get cannotVoteRetry => 'ไม่สามารถโหวตได้ กรุณาลองใหม่';

  @override
  String get retry => 'ลองใหม่';

  @override
  String get loginRequiredForStats => 'จำเป็นต้องล็อกอินเพื่อดูสถิติ';

  @override
  String get contributionScore => 'คะแนนการมีส่วนร่วม';

  @override
  String get totalContributions => 'การมีส่วนร่วมทั้งหมด';

  @override
  String get reportsSubmitted => 'รายงานส่ง';

  @override
  String get votesGiven => 'โหวตให้';

  @override
  String get communityImpact => 'ผลกระทบต่อชุมชน';

  @override
  String get communityImpactDescription =>
      'การมีส่วนร่วมของคุณช่วยให้:\n• ข้อมูลกล้องจับความเร็วมีความแม่นยำ\n• ชุมชนมีข้อมูลที่ทันสมัย\n• การขับขี่ปลอดภัยยิ่งขึ้น';

  @override
  String get leaderboardAndRewards => 'อันดับผู้มีส่วนร่วม และรางวัลพิเศษ';

  @override
  String get loginThroughMapProfileRequired =>
      'กรุณาล็อกอินผ่านหน้าแผนที่ก่อนโหวต';

  @override
  String get reportSubmissionSuccess =>
      'ส่งรายงานเรียบร้อยแล้ว! ตรวจสอบในแท็บโหวต';

  @override
  String errorOccurred(String error) {
    return 'เกิดข้อผิดพลาด: $error';
  }

  @override
  String get showPostsFromNationwide => 'แสดงโพสต์จากทั่วประเทศ';

  @override
  String get showNearbyPosts => 'แสดงโพสต์ใกล้เคียง';

  @override
  String radiusAllPosts(int radius, int count) {
    return 'รัศมี: $radius กม. • โพสต์ทั้งหมด: $count';
  }

  @override
  String radiusNearbyPosts(int radius, int count) {
    return 'รัศมี: $radius กม. • โพสต์ใกล้เคียง: $count';
  }

  @override
  String get pleaseLoginThroughMapProfile =>
      'กรุณาล็อกอินผ่านโปรไฟล์ในหน้าแผนที่';

  @override
  String get tapProfileButtonInMap => 'แตะที่ปุ่มโปรไฟล์มุมขวาบนของแผนที่';

  @override
  String get voteExistsSuccess => 'โหวต \"มีจริง\" เรียบร้อยแล้ว';

  @override
  String get voteNotExistsSuccess => 'โหวต \"ไม่มี\" เรียบร้อยแล้ว';

  @override
  String get cameraReportFormTitle => 'รายงานกล้องจับความเร็ว';

  @override
  String get reportTypeLabel => 'ประเภทการรายงาน';

  @override
  String get newCameraLocationLabel => 'ตำแหน่งกล้องใหม่';

  @override
  String get selectNewCameraLocation => 'เลือกตำแหน่งกล้องใหม่';

  @override
  String get selectLocationOnMap => 'กรุณาเลือกตำแหน่งบนแผนที่';

  @override
  String get roadNameLabel => 'ชื่อถนน';

  @override
  String get pleaseEnterRoadName => 'กรุณากรอกชื่อถนน';

  @override
  String get speedLimitLabel => 'จำกัดความเร็ว (km/h)';

  @override
  String get newSpeedLimitLabel => 'จำกัดความเร็วใหม่ (km/h)';

  @override
  String get additionalDetailsLabel => 'รายละเอียดเพิ่มเติม';

  @override
  String get selectExistingCameraLabel => 'เลือกกล้องที่มีอยู่ในระบบ';

  @override
  String get selectedLocationLabel => 'ตำแหน่งที่เลือก';

  @override
  String get tapToSelectLocationOnMap => 'แตะเพื่อเลือกตำแหน่งบนแผนที่';

  @override
  String get locationDetailsLabel => 'รายละเอียดที่ตั้งและจุดสังเกต';

  @override
  String get pleaseProvideLocationDetails =>
      'กรุณาระบุรายละเอียดที่ตั้งและจุดสังเกต';

  @override
  String get pleaseProvideAtLeast10Characters =>
      'กรุณาระบุรายละเอียดอย่างน้อย 10 ตัวอักษร';

  @override
  String get reportNewCamera => 'เพิ่มกล้องใหม่';

  @override
  String get reportRemovedCamera => 'กล้องที่ถูกถอน';

  @override
  String get reportSpeedChanged => 'เปลี่ยนจำกัดความเร็ว';

  @override
  String get noLocationDataFound => 'ไม่พบข้อมูลสถานที่';

  @override
  String get loginRequiredToViewStats => 'จำเป็นต้องล็อกอินเพื่อดูสถิติ';

  @override
  String get securityCheckFailed => 'การตรวจสอบความปลอดภัยล้มเหลว';

  @override
  String get pleaseLoginBeforeVoting => 'กรุณาล็อกอินผ่านหน้าแผนที่ก่อนโหวต';

  @override
  String get alreadyVotedDetected =>
      'โหวตเรียบร้อยแล้ว!\n(ระบบตรวจสอบว่าคุณได้โหวตแล้ว)';

  @override
  String get noVotingPermission =>
      'ไม่มีสิทธิ์ในการโหวต\nลองออกจากระบบและล็อกอินใหม่';

  @override
  String get engagementScore => 'คะแนนการมีส่วนร่วม';

  @override
  String get totalEngagement => 'การมีส่วนร่วมทั้งหมด';

  @override
  String get voteFor => 'โหวตให้';

  @override
  String get loadingCameraData => 'กำลังโหลดข้อมูลกล้อง...';

  @override
  String get noCameraDataFound => 'ไม่พบข้อมูลกล้องในระบบ';

  @override
  String get selectedCamera => 'กล้องที่เลือก';

  @override
  String get tapToSelectCameraFromMap => 'แตะเพื่อเลือกกล้องจากแผนที่';

  @override
  String get pleaseSelectCameraFromMap => 'กรุณาเลือกกล้องจากแผนที่';

  @override
  String oldSpeedToNewSpeed(int oldSpeed, int newSpeed) {
    return 'ความเร็วเดิม: $oldSpeed km/h → ใหม่: $newSpeed km/h';
  }

  @override
  String get locationExampleHint =>
      'เช่น ใกล้ห้าแยกโรบินสัน, หน้าโรงเรียน, ตรงข้ามปั๊มน้ำมัน, บริเวณสะพาน';

  @override
  String get pleaseLoginBeforeReportingCamera => 'กรุณาล็อกอินก่อนรายงานกล้อง';

  @override
  String coordinatesFormat(String lat, String lng) {
    return 'ละติจูด: $lat, ลองจิจูด: $lng';
  }

  @override
  String get selectCamera => 'เลือกกล้อง';

  @override
  String get cannotFindCurrentLocationEnableGPS =>
      'ไม่สามารถหาตำแหน่งปัจจุบันได้ กรุณาเปิด GPS';

  @override
  String get select => 'เลือก';

  @override
  String speedLimitFormat(int limit) {
    return 'จำกัดความเร็ว: $limit km/h';
  }

  @override
  String get confirmSelection => 'ยืนยันการเลือก';

  @override
  String get tapCameraIconOnMapToSelect => 'แตะที่ไอคอนกล้องบนแผนที่เพื่อเลือก';

  @override
  String get cameraNotFoundInSystem => 'ไม่พบข้อมูลกล้องในระบบ';

  @override
  String get errorLoadingData => 'เกิดข้อผิดพลาดในการโหลดข้อมูล';

  @override
  String get selectCameraFromMap => 'เลือกกล้องจากแผนที่';

  @override
  String get searchingCurrentLocation => 'กำลังหาตำแหน่งปัจจุบัน...';

  @override
  String get foundCurrentLocation => 'พบตำแหน่งปัจจุบันแล้ว';

  @override
  String get cannotFindLocationUseMap =>
      'ไม่สามารถหาตำแหน่งได้ ใช้แผนที่ค้นหากล้องแทน';

  @override
  String get pleaseAllowLocationAccess =>
      'กรุณาอนุญาตการเข้าถึงตำแหน่งในการตั้งค่าแอป';

  @override
  String get showingBangkokMapNormalSearch =>
      'แสดงแผนที่กรุงเทพฯ (ค้นหากล้องได้ปกติ)';

  @override
  String get selectedCameraInfo => 'กล้องที่เลือก';

  @override
  String cameraCode(String code) {
    return 'รหัส: $code';
  }

  @override
  String speedAndType(int speed, String type) {
    return 'ความเร็ว: $speed km/h • $type';
  }

  @override
  String camerasCount(int count) {
    return '$count กล้อง';
  }

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get myReport => 'รายงานของฉัน';

  @override
  String get communityMember => 'สมาชิกในชุมชน';

  @override
  String get deleteReport => 'ลบรายงาน';

  @override
  String speedLimitDisplay(int speed) {
    return 'จำกัดความเร็ว: $speed km/h';
  }

  @override
  String get viewMapButton => 'ดูแผนที่';

  @override
  String get viewCameraOnMap => 'ดูกล้องในแผนที่';

  @override
  String viewLocationTitle(String roadName) {
    return 'ดูตำแหน่ง: $roadName';
  }

  @override
  String get win => 'ชนะ';

  @override
  String get tied => 'เสมอ 3-3';

  @override
  String needsMoreVotes(int count) {
    return 'ต้องการ $count โหวต';
  }

  @override
  String get exists => 'มีจริง';

  @override
  String get trueVote => 'จริง';

  @override
  String get doesNotExist => 'ไม่มี';

  @override
  String get falseVote => 'ไม่จริง';

  @override
  String get confirmDeletion => 'ยืนยันการลบ';

  @override
  String get deleteConfirmMessage =>
      'คุณต้องการลบรายงานนี้ใช่หรือไม่?\n\nเมื่อลบแล้วจะไม่สามารถกู้คืนได้';

  @override
  String get delete => 'ลบ';

  @override
  String get deletingReport => 'กำลังลบรายงาน...';

  @override
  String get reportDeletedSuccess =>
      'ลบรายงานเรียบร้อยแล้ว 🎉 กำลังอัปเดตหน้าจอ...';

  @override
  String get deleteTimeoutError => 'การลบใช้เวลานานเกินไป กรุณาลองใหม่';

  @override
  String get newCameraType => '📷 กล้องใหม่';

  @override
  String get removedCameraType => '❌ กล้องถูกถอด';

  @override
  String get speedChangedType => '⚡ เปลี่ยนความเร็ว';

  @override
  String get yourReportPending => 'รายงานของคุณ - รอโหวต';

  @override
  String get alreadyVotedStatus => 'คุณได้โหวตแล้ว';

  @override
  String get pendingReview => 'รอการตรวจสอบ';

  @override
  String get verified => 'ยืนยันแล้ว';

  @override
  String get rejected => 'ถูกปฏิเสธ';

  @override
  String get duplicate => 'ข้อมูลซ้ำ';

  @override
  String get justNow => 'เมื่อสักครู่';

  @override
  String minutesAgo(int minutes) {
    return '$minutes นาทีที่แล้ว';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours ชั่วโมงที่แล้ว';
  }

  @override
  String daysAgo(int days) {
    return '$days วันที่แล้ว';
  }

  @override
  String get locationAccessDenied => 'ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง';

  @override
  String get enableLocationInSettings => 'กรุณาเปิดอนุญาตตำแหน่งในการตั้งค่า';

  @override
  String get speedCameraTitle => 'กล้องจับความเร็ว';

  @override
  String get soundSettingsTooltip => 'ตั้งค่าเสียงแจ้งเตือน';

  @override
  String get loadingDataText => 'กำลังโหลดข้อมูล...';

  @override
  String get cannotDetermineLocation => 'ไม่สามารถระบุตำแหน่งได้';

  @override
  String get cannotLoadSpeedCameraData =>
      'ไม่สามารถโหลดข้อมูลกล้องจับความเร็วได้';

  @override
  String get speedLimitText => 'จำกัด';

  @override
  String predictedCameraAlert(String roadName, int speedLimit) {
    return 'คาดการณ์ จะพบกล้องจับความเร็วใน 10 วินาที บน $roadName จำกัด $speedLimit กิโลเมตรต่อชั่วโมง';
  }

  @override
  String get nearCameraReduceSpeed => 'อยู่ใกล้กล้องจับความเร็ว โปรดลดความเร็ว';

  @override
  String get nearCameraGoodSpeed => 'อยู่ใกล้กล้องจับความเร็ว ความเร็วเหมาะสม';

  @override
  String cameraAheadDistance(int distance, int speedLimit) {
    return 'กล้องจับความเร็วข้างหน้า $distance เมตร จำกัด $speedLimit กิโลเมตรต่อชั่วโมง';
  }

  @override
  String get speedCameraBadgeTitle => 'กล้องจับความเร็ว';

  @override
  String get badgeUpdatingCameraData => 'กำลังอัปเดตข้อมูลกล้อง...';

  @override
  String badgeFoundNewCameras(int count) {
    return '🎉 พบกล้องใหม่ $count จุด ที่ชุมชนยืนยัน!';
  }

  @override
  String get badgeCameraDataUpdated => '✅ ข้อมูลกล้องอัปเดตเรียบร้อย';

  @override
  String get badgeCannotUpdateData => '⚠️ ไม่สามารถอัปเดตข้อมูลได้';

  @override
  String get badgeSecurityAnomalyDetected => '🔒 ระบบตรวจพบการใช้งานผิดปกติ';

  @override
  String get badgeSystemBackToNormal => '✅ ระบบกลับสู่การทำงานปกติ';

  @override
  String get badgePredictedCameraAhead => '🔮 จะพบกล้องใน 10 วินาที';

  @override
  String get badgeNearCameraReduceSpeed => '⚠️ อยู่ใกล้กล้อง โปรดลดความเร็ว';

  @override
  String get badgeNearCameraGoodSpeed => '✅ อยู่ใกล้กล้อง ความเร็วเหมาะสม';

  @override
  String badgeExceedingSpeed(int excessSpeed) {
    return '🚨 เร็วเกิน $excessSpeed km/h';
  }

  @override
  String badgeCameraAhead(int distance) {
    return '📍 กล้องข้างหน้า ${distance}m';
  }

  @override
  String badgeRadarDetection(int distance) {
    return '🔊 เรดาร์กล้อง ${distance}m';
  }

  @override
  String get soundTypeNone => 'ปิดเสียง';

  @override
  String get soundTypeBeep => 'เสียงบี๊บจริง (ไม่แนะนำ)';

  @override
  String get soundTypeWarning => 'เสียงเตือนภัยจริง (ไม่แนะนำ)';

  @override
  String get soundTypeTts => 'เสียงพูดภาษาไทย';

  @override
  String ttsDistanceKilometer(String distance) {
    return '$distance กิโลเมตร';
  }

  @override
  String ttsDistanceMeter(int distance) {
    return '$distance เมตร';
  }

  @override
  String ttsCameraDistance(String distance) {
    return 'กล้องจับความเร็วอยู่ห่างจากคุณ $distance';
  }

  @override
  String ttsEnteringRoadSpeed(String roadName, int speedLimit) {
    return 'กำลังเข้าสู่ $roadName จำกัดความเร็ว $speedLimit กิโลเมตรต่อชั่วโมง';
  }

  @override
  String get ttsBeep => 'บี๊บ';

  @override
  String get ttsWarning => 'เตือนภัย';

  @override
  String get ttsTestVoice => 'ทดสอบเสียงภาษาไทย';

  @override
  String get ttsCameraExample =>
      'กล้องจับความเร็วข้างหน้า จำกัดความเร็ว 90 กิโลเมตรต่อชั่วโมง';

  @override
  String get noMessage => 'ไม่มีข้อความ';

  @override
  String get other => 'อื่นๆ';

  @override
  String get report => 'รายงาน';

  @override
  String get error => 'เกิดข้อผิดพลาด';

  @override
  String errorWithDetails(String error) {
    return 'เกิดข้อผิดพลาด: $error';
  }

  @override
  String categoryCount(int count) {
    return 'ประเภท ($count)';
  }

  @override
  String get urgent => 'แจ้งด่วน';

  @override
  String get listing => 'รายการ';

  @override
  String get locationPermissionDenied => 'ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง';

  @override
  String get enableLocationPermission => 'กรุณาเปิดอนุญาตตำแหน่งในการตั้งค่า';

  @override
  String get cannotDetermineCurrentLocation =>
      'ไม่สามารถระบุตำแหน่งปัจจุบันได้';

  @override
  String get coordinateValidationError =>
      'พิกัดไม่ถูกต้อง: Latitude (-90 ถึง 90), Longitude (-180 ถึง 180)';

  @override
  String get invalidCoordinates => 'รูปแบบพิกัดไม่ถูกต้อง';

  @override
  String cameraLocation(String roadName) {
    return 'ตำแหน่งกล้อง - $roadName';
  }

  @override
  String get closeButton => 'ปิด';

  @override
  String get manualCoordinates => 'ป้อนพิกัดโดยตรง';

  @override
  String get tapMapToSelect => 'หรือแตะบนแผนที่เพื่อเลือกตำแหน่ง';

  @override
  String get roadNameFieldLabel => 'ชื่อถนน';

  @override
  String get roadNameHintText => 'ชื่อถนนจะแสดงอัตโนมัติ หรือพิมพ์เอง';

  @override
  String get selectedLocationText => 'ตำแหน่งที่เลือก:';

  @override
  String get cameraLocationText => 'ตำแหน่งกล้อง:';

  @override
  String speedLimitInfo(int speedLimit) {
    return 'จำกัดความเร็ว: $speedLimit km/h';
  }

  @override
  String get noDetails => 'ไม่มีรายละเอียด';

  @override
  String get noLocation => 'ไม่ระบุตำแหน่ง';

  @override
  String get details => 'รายละเอียด';

  @override
  String get location => 'สถานที่';

  @override
  String get coordinatesLabel => 'พิกัด';

  @override
  String get closeDialog => 'ปิด';

  @override
  String get removedDetailPage => 'หน้ารายละเอียดถูกลบออกแล้ว';

  @override
  String get viewDetails => 'ดูรายละเอียด';

  @override
  String get saveSettingsSuccess => '✅ บันทึกการตั้งค่าเรียบร้อย';

  @override
  String saveSettingsError(String error) {
    return '❌ เกิดข้อผิดพลาด: $error';
  }

  @override
  String get testingNotification => '🔔 กำลังทดสอบการแจ้งเตือน...';

  @override
  String get testNotificationSent => '✅ ส่งการแจ้งเตือนทดสอบแล้ว';

  @override
  String testNotificationError(String error) {
    return '❌ เกิดข้อผิดพลาดในการทดสอบ: $error';
  }

  @override
  String get notificationTitle => 'การแจ้งเตือน';

  @override
  String get saveSettingsTooltip => 'บันทึกการตั้งค่า';

  @override
  String get mainSettingsTitle => '⚙️ การตั้งค่าหลัก';

  @override
  String get enableNotificationTitle => 'เปิดการแจ้งเตือน';

  @override
  String get enableNotificationSubtitle => 'รับการแจ้งเตือนจากแอป CheckDarn';

  @override
  String get notificationTypesTitle => '🔔 ประเภทการแจ้งเตือน';

  @override
  String get newEventsTitle => 'เหตุการณ์ใหม่';

  @override
  String get newEventsSubtitle =>
      'แจ้งเตือนเมื่อมีเหตุการณ์ใหม่ในบริเวณใกล้คุณ';

  @override
  String get commentsSubtitle =>
      'แจ้งเตือนเมื่อมีคนแสดงความคิดเห็นในโพสต์ของคุณ';

  @override
  String get systemTitle => 'ระบบ';

  @override
  String get systemSubtitle => 'แจ้งเตือนจากระบบและการอัปเดต';

  @override
  String get statusTitle => '📊 สถานะ';

  @override
  String get userTitle => 'ผู้ใช้';

  @override
  String get deviceTitle => 'อุปกรณ์';

  @override
  String get deviceConnected => 'เชื่อมต่อแล้ว';

  @override
  String get notificationDisabled => 'ปิดการแจ้งเตือน';

  @override
  String get testTitle => '🧪 ทดสอบ';

  @override
  String get testNotification => 'ทดสอบการแจ้งเตือน';

  @override
  String get tipsTitle => '💡 คำแนะนำ';

  @override
  String get privacySettingTitle => 'ความเป็นส่วนตัว';

  @override
  String get privacySettingSubtitle =>
      'เราจะไม่แจ้งเตือนให้คุณเมื่อคุณโพสต์เอง';

  @override
  String get batterySavingTitle => 'ประหยัดแบตเตอรี่';

  @override
  String get batterySavingSubtitle =>
      'ปิดการแจ้งเตือนที่ไม่จำเป็นเพื่อประหยัดแบตเตอรี่';

  @override
  String get loginProcessStarted => '🚀 เริ่มกระบวนการล็อกอิน...';

  @override
  String loginSuccessWelcome(String name) {
    return 'เข้าสู่ระบบสำเร็จ! ยินดีต้อนรับ $name';
  }

  @override
  String loginFailed(String error) {
    return 'ล็อกอินไม่สำเร็จ: $error';
  }

  @override
  String get platformDescription => 'แพลตฟอร์มรายงานเหตุการณ์\nในชุมชนของคุณ';

  @override
  String get signingIn => 'กำลังเข้าสู่ระบบ...';

  @override
  String get signInWithGoogle => 'เข้าสู่ระบบด้วย Google';

  @override
  String get skipForNow => 'ข้ามไปก่อน';

  @override
  String get loginBenefit =>
      'การเข้าสู่ระบบจะช่วยให้คุณสามารถ\nรายงานเหตุการณ์และแสดงความคิดเห็นได้';

  @override
  String get welcome => 'ยินดีต้อนรับ';

  @override
  String get appSlogan => '\"รู้ก่อน รอดก่อน ปลอดภัยก่อน\"';

  @override
  String get appVersion => 'เวอร์ชัน 1.0';

  @override
  String get readyToTest => 'พร้อมทดสอบ';

  @override
  String get alreadyLoggedIn => 'ล็อกอินแล้ว';

  @override
  String get notLoggedIn => 'ยังไม่ล็อกอิน';

  @override
  String get testingLogin => 'กำลังทดสอบล็อกอิน...';

  @override
  String get startLoginTest => '🧪 เริ่มทดสอบการล็อกอิน...';

  @override
  String loginSuccessEmail(String email) {
    return 'ล็อกอินสำเร็จ: $email';
  }

  @override
  String loginSuccessName(String name) {
    return 'ล็อกอินสำเร็จ: $name';
  }

  @override
  String get userCancelledLogin => 'ผู้ใช้ยกเลิกการล็อกอิน';

  @override
  String loginTestFailed(String error) {
    return '❌ ทดสอบล็อกอินล้มเหลว: $error';
  }

  @override
  String loginFailedGeneral(String error) {
    return 'ล็อกอินล้มเหลว: $error';
  }

  @override
  String get loggedOut => 'ออกจากระบบแล้ว';

  @override
  String get logoutSuccess => 'ออกจากระบบสำเร็จ';

  @override
  String logoutFailedError(String error) {
    return 'ออกจากระบบล้มเหลว: $error';
  }

  @override
  String get loginTestTitle => 'ทดสอบการล็อกอิน';

  @override
  String get loginStatusTitle => 'สถานะการล็อกอิน';

  @override
  String get userDataTitle => 'ข้อมูลผู้ใช้';

  @override
  String get testingTitle => 'การทดสอบ';

  @override
  String get testing => 'กำลังทดสอบ...';

  @override
  String get testLogin => 'ทดสอบการล็อกอิน';

  @override
  String get logoutButton => 'ออกจากระบบ';

  @override
  String get notesTitle => 'หมายเหตุ:';

  @override
  String get debugConsole => '• ดู Console/Log เพื่อรายละเอียดการ debug';

  @override
  String get checkGoogleServices =>
      '• ตรวจสอบ Google Services และ Firebase Console';

  @override
  String get checkSHA1 => '• ตรวจสอบ SHA-1 fingerprint ใน Firebase';

  @override
  String get testOnDevice => '• ทดสอบบนอุปกรณ์จริง ไม่ใช่ Emulator';

  @override
  String get simpleTestReady => 'พร้อมทดสอบ';

  @override
  String get simpleTesting => 'กำลังทดสอบ...';

  @override
  String get simpleTestStart => '🧪 === เริ่มทดสอบการล็อกอิน ===';

  @override
  String authServiceInitialized(bool status) {
    return 'เริ่มต้น AuthService แล้ว\nสถานะล็อกอิน: $status';
  }

  @override
  String categoryWithCount(int count) {
    return 'ประเภท ($count)';
  }

  @override
  String get urgentReport => 'แจ้งด่วน';

  @override
  String get listView => 'รายการ';

  @override
  String get postStatisticsTitle => '📊 สถิติโพสต์';

  @override
  String totalPostsWithEmoji(int count) {
    return '📄 โพสต์ทั้งหมด: $count รายการ';
  }

  @override
  String freshPostsWithEmoji(int count) {
    return '✨ โพสต์สดใหม่ (24 ชม.): $count รายการ';
  }

  @override
  String oldPostsWithEmoji(int count) {
    return '🗑️ โพสต์เก่า: $count รายการ';
  }

  @override
  String get autoDeleteInfo =>
      '💡 โพสต์จะถูกลบอัตโนมัติหลัง 24 ชั่วโมง\nเพื่อรักษาความสดใหม่ของข้อมูล';

  @override
  String get cleanupOldPosts => '🧹 ลบโพสต์เก่าตอนนี้';

  @override
  String get cleaningPosts => '🧹 กำลังลบโพสต์เก่า...';

  @override
  String cleanupComplete(int count) {
    return '✅ ลบเสร็จแล้ว! เหลือโพสต์สดใหม่ $count รายการ';
  }

  @override
  String cleanupError(String error) {
    return 'เกิดข้อผิดพลาดในการลบ: $error';
  }

  @override
  String get postStatisticsTooltip => 'ดูสถิติโพสต์';

  @override
  String loadingDataError(String error) {
    return 'เกิดข้อผิดพลาด: $error';
  }

  @override
  String get loadingText => 'กำลังโหลดข้อมูล...';

  @override
  String get noReportsTitle => 'ยังไม่มีรายการแจ้งเหตุ';

  @override
  String get startReporting => 'เริ่มต้นด้วยการแจ้งเหตุครั้งแรกของคุณ';

  @override
  String get reportListTitle => 'รายการแจ้งเหตุ';

  @override
  String get unspecifiedLocation => 'ไม่ระบุสถานที่';

  @override
  String get showComments => 'แสดงความคิดเห็น';

  @override
  String eventsInAreaFull(int count) {
    return 'เหตุการณ์ในบริเวณนี้ ($count รายการ)';
  }

  @override
  String get unspecifiedUser => 'ไม่ระบุชื่อ';

  @override
  String get unknownUser => 'ผู้ใช้ไม่ระบุชื่อ';

  @override
  String get maskedUserFallback => 'ผู้ใช้ไม่ระบุชื่อ';

  @override
  String loginSuccessWithName(String name) {
    return 'ล็อกอินสำเร็จ! ยินดีต้อนรับ $name';
  }

  @override
  String loginError(String error) {
    return 'เกิดข้อผิดพลาดในการล็อกอิน: $error';
  }

  @override
  String get logoutSuccessful => 'ล็อกเอาต์เรียบร้อยแล้ว';

  @override
  String logoutError(String error) {
    return 'เกิดข้อผิดพลาดในการล็อกเอาต์: $error';
  }

  @override
  String get loginThroughMapRequired => 'กรุณาล็อกอินผ่านโปรไฟล์ในหน้าแผนที่';

  @override
  String get fallbackOther => 'อื่นๆ';

  @override
  String get developmentOnly => '(Dev Only)';

  @override
  String get user => 'ผู้ใช้';

  @override
  String get defaultUser => 'ผู้ใช้';

  @override
  String get anonymous => 'ไม่ระบุชื่อ';

  @override
  String get roadNamePlaceholder => 'ชื่อถนน';

  @override
  String get eventLocationLabel => 'ตำแหน่งเหตุการณ์';

  @override
  String get unspecified => 'ไม่ระบุ';

  @override
  String get securityTimeout => 'ตรวจสอบสิทธิ์เกินเวลา';

  @override
  String get locationRequest => '📍 กำลังขอตำแหน่งปัจจุบัน...';

  @override
  String locationReceived(String location) {
    return '✅ ได้ตำแหน่ง: $location';
  }

  @override
  String get cannotGetLocationManual =>
      'ไม่สามารถระบุตำแหน่งได้ กรุณาเลือกตำแหน่งด้วยตนเอง';

  @override
  String get reportTimeoutWarning =>
      'การส่งรายงานเกินเวลา กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';

  @override
  String get reportSuccessTitle => 'สำเร็จ';

  @override
  String get reportTimeoutError =>
      'ส่งรายงานไม่สำเร็จ: เกินเวลารอคอย กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
}
