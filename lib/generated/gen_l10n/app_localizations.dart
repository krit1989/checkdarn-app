import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th')
  ];

  /// No description provided for @searchingPostsInArea.
  ///
  /// In en, this message translates to:
  /// **'Searching for posts in this area...'**
  String get searchingPostsInArea;

  /// No description provided for @movedToViewPosts.
  ///
  /// In en, this message translates to:
  /// **'Moved to view posts in area: {locationName}'**
  String movedToViewPosts(String locationName);

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get selectedLocation;

  /// No description provided for @cannotLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Cannot load image'**
  String get cannotLoadImage;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noTitle.
  ///
  /// In en, this message translates to:
  /// **'No title'**
  String get noTitle;

  /// No description provided for @anonymousUser.
  ///
  /// In en, this message translates to:
  /// **'Anonymous user'**
  String get anonymousUser;

  /// No description provided for @myLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back to my real location'**
  String get myLocationTooltip;

  /// No description provided for @eventsInArea.
  ///
  /// In en, this message translates to:
  /// **'Events in this area ({count} items)'**
  String eventsInArea(int count);

  /// No description provided for @kilometerShort.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kilometerShort;

  /// No description provided for @cannotGetLocationInfo.
  ///
  /// In en, this message translates to:
  /// **'Cannot retrieve location information: {error}'**
  String cannotGetLocationInfo(String error);

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get unknownLocation;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @cannotLoadData.
  ///
  /// In en, this message translates to:
  /// **'Cannot load data: {error}'**
  String cannotLoadData(String error);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get category;

  /// No description provided for @reportWhat.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportWhat;

  /// No description provided for @nearMe.
  ///
  /// In en, this message translates to:
  /// **'Near Me'**
  String get nearMe;

  /// No description provided for @speedCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get speedCamera;

  /// No description provided for @emergencyNumbers.
  ///
  /// In en, this message translates to:
  /// **'Emergency Numbers'**
  String get emergencyNumbers;

  /// No description provided for @police.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get police;

  /// No description provided for @traffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get traffic;

  /// No description provided for @highway.
  ///
  /// In en, this message translates to:
  /// **'Highway Department'**
  String get highway;

  /// No description provided for @ruralRoad.
  ///
  /// In en, this message translates to:
  /// **'Rural Road'**
  String get ruralRoad;

  /// No description provided for @fireDepartment.
  ///
  /// In en, this message translates to:
  /// **'Fire Department'**
  String get fireDepartment;

  /// No description provided for @emergencyMedical.
  ///
  /// In en, this message translates to:
  /// **'Emergency Medical Services (EMS)'**
  String get emergencyMedical;

  /// No description provided for @erawanCenter.
  ///
  /// In en, this message translates to:
  /// **'Erawan Center (Bangkok)'**
  String get erawanCenter;

  /// No description provided for @disasterAlert.
  ///
  /// In en, this message translates to:
  /// **'Disaster Alert'**
  String get disasterAlert;

  /// No description provided for @bombThreatTerrorism.
  ///
  /// In en, this message translates to:
  /// **'Bomb Threat / Terrorism'**
  String get bombThreatTerrorism;

  /// No description provided for @diseaseControl.
  ///
  /// In en, this message translates to:
  /// **'Disease Control Center'**
  String get diseaseControl;

  /// No description provided for @disasterPrevention.
  ///
  /// In en, this message translates to:
  /// **'Disaster Prevention and Mitigation (DDPM)'**
  String get disasterPrevention;

  /// No description provided for @ruamkatanyu.
  ///
  /// In en, this message translates to:
  /// **'Ruamkatanyu Foundation'**
  String get ruamkatanyu;

  /// No description provided for @pohtecktung.
  ///
  /// In en, this message translates to:
  /// **'Poh Teck Tung Foundation'**
  String get pohtecktung;

  /// No description provided for @cyberCrimeHotline.
  ///
  /// In en, this message translates to:
  /// **'Cyber Crime Hotline'**
  String get cyberCrimeHotline;

  /// No description provided for @consumerProtection.
  ///
  /// In en, this message translates to:
  /// **'Office of Consumer Protection Board (OCPB)'**
  String get consumerProtection;

  /// No description provided for @js100.
  ///
  /// In en, this message translates to:
  /// **'JS.100'**
  String get js100;

  /// No description provided for @touristPolice.
  ///
  /// In en, this message translates to:
  /// **'Tourist Police'**
  String get touristPolice;

  /// No description provided for @tourismAuthority.
  ///
  /// In en, this message translates to:
  /// **'Tourism Authority of Thailand (TAT)'**
  String get tourismAuthority;

  /// No description provided for @harborDepartment.
  ///
  /// In en, this message translates to:
  /// **'Harbor Department'**
  String get harborDepartment;

  /// No description provided for @waterAccident.
  ///
  /// In en, this message translates to:
  /// **'Water Accident'**
  String get waterAccident;

  /// No description provided for @expressway.
  ///
  /// In en, this message translates to:
  /// **'Expressway Authority of Thailand'**
  String get expressway;

  /// No description provided for @transportCooperative.
  ///
  /// In en, this message translates to:
  /// **'Transport Cooperative'**
  String get transportCooperative;

  /// No description provided for @busVan.
  ///
  /// In en, this message translates to:
  /// **'Bus / Van'**
  String get busVan;

  /// No description provided for @taxiGrab.
  ///
  /// In en, this message translates to:
  /// **'Taxi / Grab'**
  String get taxiGrab;

  /// No description provided for @meaElectricity.
  ///
  /// In en, this message translates to:
  /// **'Metropolitan Electricity Authority (MEA)'**
  String get meaElectricity;

  /// No description provided for @peaElectricity.
  ///
  /// In en, this message translates to:
  /// **'Provincial Electricity Authority (PEA)'**
  String get peaElectricity;

  /// No description provided for @cannotCallPhone.
  ///
  /// In en, this message translates to:
  /// **'Cannot call {phoneNumber}\nPlease check if device supports phone calls'**
  String cannotCallPhone(String phoneNumber);

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @selectedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total} items'**
  String selectedOfTotal(int selected, int total);

  /// No description provided for @categoryCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Checkpoint'**
  String get categoryCheckpoint;

  /// No description provided for @categoryAccident.
  ///
  /// In en, this message translates to:
  /// **'Accident'**
  String get categoryAccident;

  /// No description provided for @categoryFire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get categoryFire;

  /// No description provided for @categoryFloodRain.
  ///
  /// In en, this message translates to:
  /// **'Rain/Flood'**
  String get categoryFloodRain;

  /// No description provided for @categoryTsunami.
  ///
  /// In en, this message translates to:
  /// **'Tsunami'**
  String get categoryTsunami;

  /// No description provided for @categoryEarthquake.
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get categoryEarthquake;

  /// No description provided for @categoryAnimalLost.
  ///
  /// In en, this message translates to:
  /// **'Lost Animal'**
  String get categoryAnimalLost;

  /// No description provided for @categoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'General Question'**
  String get categoryQuestion;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @speedCameraSoundAlert.
  ///
  /// In en, this message translates to:
  /// **'Speed Camera Sound Alert'**
  String get speedCameraSoundAlert;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @enableNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Notify when new events occur'**
  String get enableNotificationsDesc;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @thaiVoice.
  ///
  /// In en, this message translates to:
  /// **'Thai Voice'**
  String get thaiVoice;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @thai.
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get thai;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @currentlySelected.
  ///
  /// In en, this message translates to:
  /// **'Currently Selected'**
  String get currentlySelected;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon!'**
  String get comingSoon;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @shareAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Share app with friends'**
  String get shareAppDesc;

  /// No description provided for @reviewApp.
  ///
  /// In en, this message translates to:
  /// **'Review App'**
  String get reviewApp;

  /// No description provided for @reviewAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Rate app on App Store'**
  String get reviewAppDesc;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @sendFeedbackOrReport.
  ///
  /// In en, this message translates to:
  /// **'Send feedback or report issues'**
  String get sendFeedbackOrReport;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @openEmailApp.
  ///
  /// In en, this message translates to:
  /// **'Open email app'**
  String get openEmailApp;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report Problem'**
  String get reportProblem;

  /// No description provided for @reportProblemDesc.
  ///
  /// In en, this message translates to:
  /// **'Report usage issues'**
  String get reportProblemDesc;

  /// No description provided for @reportFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Report feature coming soon!'**
  String get reportFeatureComingSoon;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to logout?'**
  String get logoutMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @securityValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'Security validation failed'**
  String get securityValidationFailed;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logoutFailed;

  /// No description provided for @welcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get welcomeTo;

  /// No description provided for @termsOfServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceTitle;

  /// No description provided for @termsOfServiceHeader.
  ///
  /// In en, this message translates to:
  /// **'📋 CheckDarn Terms of Service'**
  String get termsOfServiceHeader;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated: August 8, 2025'**
  String get lastUpdated;

  /// No description provided for @acceptanceOfTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get acceptanceOfTermsTitle;

  /// No description provided for @acceptanceOfTermsContent.
  ///
  /// In en, this message translates to:
  /// **'By using the CheckDarn application, you agree to accept and comply with all terms of service. If you do not accept these terms, please stop using the application immediately.'**
  String get acceptanceOfTermsContent;

  /// No description provided for @purposeOfUseTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Purpose of Use'**
  String get purposeOfUseTitle;

  /// No description provided for @purposeOfUseContent.
  ///
  /// In en, this message translates to:
  /// **'CheckDarn is an application for reporting and alerting various events in the area, such as traffic, accidents, or other important events to help the community receive useful information.'**
  String get purposeOfUseContent;

  /// No description provided for @appropriateUseTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Appropriate Use'**
  String get appropriateUseTitle;

  /// No description provided for @appropriateUseContent.
  ///
  /// In en, this message translates to:
  /// **'Users must use the application responsibly. Do not post false, offensive, or illegal information. Reported information should be factual and beneficial to the community.'**
  String get appropriateUseContent;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyContent.
  ///
  /// In en, this message translates to:
  /// **'We value user privacy. Personal data will be kept secure and used only for service development and improvement purposes.'**
  String get privacyContent;

  /// No description provided for @responsibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'5. Responsibility'**
  String get responsibilityTitle;

  /// No description provided for @responsibilityContent.
  ///
  /// In en, this message translates to:
  /// **'Application developers are not responsible for any damages arising from the use of the application. Users must use their judgment when making decisions based on received information.'**
  String get responsibilityContent;

  /// No description provided for @modificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'6. Terms Modifications'**
  String get modificationsTitle;

  /// No description provided for @modificationsContent.
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to modify the terms of service at any time. Modifications will take effect immediately after being announced in the application.'**
  String get modificationsContent;

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'7. Contact'**
  String get contactTitle;

  /// No description provided for @contactContent.
  ///
  /// In en, this message translates to:
  /// **'If you have questions or need to contact regarding the terms of service, you can contact through the application or designated channels.'**
  String get contactContent;

  /// No description provided for @thankYouForUsing.
  ///
  /// In en, this message translates to:
  /// **'✅ Thank you for using CheckDarn'**
  String get thankYouForUsing;

  /// No description provided for @communityMessage.
  ///
  /// In en, this message translates to:
  /// **'Together building a safe community with good information'**
  String get communityMessage;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicyHeader.
  ///
  /// In en, this message translates to:
  /// **'🔒 CheckDarn Privacy Policy'**
  String get privacyPolicyHeader;

  /// No description provided for @effectiveFrom.
  ///
  /// In en, this message translates to:
  /// **'Effective from: August 8, 2025'**
  String get effectiveFrom;

  /// No description provided for @dataCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Data We Collect'**
  String get dataCollectionTitle;

  /// No description provided for @dataCollectionContent.
  ///
  /// In en, this message translates to:
  /// **'We collect information when you use the CheckDarn application, including:\n\n• Account Information: Email, username, profile picture\n• Location Data: GPS location to display and report events\n• Usage Data: Access time, reporting types\n• Device Information: Mobile model, operating system'**
  String get dataCollectionContent;

  /// No description provided for @dataUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Purpose of Data Usage'**
  String get dataUsageTitle;

  /// No description provided for @dataUsageContent.
  ///
  /// In en, this message translates to:
  /// **'We use your data to:\n\n• Provide event reporting and notification services\n• Display events on maps according to appropriate locations\n• Improve and develop application quality\n• Send necessary and relevant notifications\n• Maintain security and prevent inappropriate usage'**
  String get dataUsageContent;

  /// No description provided for @dataSharingTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Data Sharing'**
  String get dataSharingTitle;

  /// No description provided for @dataSharingContent.
  ///
  /// In en, this message translates to:
  /// **'We do not sell or rent your personal data to third parties\n\nWe may share data in the following cases:\n\n• When we receive your consent\n• To comply with laws or court orders\n• To protect users\' rights and safety\n• Publicly disclosed information (reports that users choose to share)'**
  String get dataSharingContent;

  /// No description provided for @dataSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Data Security'**
  String get dataSecurityTitle;

  /// No description provided for @dataSecurityContent.
  ///
  /// In en, this message translates to:
  /// **'We prioritize protecting your data:\n\n• Use data encryption during transmission and storage\n• Have secure authentication systems\n• Limit data access to necessary personnel only\n• Regularly check and update security systems'**
  String get dataSecurityContent;

  /// No description provided for @userRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'5. User Rights'**
  String get userRightsTitle;

  /// No description provided for @userRightsContent.
  ///
  /// In en, this message translates to:
  /// **'You have rights regarding your personal data:\n\n• Access Right: Request to view data we collect\n• Correction Right: Request to correct incorrect data\n• Deletion Right: Request to delete personal data\n• Withdrawal Right: Cancel service usage at any time\n• Complaint Right: Report data usage issues'**
  String get userRightsContent;

  /// No description provided for @cookiesTitle.
  ///
  /// In en, this message translates to:
  /// **'6. Cookies and Tracking Technologies'**
  String get cookiesTitle;

  /// No description provided for @cookiesContent.
  ///
  /// In en, this message translates to:
  /// **'The application may use these technologies:\n\n• Local Storage: Store settings and temporary data\n• Analytics: Analyze usage to improve the app\n• Push Notifications: Send necessary notifications\n• Firebase Services: Cloud services for data storage'**
  String get cookiesContent;

  /// No description provided for @policyChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'7. Policy Changes'**
  String get policyChangesTitle;

  /// No description provided for @policyChangesContent.
  ///
  /// In en, this message translates to:
  /// **'We may update the privacy policy periodically\n\n• Will notify in advance if there are significant changes\n• Continued usage implies acceptance of new policy\n• Should check policy updates regularly'**
  String get policyChangesContent;

  /// No description provided for @contactPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'8. Contact'**
  String get contactPrivacyTitle;

  /// No description provided for @contactPrivacyContent.
  ///
  /// In en, this message translates to:
  /// **'If you have questions about the privacy policy:\n\n• Contact through the application\n• Send email to support team\n• Use \"Contact Us\" feature in settings page'**
  String get contactPrivacyContent;

  /// No description provided for @respectPrivacy.
  ///
  /// In en, this message translates to:
  /// **'🛡️ We respect your privacy'**
  String get respectPrivacy;

  /// No description provided for @securityMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data is protected with the highest security standards'**
  String get securityMessage;

  /// No description provided for @cannotOpenEmailApp.
  ///
  /// In en, this message translates to:
  /// **'Cannot open email app. Please try another method'**
  String get cannotOpenEmailApp;

  /// No description provided for @emailAppOpened.
  ///
  /// In en, this message translates to:
  /// **'Opening email app...'**
  String get emailAppOpened;

  /// No description provided for @nearMeTitle.
  ///
  /// In en, this message translates to:
  /// **'Near Me'**
  String get nearMeTitle;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @myPosts.
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myPosts;

  /// No description provided for @noReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get noReportsYet;

  /// No description provided for @startWithFirstReport.
  ///
  /// In en, this message translates to:
  /// **'Start with your first report'**
  String get startWithFirstReport;

  /// No description provided for @postStatistics.
  ///
  /// In en, this message translates to:
  /// **'Post Statistics'**
  String get postStatistics;

  /// No description provided for @totalPosts.
  ///
  /// In en, this message translates to:
  /// **'Total posts: {count} items'**
  String totalPosts(int count);

  /// No description provided for @freshPosts.
  ///
  /// In en, this message translates to:
  /// **'Fresh posts (24 hrs): {count} items'**
  String freshPosts(int count);

  /// No description provided for @oldPosts.
  ///
  /// In en, this message translates to:
  /// **'Old posts: {count} items'**
  String oldPosts(int count);

  /// No description provided for @autoDeleteNotice.
  ///
  /// In en, this message translates to:
  /// **'Posts will be automatically deleted after 24 hours\nto maintain data freshness'**
  String get autoDeleteNotice;

  /// No description provided for @deleteOldPostsNow.
  ///
  /// In en, this message translates to:
  /// **'Delete old posts now'**
  String get deleteOldPostsNow;

  /// No description provided for @deletingOldPosts.
  ///
  /// In en, this message translates to:
  /// **'Deleting old posts...'**
  String get deletingOldPosts;

  /// No description provided for @deleteComplete.
  ///
  /// In en, this message translates to:
  /// **'Deletion complete! {count} fresh posts remaining'**
  String deleteComplete(int count);

  /// No description provided for @deleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting posts: {error}'**
  String deleteError(String error);

  /// No description provided for @generalError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String generalError(String error);

  /// No description provided for @viewMap.
  ///
  /// In en, this message translates to:
  /// **'View Map'**
  String get viewMap;

  /// No description provided for @clickToViewImage.
  ///
  /// In en, this message translates to:
  /// **'Click to view image'**
  String get clickToViewImage;

  /// No description provided for @devOnly.
  ///
  /// In en, this message translates to:
  /// **'View Post Statistics (Dev Only)'**
  String get devOnly;

  /// No description provided for @meters.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get meters;

  /// No description provided for @kilometers.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kilometers;

  /// No description provided for @reportScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Report What?'**
  String get reportScreenTitle;

  /// No description provided for @selectEventType.
  ///
  /// In en, this message translates to:
  /// **'Select Event Type *'**
  String get selectEventType;

  /// No description provided for @detailsField.
  ///
  /// In en, this message translates to:
  /// **'Details *'**
  String get detailsField;

  /// No description provided for @clickToSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Click to select location'**
  String get clickToSelectLocation;

  /// No description provided for @willTakeToCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Will take you to your current location *'**
  String get willTakeToCurrentLocation;

  /// No description provided for @findingCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Finding current location...'**
  String get findingCurrentLocation;

  /// No description provided for @loadingAddressInfo.
  ///
  /// In en, this message translates to:
  /// **'Loading address information...'**
  String get loadingAddressInfo;

  /// No description provided for @tapToChangeLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap to change location'**
  String get tapToChangeLocation;

  /// No description provided for @imageOnlyForLostAnimals.
  ///
  /// In en, this message translates to:
  /// **'Images can only be attached for \"Lost Animals\" reports\nto prevent inappropriate content'**
  String get imageOnlyForLostAnimals;

  /// No description provided for @selectImageSource.
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image (Optional)'**
  String get addImage;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get save;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @securityValidationFailedImage.
  ///
  /// In en, this message translates to:
  /// **'Security validation failed. Cannot upload image'**
  String get securityValidationFailedImage;

  /// No description provided for @webpCompression.
  ///
  /// In en, this message translates to:
  /// **'WebP Compression...'**
  String get webpCompression;

  /// No description provided for @imageUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully!'**
  String get imageUploadSuccess;

  /// No description provided for @cannotProcessImage.
  ///
  /// In en, this message translates to:
  /// **'Cannot process image'**
  String get cannotProcessImage;

  /// No description provided for @imageSelectionError.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image: {error}'**
  String imageSelectionError(String error);

  /// No description provided for @securityValidationFailedGeneral.
  ///
  /// In en, this message translates to:
  /// **'Security validation failed. Please try again'**
  String get securityValidationFailedGeneral;

  /// No description provided for @pleaseSelectCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Please select coordinates: {field}'**
  String pleaseSelectCoordinates(String field);

  /// No description provided for @pleaseFillData.
  ///
  /// In en, this message translates to:
  /// **'Please fill in data: {field}'**
  String pleaseFillData(String field);

  /// No description provided for @eventLocation.
  ///
  /// In en, this message translates to:
  /// **'Event Location'**
  String get eventLocation;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found. Please login again'**
  String get userNotFound;

  /// No description provided for @dailyLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Limit exceeded: 5 posts per day. Please wait 24 hrs'**
  String get dailyLimitExceeded;

  /// No description provided for @cannotGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Cannot determine location. Please select location manually'**
  String get cannotGetLocation;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Submitted successfully'**
  String get success;

  /// No description provided for @submitTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report: Timeout. Please check your internet connection'**
  String get submitTimeoutError;

  /// No description provided for @submitError.
  ///
  /// In en, this message translates to:
  /// **'Error submitting report'**
  String get submitError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network connection problem. Please check WiFi/4G'**
  String get networkError;

  /// No description provided for @permissionError.
  ///
  /// In en, this message translates to:
  /// **'No upload permission. Please contact system administrator'**
  String get permissionError;

  /// No description provided for @storageError.
  ///
  /// In en, this message translates to:
  /// **'File upload problem. Please try sending without image'**
  String get storageError;

  /// No description provided for @fileSizeError.
  ///
  /// In en, this message translates to:
  /// **'Image file too large. Please try taking a new photo'**
  String get fileSizeError;

  /// No description provided for @persistentError.
  ///
  /// In en, this message translates to:
  /// **'If the problem persists, try sending without image'**
  String get persistentError;

  /// No description provided for @tryAgainAction.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgainAction;

  /// No description provided for @pleaseSelectEventType.
  ///
  /// In en, this message translates to:
  /// **'Please select event type'**
  String get pleaseSelectEventType;

  /// No description provided for @pleaseFillDetails.
  ///
  /// In en, this message translates to:
  /// **'Please fill in details'**
  String get pleaseFillDetails;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @tapOnMapToSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Or tap on map to select location'**
  String get tapOnMapToSelectLocation;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @addressInformation.
  ///
  /// In en, this message translates to:
  /// **'Address Information'**
  String get addressInformation;

  /// No description provided for @roadName.
  ///
  /// In en, this message translates to:
  /// **'Road Name:'**
  String get roadName;

  /// No description provided for @subDistrict.
  ///
  /// In en, this message translates to:
  /// **'Sub-district:'**
  String get subDistrict;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District:'**
  String get district;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province:'**
  String get province;

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// No description provided for @manualCoordinateEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual coordinate entry'**
  String get manualCoordinateEntry;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @coordinatesOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Coordinates must be in valid range'**
  String get coordinatesOutOfRange;

  /// No description provided for @invalidCoordinateFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid coordinate format'**
  String get invalidCoordinateFormat;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @roadNameHint.
  ///
  /// In en, this message translates to:
  /// **'Road name will be displayed automatically or type manually'**
  String get roadNameHint;

  /// No description provided for @reportComment.
  ///
  /// In en, this message translates to:
  /// **'Report Comment'**
  String get reportComment;

  /// No description provided for @reportCommentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to report this comment as inappropriate?'**
  String get reportCommentConfirm;

  /// No description provided for @reportCommentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Comment reported successfully'**
  String get reportCommentSuccess;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// No description provided for @beFirstToComment.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment!'**
  String get beFirstToComment;

  /// No description provided for @addCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add comment...'**
  String get addCommentHint;

  /// No description provided for @pleaseEnterComment.
  ///
  /// In en, this message translates to:
  /// **'Please enter a comment'**
  String get pleaseEnterComment;

  /// No description provided for @commentSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Comment sent successfully'**
  String get commentSentSuccess;

  /// No description provided for @typeCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Type a comment...'**
  String get typeCommentHint;

  /// No description provided for @soundSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sound Alert Settings'**
  String get soundSettingsTitle;

  /// No description provided for @enableSoundNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Sound Notifications'**
  String get enableSoundNotifications;

  /// No description provided for @enableDisableSoundDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable/Disable all sound alerts'**
  String get enableDisableSoundDesc;

  /// No description provided for @selectSoundType.
  ///
  /// In en, this message translates to:
  /// **'🔊 Select Sound Alert Type'**
  String get selectSoundType;

  /// No description provided for @testSound.
  ///
  /// In en, this message translates to:
  /// **'Test Sound'**
  String get testSound;

  /// No description provided for @soundTips.
  ///
  /// In en, this message translates to:
  /// **'💡 Tips'**
  String get soundTips;

  /// No description provided for @soundTipsDescription.
  ///
  /// In en, this message translates to:
  /// **'• Voice: Reads text aloud in Thai, provides detailed and clear information\n• Silent: No sound alerts, suitable for quiet places'**
  String get soundTipsDescription;

  /// No description provided for @noSoundDescription.
  ///
  /// In en, this message translates to:
  /// **'No sound alerts, completely silent'**
  String get noSoundDescription;

  /// No description provided for @beepSoundDescription.
  ///
  /// In en, this message translates to:
  /// **'Short beep sound (deprecated)'**
  String get beepSoundDescription;

  /// No description provided for @warningSoundDescription.
  ///
  /// In en, this message translates to:
  /// **'Siren warning sound (deprecated)'**
  String get warningSoundDescription;

  /// No description provided for @ttsSoundDescription.
  ///
  /// In en, this message translates to:
  /// **'Reads text aloud in Thai - Recommended'**
  String get ttsSoundDescription;

  /// No description provided for @noSoundDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get noSoundDisplayName;

  /// No description provided for @thaiVoiceDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Thai Voice'**
  String get thaiVoiceDisplayName;

  /// No description provided for @testSoundSuccess.
  ///
  /// In en, this message translates to:
  /// **'Test sound: {soundType}'**
  String testSoundSuccess(String soundType);

  /// No description provided for @cannotPlaySound.
  ///
  /// In en, this message translates to:
  /// **'Cannot play sound: {error}'**
  String cannotPlaySound(String error);

  /// No description provided for @cameraReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Speed Camera Reports'**
  String get cameraReportTitle;

  /// No description provided for @switchToNearbyView.
  ///
  /// In en, this message translates to:
  /// **'Switch to nearby view'**
  String get switchToNearbyView;

  /// No description provided for @switchToNationwideView.
  ///
  /// In en, this message translates to:
  /// **'Switch to nationwide view'**
  String get switchToNationwideView;

  /// No description provided for @newReportTab.
  ///
  /// In en, this message translates to:
  /// **'New Report'**
  String get newReportTab;

  /// No description provided for @votingTab.
  ///
  /// In en, this message translates to:
  /// **'Voting'**
  String get votingTab;

  /// No description provided for @statisticsTab.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTab;

  /// No description provided for @howToReportTitle.
  ///
  /// In en, this message translates to:
  /// **'How to Report'**
  String get howToReportTitle;

  /// No description provided for @howToReportDescription.
  ///
  /// In en, this message translates to:
  /// **'• Report new cameras you encounter\n• Report speed limit changes\n• Data will be verified by the community\n• Once verified, the system will process automatically\n• You cannot vote on your own reports'**
  String get howToReportDescription;

  /// No description provided for @reportSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully! Check in the voting tab'**
  String get reportSubmittedSuccess;

  /// No description provided for @showingNationwidePosts.
  ///
  /// In en, this message translates to:
  /// **'Showing posts from nationwide'**
  String get showingNationwidePosts;

  /// No description provided for @showingNearbyPosts.
  ///
  /// In en, this message translates to:
  /// **'Showing nearby posts'**
  String get showingNearbyPosts;

  /// No description provided for @radiusKm.
  ///
  /// In en, this message translates to:
  /// **'Radius: {radius} km'**
  String radiusKm(int radius);

  /// No description provided for @totalPostsCount.
  ///
  /// In en, this message translates to:
  /// **'Total posts: {count}'**
  String totalPostsCount(int count);

  /// No description provided for @nearbyPostsCount.
  ///
  /// In en, this message translates to:
  /// **'Nearby posts: {count}'**
  String nearbyPostsCount(int count);

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @nationwide.
  ///
  /// In en, this message translates to:
  /// **'Nationwide'**
  String get nationwide;

  /// No description provided for @loginRequiredToVote.
  ///
  /// In en, this message translates to:
  /// **'Login required to vote'**
  String get loginRequiredToVote;

  /// No description provided for @loginThroughMapProfile.
  ///
  /// In en, this message translates to:
  /// **'Please login through profile on map screen'**
  String get loginThroughMapProfile;

  /// No description provided for @tapProfileButtonOnMap.
  ///
  /// In en, this message translates to:
  /// **'Tap the profile button at the top right of the map'**
  String get tapProfileButtonOnMap;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingData;

  /// No description provided for @noPendingReports.
  ///
  /// In en, this message translates to:
  /// **'No reports pending for voting'**
  String get noPendingReports;

  /// No description provided for @thankYouForVerifying.
  ///
  /// In en, this message translates to:
  /// **'Thank you for helping verify data!'**
  String get thankYouForVerifying;

  /// No description provided for @voting.
  ///
  /// In en, this message translates to:
  /// **'Voting...'**
  String get voting;

  /// No description provided for @voteUpvoteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vote \"Exists\" submitted successfully'**
  String get voteUpvoteSuccess;

  /// No description provided for @voteDownvoteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vote \"Doesn\'t exist\" submitted successfully'**
  String get voteDownvoteSuccess;

  /// No description provided for @alreadyVoted.
  ///
  /// In en, this message translates to:
  /// **'You have already voted on this report'**
  String get alreadyVoted;

  /// No description provided for @voteSuccessfullyRecorded.
  ///
  /// In en, this message translates to:
  /// **'Vote recorded successfully!\n(System verified that you have voted)'**
  String get voteSuccessfullyRecorded;

  /// No description provided for @noPermissionToVote.
  ///
  /// In en, this message translates to:
  /// **'No permission to vote\nTry logging out and logging in again'**
  String get noPermissionToVote;

  /// No description provided for @reportNotFound.
  ///
  /// In en, this message translates to:
  /// **'Report not found, may have been deleted'**
  String get reportNotFound;

  /// No description provided for @connectionProblem.
  ///
  /// In en, this message translates to:
  /// **'Connection problem\nPlease check your internet and try again'**
  String get connectionProblem;

  /// No description provided for @cannotVoteRetry.
  ///
  /// In en, this message translates to:
  /// **'Cannot vote, please try again'**
  String get cannotVoteRetry;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loginRequiredForStats.
  ///
  /// In en, this message translates to:
  /// **'Login required to view statistics'**
  String get loginRequiredForStats;

  /// No description provided for @contributionScore.
  ///
  /// In en, this message translates to:
  /// **'Contribution Score'**
  String get contributionScore;

  /// No description provided for @totalContributions.
  ///
  /// In en, this message translates to:
  /// **'Total Contributions'**
  String get totalContributions;

  /// No description provided for @reportsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Reports Submitted'**
  String get reportsSubmitted;

  /// No description provided for @votesGiven.
  ///
  /// In en, this message translates to:
  /// **'Votes Given'**
  String get votesGiven;

  /// No description provided for @communityImpact.
  ///
  /// In en, this message translates to:
  /// **'Community Impact'**
  String get communityImpact;

  /// No description provided for @communityImpactDescription.
  ///
  /// In en, this message translates to:
  /// **'Your participation helps:\n• Speed camera data accuracy\n• Community has up-to-date information\n• Safer driving experience'**
  String get communityImpactDescription;

  /// No description provided for @leaderboardAndRewards.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard and special rewards'**
  String get leaderboardAndRewards;

  /// No description provided for @loginThroughMapProfileRequired.
  ///
  /// In en, this message translates to:
  /// **'Please login through map profile before voting'**
  String get loginThroughMapProfileRequired;

  /// No description provided for @reportSubmissionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully! Check in voting tab'**
  String get reportSubmissionSuccess;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error occurred: {error}'**
  String errorOccurred(String error);

  /// No description provided for @showPostsFromNationwide.
  ///
  /// In en, this message translates to:
  /// **'Show posts from nationwide'**
  String get showPostsFromNationwide;

  /// No description provided for @showNearbyPosts.
  ///
  /// In en, this message translates to:
  /// **'Show nearby posts'**
  String get showNearbyPosts;

  /// No description provided for @radiusAllPosts.
  ///
  /// In en, this message translates to:
  /// **'Radius: {radius} km. • All posts: {count}'**
  String radiusAllPosts(int radius, int count);

  /// No description provided for @radiusNearbyPosts.
  ///
  /// In en, this message translates to:
  /// **'Radius: {radius} km. • Nearby posts: {count}'**
  String radiusNearbyPosts(int radius, int count);

  /// No description provided for @pleaseLoginThroughMapProfile.
  ///
  /// In en, this message translates to:
  /// **'Please login through map profile'**
  String get pleaseLoginThroughMapProfile;

  /// No description provided for @tapProfileButtonInMap.
  ///
  /// In en, this message translates to:
  /// **'Tap profile button at top right of map'**
  String get tapProfileButtonInMap;

  /// No description provided for @voteExistsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vote \"Exists\" submitted successfully'**
  String get voteExistsSuccess;

  /// No description provided for @voteNotExistsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vote \"Doesn\'t exist\" submitted successfully'**
  String get voteNotExistsSuccess;

  /// No description provided for @cameraReportFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Speed Camera Report'**
  String get cameraReportFormTitle;

  /// No description provided for @reportTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Report Type'**
  String get reportTypeLabel;

  /// No description provided for @newCameraLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'New Camera Location'**
  String get newCameraLocationLabel;

  /// No description provided for @selectNewCameraLocation.
  ///
  /// In en, this message translates to:
  /// **'Select New Camera Location'**
  String get selectNewCameraLocation;

  /// No description provided for @selectLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Please select location on map'**
  String get selectLocationOnMap;

  /// No description provided for @roadNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Road Name'**
  String get roadNameLabel;

  /// No description provided for @pleaseEnterRoadName.
  ///
  /// In en, this message translates to:
  /// **'Please enter road name'**
  String get pleaseEnterRoadName;

  /// No description provided for @speedLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed Limit (km/h)'**
  String get speedLimitLabel;

  /// No description provided for @newSpeedLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'New Speed Limit (km/h)'**
  String get newSpeedLimitLabel;

  /// No description provided for @additionalDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional Details'**
  String get additionalDetailsLabel;

  /// No description provided for @selectExistingCameraLabel.
  ///
  /// In en, this message translates to:
  /// **'Select existing camera from system'**
  String get selectExistingCameraLabel;

  /// No description provided for @selectedLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get selectedLocationLabel;

  /// No description provided for @tapToSelectLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Tap to select location on map'**
  String get tapToSelectLocationOnMap;

  /// No description provided for @locationDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Location details and landmarks'**
  String get locationDetailsLabel;

  /// No description provided for @pleaseProvideLocationDetails.
  ///
  /// In en, this message translates to:
  /// **'Please provide location details and landmarks'**
  String get pleaseProvideLocationDetails;

  /// No description provided for @pleaseProvideAtLeast10Characters.
  ///
  /// In en, this message translates to:
  /// **'Please provide at least 10 characters'**
  String get pleaseProvideAtLeast10Characters;

  /// No description provided for @reportNewCamera.
  ///
  /// In en, this message translates to:
  /// **'Report New Camera'**
  String get reportNewCamera;

  /// No description provided for @reportRemovedCamera.
  ///
  /// In en, this message translates to:
  /// **'Report Removed Camera'**
  String get reportRemovedCamera;

  /// No description provided for @reportSpeedChanged.
  ///
  /// In en, this message translates to:
  /// **'Report Speed Limit Changed'**
  String get reportSpeedChanged;

  /// No description provided for @noLocationDataFound.
  ///
  /// In en, this message translates to:
  /// **'No location data found'**
  String get noLocationDataFound;

  /// No description provided for @loginRequiredToViewStats.
  ///
  /// In en, this message translates to:
  /// **'Login required to view statistics'**
  String get loginRequiredToViewStats;

  /// No description provided for @securityCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Security check failed'**
  String get securityCheckFailed;

  /// No description provided for @pleaseLoginBeforeVoting.
  ///
  /// In en, this message translates to:
  /// **'Please login through map page before voting'**
  String get pleaseLoginBeforeVoting;

  /// No description provided for @alreadyVotedDetected.
  ///
  /// In en, this message translates to:
  /// **'Vote completed!\n(System detected you have already voted)'**
  String get alreadyVotedDetected;

  /// No description provided for @noVotingPermission.
  ///
  /// In en, this message translates to:
  /// **'No voting permission\nTry logout and login again'**
  String get noVotingPermission;

  /// No description provided for @engagementScore.
  ///
  /// In en, this message translates to:
  /// **'Engagement Score'**
  String get engagementScore;

  /// No description provided for @totalEngagement.
  ///
  /// In en, this message translates to:
  /// **'Total Engagement'**
  String get totalEngagement;

  /// No description provided for @voteFor.
  ///
  /// In en, this message translates to:
  /// **'Vote For'**
  String get voteFor;

  /// No description provided for @loadingCameraData.
  ///
  /// In en, this message translates to:
  /// **'Loading camera data...'**
  String get loadingCameraData;

  /// No description provided for @noCameraDataFound.
  ///
  /// In en, this message translates to:
  /// **'No camera data found in system'**
  String get noCameraDataFound;

  /// No description provided for @selectedCamera.
  ///
  /// In en, this message translates to:
  /// **'Selected Camera'**
  String get selectedCamera;

  /// No description provided for @tapToSelectCameraFromMap.
  ///
  /// In en, this message translates to:
  /// **'Tap to select camera from map'**
  String get tapToSelectCameraFromMap;

  /// No description provided for @pleaseSelectCameraFromMap.
  ///
  /// In en, this message translates to:
  /// **'Please select camera from map'**
  String get pleaseSelectCameraFromMap;

  /// No description provided for @oldSpeedToNewSpeed.
  ///
  /// In en, this message translates to:
  /// **'Old speed: {oldSpeed} km/h → New: {newSpeed} km/h'**
  String oldSpeedToNewSpeed(int oldSpeed, int newSpeed);

  /// No description provided for @locationExampleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Near Robinson Intersection, In front of school, Opposite gas station, Bridge area'**
  String get locationExampleHint;

  /// No description provided for @pleaseLoginBeforeReportingCamera.
  ///
  /// In en, this message translates to:
  /// **'Please login before reporting camera'**
  String get pleaseLoginBeforeReportingCamera;

  /// No description provided for @coordinatesFormat.
  ///
  /// In en, this message translates to:
  /// **'Latitude: {lat}, Longitude: {lng}'**
  String coordinatesFormat(String lat, String lng);

  /// No description provided for @selectCamera.
  ///
  /// In en, this message translates to:
  /// **'Select Camera'**
  String get selectCamera;

  /// No description provided for @cannotFindCurrentLocationEnableGPS.
  ///
  /// In en, this message translates to:
  /// **'Cannot find current location, please enable GPS'**
  String get cannotFindCurrentLocationEnableGPS;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @speedLimitFormat.
  ///
  /// In en, this message translates to:
  /// **'Speed limit: {limit} km/h'**
  String speedLimitFormat(int limit);

  /// No description provided for @confirmSelection.
  ///
  /// In en, this message translates to:
  /// **'Confirm Selection'**
  String get confirmSelection;

  /// No description provided for @tapCameraIconOnMapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap camera icon on map to select'**
  String get tapCameraIconOnMapToSelect;

  /// No description provided for @cameraNotFoundInSystem.
  ///
  /// In en, this message translates to:
  /// **'Camera data not found in system'**
  String get cameraNotFoundInSystem;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @selectCameraFromMap.
  ///
  /// In en, this message translates to:
  /// **'Select Camera from Map'**
  String get selectCameraFromMap;

  /// No description provided for @searchingCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Searching for current location...'**
  String get searchingCurrentLocation;

  /// No description provided for @foundCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Found current location'**
  String get foundCurrentLocation;

  /// No description provided for @cannotFindLocationUseMap.
  ///
  /// In en, this message translates to:
  /// **'Cannot find location, use map to search for cameras instead'**
  String get cannotFindLocationUseMap;

  /// No description provided for @pleaseAllowLocationAccess.
  ///
  /// In en, this message translates to:
  /// **'Please allow location access in app settings'**
  String get pleaseAllowLocationAccess;

  /// No description provided for @showingBangkokMapNormalSearch.
  ///
  /// In en, this message translates to:
  /// **'Showing Bangkok map (camera search works normally)'**
  String get showingBangkokMapNormalSearch;

  /// No description provided for @selectedCameraInfo.
  ///
  /// In en, this message translates to:
  /// **'Selected Camera'**
  String get selectedCameraInfo;

  /// No description provided for @cameraCode.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String cameraCode(String code);

  /// No description provided for @speedAndType.
  ///
  /// In en, this message translates to:
  /// **'Speed: {speed} km/h • {type}'**
  String speedAndType(int speed, String type);

  /// No description provided for @camerasCount.
  ///
  /// In en, this message translates to:
  /// **'{count} cameras'**
  String camerasCount(int count);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @myReport.
  ///
  /// In en, this message translates to:
  /// **'My Report'**
  String get myReport;

  /// No description provided for @communityMember.
  ///
  /// In en, this message translates to:
  /// **'Community Member'**
  String get communityMember;

  /// No description provided for @deleteReport.
  ///
  /// In en, this message translates to:
  /// **'Delete Report'**
  String get deleteReport;

  /// No description provided for @speedLimitDisplay.
  ///
  /// In en, this message translates to:
  /// **'Speed limit: {speed} km/h'**
  String speedLimitDisplay(int speed);

  /// No description provided for @viewMapButton.
  ///
  /// In en, this message translates to:
  /// **'View Map'**
  String get viewMapButton;

  /// No description provided for @viewCameraOnMap.
  ///
  /// In en, this message translates to:
  /// **'View Camera on Map'**
  String get viewCameraOnMap;

  /// No description provided for @viewLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'View Location: {roadName}'**
  String viewLocationTitle(String roadName);

  /// No description provided for @win.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get win;

  /// No description provided for @tied.
  ///
  /// In en, this message translates to:
  /// **'Tied 3-3'**
  String get tied;

  /// No description provided for @needsMoreVotes.
  ///
  /// In en, this message translates to:
  /// **'Needs {count} more votes'**
  String needsMoreVotes(int count);

  /// No description provided for @exists.
  ///
  /// In en, this message translates to:
  /// **'Exists'**
  String get exists;

  /// No description provided for @trueVote.
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get trueVote;

  /// No description provided for @doesNotExist.
  ///
  /// In en, this message translates to:
  /// **'Does Not Exist'**
  String get doesNotExist;

  /// No description provided for @falseVote.
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get falseVote;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete this report?\n\nOnce deleted, it cannot be recovered.'**
  String get deleteConfirmMessage;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deletingReport.
  ///
  /// In en, this message translates to:
  /// **'Deleting report...'**
  String get deletingReport;

  /// No description provided for @reportDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report deleted successfully 🎉 Updating screen...'**
  String get reportDeletedSuccess;

  /// No description provided for @deleteTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'Deletion took too long, please try again'**
  String get deleteTimeoutError;

  /// No description provided for @newCameraType.
  ///
  /// In en, this message translates to:
  /// **'📷 New Camera'**
  String get newCameraType;

  /// No description provided for @removedCameraType.
  ///
  /// In en, this message translates to:
  /// **'❌ Camera Removed'**
  String get removedCameraType;

  /// No description provided for @speedChangedType.
  ///
  /// In en, this message translates to:
  /// **'⚡ Speed Changed'**
  String get speedChangedType;

  /// No description provided for @yourReportPending.
  ///
  /// In en, this message translates to:
  /// **'Your Report - Pending Votes'**
  String get yourReportPending;

  /// No description provided for @alreadyVotedStatus.
  ///
  /// In en, this message translates to:
  /// **'You Have Already Voted'**
  String get alreadyVotedStatus;

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get pendingReview;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Data'**
  String get duplicate;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(int days);

  /// No description provided for @locationAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access denied'**
  String get locationAccessDenied;

  /// No description provided for @enableLocationInSettings.
  ///
  /// In en, this message translates to:
  /// **'Please enable location access in settings'**
  String get enableLocationInSettings;

  /// No description provided for @speedCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Speed Camera'**
  String get speedCameraTitle;

  /// No description provided for @soundSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sound Alert Settings'**
  String get soundSettingsTooltip;

  /// No description provided for @loadingDataText.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingDataText;

  /// No description provided for @cannotDetermineLocation.
  ///
  /// In en, this message translates to:
  /// **'Cannot determine location'**
  String get cannotDetermineLocation;

  /// No description provided for @cannotLoadSpeedCameraData.
  ///
  /// In en, this message translates to:
  /// **'Cannot load speed camera data'**
  String get cannotLoadSpeedCameraData;

  /// No description provided for @speedLimitText.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get speedLimitText;

  /// No description provided for @predictedCameraAlert.
  ///
  /// In en, this message translates to:
  /// **'Predicted speed camera in 10 seconds on {roadName} limit {speedLimit} km/h'**
  String predictedCameraAlert(String roadName, int speedLimit);

  /// No description provided for @nearCameraReduceSpeed.
  ///
  /// In en, this message translates to:
  /// **'Near speed camera, please reduce speed'**
  String get nearCameraReduceSpeed;

  /// No description provided for @nearCameraGoodSpeed.
  ///
  /// In en, this message translates to:
  /// **'Near speed camera, appropriate speed'**
  String get nearCameraGoodSpeed;

  /// No description provided for @cameraAheadDistance.
  ///
  /// In en, this message translates to:
  /// **'Speed camera ahead {distance}m limit {speedLimit} km/h'**
  String cameraAheadDistance(int distance, int speedLimit);

  /// No description provided for @speedCameraBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Speed Camera'**
  String get speedCameraBadgeTitle;

  /// No description provided for @badgeUpdatingCameraData.
  ///
  /// In en, this message translates to:
  /// **'Updating camera data...'**
  String get badgeUpdatingCameraData;

  /// No description provided for @badgeFoundNewCameras.
  ///
  /// In en, this message translates to:
  /// **'🎉 Found {count} new community verified cameras!'**
  String badgeFoundNewCameras(int count);

  /// No description provided for @badgeCameraDataUpdated.
  ///
  /// In en, this message translates to:
  /// **'✅ Camera data updated successfully'**
  String get badgeCameraDataUpdated;

  /// No description provided for @badgeCannotUpdateData.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Cannot update data'**
  String get badgeCannotUpdateData;

  /// No description provided for @badgeSecurityAnomalyDetected.
  ///
  /// In en, this message translates to:
  /// **'🔒 System detected abnormal usage'**
  String get badgeSecurityAnomalyDetected;

  /// No description provided for @badgeSystemBackToNormal.
  ///
  /// In en, this message translates to:
  /// **'✅ System back to normal operation'**
  String get badgeSystemBackToNormal;

  /// No description provided for @badgePredictedCameraAhead.
  ///
  /// In en, this message translates to:
  /// **'🔮 Camera detected in 10 seconds'**
  String get badgePredictedCameraAhead;

  /// No description provided for @badgeNearCameraReduceSpeed.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Near camera, please reduce speed'**
  String get badgeNearCameraReduceSpeed;

  /// No description provided for @badgeNearCameraGoodSpeed.
  ///
  /// In en, this message translates to:
  /// **'✅ Near camera, appropriate speed'**
  String get badgeNearCameraGoodSpeed;

  /// No description provided for @badgeExceedingSpeed.
  ///
  /// In en, this message translates to:
  /// **'🚨 Exceeding {excessSpeed} km/h'**
  String badgeExceedingSpeed(int excessSpeed);

  /// No description provided for @badgeCameraAhead.
  ///
  /// In en, this message translates to:
  /// **'📍 Camera ahead {distance}m'**
  String badgeCameraAhead(int distance);

  /// No description provided for @badgeRadarDetection.
  ///
  /// In en, this message translates to:
  /// **'🔊 Camera radar {distance}m'**
  String badgeRadarDetection(int distance);

  /// No description provided for @soundTypeNone.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get soundTypeNone;

  /// No description provided for @soundTypeBeep.
  ///
  /// In en, this message translates to:
  /// **'Real beep sound (not recommended)'**
  String get soundTypeBeep;

  /// No description provided for @soundTypeWarning.
  ///
  /// In en, this message translates to:
  /// **'Real warning siren (not recommended)'**
  String get soundTypeWarning;

  /// No description provided for @soundTypeTts.
  ///
  /// In en, this message translates to:
  /// **'Thai voice'**
  String get soundTypeTts;

  /// No description provided for @ttsDistanceKilometer.
  ///
  /// In en, this message translates to:
  /// **'{distance} kilometers'**
  String ttsDistanceKilometer(String distance);

  /// No description provided for @ttsDistanceMeter.
  ///
  /// In en, this message translates to:
  /// **'{distance} meters'**
  String ttsDistanceMeter(int distance);

  /// No description provided for @ttsCameraDistance.
  ///
  /// In en, this message translates to:
  /// **'Speed camera is {distance} away from you'**
  String ttsCameraDistance(String distance);

  /// No description provided for @ttsEnteringRoadSpeed.
  ///
  /// In en, this message translates to:
  /// **'Entering {roadName} speed limit {speedLimit} kilometers per hour'**
  String ttsEnteringRoadSpeed(String roadName, int speedLimit);

  /// No description provided for @ttsBeep.
  ///
  /// In en, this message translates to:
  /// **'Beep'**
  String get ttsBeep;

  /// No description provided for @ttsWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get ttsWarning;

  /// No description provided for @ttsTestVoice.
  ///
  /// In en, this message translates to:
  /// **'Test Thai voice'**
  String get ttsTestVoice;

  /// No description provided for @ttsCameraExample.
  ///
  /// In en, this message translates to:
  /// **'Speed camera ahead speed limit 90 kilometers per hour'**
  String get ttsCameraExample;

  /// No description provided for @noMessage.
  ///
  /// In en, this message translates to:
  /// **'No message'**
  String get noMessage;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error occurred'**
  String get error;

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error occurred: {error}'**
  String errorWithDetails(String error);

  /// No description provided for @categoryCount.
  ///
  /// In en, this message translates to:
  /// **'Category ({count})'**
  String categoryCount(int count);

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @listing.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get listing;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access denied'**
  String get locationPermissionDenied;

  /// No description provided for @enableLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'Please enable location access in settings'**
  String get enableLocationPermission;

  /// No description provided for @cannotDetermineCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Cannot determine current location'**
  String get cannotDetermineCurrentLocation;

  /// No description provided for @coordinateValidationError.
  ///
  /// In en, this message translates to:
  /// **'Invalid coordinates: Latitude (-90 to 90), Longitude (-180 to 180)'**
  String get coordinateValidationError;

  /// No description provided for @invalidCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Invalid coordinate format'**
  String get invalidCoordinates;

  /// No description provided for @cameraLocation.
  ///
  /// In en, this message translates to:
  /// **'Camera location - {roadName}'**
  String cameraLocation(String roadName);

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @manualCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Enter coordinates manually'**
  String get manualCoordinates;

  /// No description provided for @tapMapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Or tap on map to select location'**
  String get tapMapToSelect;

  /// No description provided for @roadNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Road name'**
  String get roadNameFieldLabel;

  /// No description provided for @roadNameHintText.
  ///
  /// In en, this message translates to:
  /// **'Road name will be displayed automatically or type manually'**
  String get roadNameHintText;

  /// No description provided for @selectedLocationText.
  ///
  /// In en, this message translates to:
  /// **'Selected location:'**
  String get selectedLocationText;

  /// No description provided for @cameraLocationText.
  ///
  /// In en, this message translates to:
  /// **'Camera location:'**
  String get cameraLocationText;

  /// No description provided for @speedLimitInfo.
  ///
  /// In en, this message translates to:
  /// **'Speed limit: {speedLimit} km/h'**
  String speedLimitInfo(int speedLimit);

  /// No description provided for @noDetails.
  ///
  /// In en, this message translates to:
  /// **'No details'**
  String get noDetails;

  /// No description provided for @noLocation.
  ///
  /// In en, this message translates to:
  /// **'No location specified'**
  String get noLocation;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @coordinatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinatesLabel;

  /// No description provided for @closeDialog.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeDialog;

  /// No description provided for @removedDetailPage.
  ///
  /// In en, this message translates to:
  /// **'Detail page has been removed'**
  String get removedDetailPage;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @saveSettingsSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Settings saved successfully'**
  String get saveSettingsSuccess;

  /// No description provided for @saveSettingsError.
  ///
  /// In en, this message translates to:
  /// **'❌ Error occurred: {error}'**
  String saveSettingsError(String error);

  /// No description provided for @testingNotification.
  ///
  /// In en, this message translates to:
  /// **'🔔 Testing notification...'**
  String get testingNotification;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'✅ Test notification sent'**
  String get testNotificationSent;

  /// No description provided for @testNotificationError.
  ///
  /// In en, this message translates to:
  /// **'❌ Error testing: {error}'**
  String testNotificationError(String error);

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationTitle;

  /// No description provided for @saveSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get saveSettingsTooltip;

  /// No description provided for @mainSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'⚙️ Main Settings'**
  String get mainSettingsTitle;

  /// No description provided for @enableNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotificationTitle;

  /// No description provided for @enableNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications from CheckDarn app'**
  String get enableNotificationSubtitle;

  /// No description provided for @notificationTypesTitle.
  ///
  /// In en, this message translates to:
  /// **'🔔 Notification Types'**
  String get notificationTypesTitle;

  /// No description provided for @newEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'New Events'**
  String get newEventsTitle;

  /// No description provided for @newEventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when new events are reported near you'**
  String get newEventsSubtitle;

  /// No description provided for @commentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when someone comments on your posts'**
  String get commentsSubtitle;

  /// No description provided for @systemTitle.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTitle;

  /// No description provided for @systemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System notifications and updates'**
  String get systemSubtitle;

  /// No description provided for @statusTitle.
  ///
  /// In en, this message translates to:
  /// **'📊 Status'**
  String get statusTitle;

  /// No description provided for @userTitle.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userTitle;

  /// No description provided for @deviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get deviceTitle;

  /// No description provided for @deviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get deviceConnected;

  /// No description provided for @notificationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationDisabled;

  /// No description provided for @testTitle.
  ///
  /// In en, this message translates to:
  /// **'🧪 Test'**
  String get testTitle;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @tipsTitle.
  ///
  /// In en, this message translates to:
  /// **'💡 Tips'**
  String get tipsTitle;

  /// No description provided for @privacySettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySettingTitle;

  /// No description provided for @privacySettingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We won\'t notify you when you post yourself'**
  String get privacySettingSubtitle;

  /// No description provided for @batterySavingTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery Saving'**
  String get batterySavingTitle;

  /// No description provided for @batterySavingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off unnecessary notifications to save battery'**
  String get batterySavingSubtitle;

  /// No description provided for @loginProcessStarted.
  ///
  /// In en, this message translates to:
  /// **'🚀 Starting login process...'**
  String get loginProcessStarted;

  /// No description provided for @loginSuccessWelcome.
  ///
  /// In en, this message translates to:
  /// **'Login successful! Welcome {name}'**
  String loginSuccessWelcome(String name);

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(String error);

  /// No description provided for @platformDescription.
  ///
  /// In en, this message translates to:
  /// **'Event reporting platform\nfor your community'**
  String get platformDescription;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @loginBenefit.
  ///
  /// In en, this message translates to:
  /// **'Signing in allows you to\nreport events and comment'**
  String get loginBenefit;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'\"Know First, Survive First, Safe First\"'**
  String get appSlogan;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0'**
  String get appVersion;

  /// No description provided for @readyToTest.
  ///
  /// In en, this message translates to:
  /// **'Ready to test'**
  String get readyToTest;

  /// No description provided for @alreadyLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Already logged in'**
  String get alreadyLoggedIn;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @testingLogin.
  ///
  /// In en, this message translates to:
  /// **'Testing login...'**
  String get testingLogin;

  /// No description provided for @startLoginTest.
  ///
  /// In en, this message translates to:
  /// **'🧪 Starting login test...'**
  String get startLoginTest;

  /// No description provided for @loginSuccessEmail.
  ///
  /// In en, this message translates to:
  /// **'Login successful: {email}'**
  String loginSuccessEmail(String email);

  /// No description provided for @loginSuccessName.
  ///
  /// In en, this message translates to:
  /// **'Login successful: {name}'**
  String loginSuccessName(String name);

  /// No description provided for @userCancelledLogin.
  ///
  /// In en, this message translates to:
  /// **'User cancelled login'**
  String get userCancelledLogin;

  /// No description provided for @loginTestFailed.
  ///
  /// In en, this message translates to:
  /// **'❌ Login test failed: {error}'**
  String loginTestFailed(String error);

  /// No description provided for @loginFailedGeneral.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailedGeneral(String error);

  /// No description provided for @loggedOut.
  ///
  /// In en, this message translates to:
  /// **'Logged out'**
  String get loggedOut;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logout successful'**
  String get logoutSuccess;

  /// No description provided for @logoutFailedError.
  ///
  /// In en, this message translates to:
  /// **'Logout failed: {error}'**
  String logoutFailedError(String error);

  /// No description provided for @loginTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Login Test'**
  String get loginTestTitle;

  /// No description provided for @loginStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Login Status'**
  String get loginStatusTitle;

  /// No description provided for @userDataTitle.
  ///
  /// In en, this message translates to:
  /// **'User Data'**
  String get userDataTitle;

  /// No description provided for @testingTitle.
  ///
  /// In en, this message translates to:
  /// **'Testing'**
  String get testingTitle;

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testing;

  /// No description provided for @testLogin.
  ///
  /// In en, this message translates to:
  /// **'Test Login'**
  String get testLogin;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes:'**
  String get notesTitle;

  /// No description provided for @debugConsole.
  ///
  /// In en, this message translates to:
  /// **'• Check Console/Log for debug details'**
  String get debugConsole;

  /// No description provided for @checkGoogleServices.
  ///
  /// In en, this message translates to:
  /// **'• Check Google Services and Firebase Console'**
  String get checkGoogleServices;

  /// No description provided for @checkSHA1.
  ///
  /// In en, this message translates to:
  /// **'• Check SHA-1 fingerprint in Firebase'**
  String get checkSHA1;

  /// No description provided for @testOnDevice.
  ///
  /// In en, this message translates to:
  /// **'• Test on real device, not Emulator'**
  String get testOnDevice;

  /// No description provided for @simpleTestReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to test'**
  String get simpleTestReady;

  /// No description provided for @simpleTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get simpleTesting;

  /// No description provided for @simpleTestStart.
  ///
  /// In en, this message translates to:
  /// **'🧪 === Starting login test ==='**
  String get simpleTestStart;

  /// No description provided for @authServiceInitialized.
  ///
  /// In en, this message translates to:
  /// **'AuthService initialized\nLogin status: {status}'**
  String authServiceInitialized(bool status);

  /// No description provided for @categoryWithCount.
  ///
  /// In en, this message translates to:
  /// **'Category ({count})'**
  String categoryWithCount(int count);

  /// No description provided for @urgentReport.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgentReport;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listView;

  /// No description provided for @postStatisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'📊 Post Statistics'**
  String get postStatisticsTitle;

  /// No description provided for @totalPostsWithEmoji.
  ///
  /// In en, this message translates to:
  /// **'📄 Total posts: {count} items'**
  String totalPostsWithEmoji(int count);

  /// No description provided for @freshPostsWithEmoji.
  ///
  /// In en, this message translates to:
  /// **'✨ Fresh posts (24 hrs): {count} items'**
  String freshPostsWithEmoji(int count);

  /// No description provided for @oldPostsWithEmoji.
  ///
  /// In en, this message translates to:
  /// **'🗑️ Old posts: {count} items'**
  String oldPostsWithEmoji(int count);

  /// No description provided for @autoDeleteInfo.
  ///
  /// In en, this message translates to:
  /// **'💡 Posts will be automatically deleted after 24 hours\nto maintain data freshness'**
  String get autoDeleteInfo;

  /// No description provided for @cleanupOldPosts.
  ///
  /// In en, this message translates to:
  /// **'🧹 Delete old posts now'**
  String get cleanupOldPosts;

  /// No description provided for @cleaningPosts.
  ///
  /// In en, this message translates to:
  /// **'🧹 Deleting old posts...'**
  String get cleaningPosts;

  /// No description provided for @cleanupComplete.
  ///
  /// In en, this message translates to:
  /// **'✅ Cleanup complete! {count} fresh posts remaining'**
  String cleanupComplete(int count);

  /// No description provided for @cleanupError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting posts: {error}'**
  String cleanupError(String error);

  /// No description provided for @postStatisticsTooltip.
  ///
  /// In en, this message translates to:
  /// **'View post statistics'**
  String get postStatisticsTooltip;

  /// No description provided for @loadingDataError.
  ///
  /// In en, this message translates to:
  /// **'Error occurred: {error}'**
  String loadingDataError(String error);

  /// No description provided for @loadingText.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingText;

  /// No description provided for @noReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get noReportsTitle;

  /// No description provided for @startReporting.
  ///
  /// In en, this message translates to:
  /// **'Start with your first report'**
  String get startReporting;

  /// No description provided for @reportListTitle.
  ///
  /// In en, this message translates to:
  /// **'Report List'**
  String get reportListTitle;

  /// No description provided for @unspecifiedLocation.
  ///
  /// In en, this message translates to:
  /// **'Location not specified'**
  String get unspecifiedLocation;

  /// No description provided for @showComments.
  ///
  /// In en, this message translates to:
  /// **'Show Comments'**
  String get showComments;

  /// No description provided for @eventsInAreaFull.
  ///
  /// In en, this message translates to:
  /// **'Events in this area ({count} items)'**
  String eventsInAreaFull(int count);

  /// No description provided for @unspecifiedUser.
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get unspecifiedUser;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Anonymous user'**
  String get unknownUser;

  /// No description provided for @maskedUserFallback.
  ///
  /// In en, this message translates to:
  /// **'Anonymous user'**
  String get maskedUserFallback;

  /// No description provided for @loginSuccessWithName.
  ///
  /// In en, this message translates to:
  /// **'Login successful! Welcome {name}'**
  String loginSuccessWithName(String name);

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Login error: {error}'**
  String loginError(String error);

  /// No description provided for @logoutSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Logout successful'**
  String get logoutSuccessful;

  /// No description provided for @logoutError.
  ///
  /// In en, this message translates to:
  /// **'Logout error: {error}'**
  String logoutError(String error);

  /// No description provided for @loginThroughMapRequired.
  ///
  /// In en, this message translates to:
  /// **'Please login through map profile'**
  String get loginThroughMapRequired;

  /// No description provided for @fallbackOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get fallbackOther;

  /// No description provided for @developmentOnly.
  ///
  /// In en, this message translates to:
  /// **'(Dev Only)'**
  String get developmentOnly;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @defaultUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUser;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @roadNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Road name'**
  String get roadNamePlaceholder;

  /// No description provided for @eventLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Event location'**
  String get eventLocationLabel;

  /// No description provided for @unspecified.
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get unspecified;

  /// No description provided for @securityTimeout.
  ///
  /// In en, this message translates to:
  /// **'Security check timeout'**
  String get securityTimeout;

  /// No description provided for @locationRequest.
  ///
  /// In en, this message translates to:
  /// **'📍 Requesting current location...'**
  String get locationRequest;

  /// No description provided for @locationReceived.
  ///
  /// In en, this message translates to:
  /// **'✅ Location received: {location}'**
  String locationReceived(String location);

  /// No description provided for @cannotGetLocationManual.
  ///
  /// In en, this message translates to:
  /// **'Cannot determine location. Please select location manually'**
  String get cannotGetLocationManual;

  /// No description provided for @reportTimeoutWarning.
  ///
  /// In en, this message translates to:
  /// **'Report submission timeout. Please check internet connection'**
  String get reportTimeoutWarning;

  /// No description provided for @reportSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get reportSuccessTitle;

  /// No description provided for @reportTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report: Timeout. Please check your internet connection'**
  String get reportTimeoutError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
