// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get searchingPostsInArea => 'Searching for posts in this area...';

  @override
  String movedToViewPosts(String locationName) {
    return 'Moved to view posts in area: $locationName';
  }

  @override
  String get selectedLocation => 'Selected location';

  @override
  String get cannotLoadImage => 'Cannot load image';

  @override
  String get comments => 'Comments';

  @override
  String get noTitle => 'No title';

  @override
  String get anonymousUser => 'Anonymous user';

  @override
  String get myLocationTooltip => 'Back to my real location';

  @override
  String eventsInArea(int count) {
    return 'Events in this area ($count items)';
  }

  @override
  String get kilometerShort => 'km';

  @override
  String cannotGetLocationInfo(String error) {
    return 'Cannot retrieve location information: $error';
  }

  @override
  String get unknownLocation => 'Unknown location';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String cannotLoadData(String error) {
    return 'Cannot load data: $error';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String get emergency => 'Emergency';

  @override
  String get category => 'Type';

  @override
  String get reportWhat => 'Report';

  @override
  String get nearMe => 'Near Me';

  @override
  String get speedCamera => 'Camera';

  @override
  String get emergencyNumbers => 'Emergency Numbers';

  @override
  String get police => 'Police';

  @override
  String get traffic => 'Traffic';

  @override
  String get highway => 'Highway Department';

  @override
  String get ruralRoad => 'Rural Road';

  @override
  String get fireDepartment => 'Fire Department';

  @override
  String get emergencyMedical => 'Emergency Medical Services (EMS)';

  @override
  String get erawanCenter => 'Erawan Center (Bangkok)';

  @override
  String get disasterAlert => 'Disaster Alert';

  @override
  String get bombThreatTerrorism => 'Bomb Threat / Terrorism';

  @override
  String get diseaseControl => 'Disease Control Center';

  @override
  String get disasterPrevention => 'Disaster Prevention and Mitigation (DDPM)';

  @override
  String get ruamkatanyu => 'Ruamkatanyu Foundation';

  @override
  String get pohtecktung => 'Poh Teck Tung Foundation';

  @override
  String get cyberCrimeHotline => 'Cyber Crime Hotline';

  @override
  String get consumerProtection => 'Office of Consumer Protection Board (OCPB)';

  @override
  String get js100 => 'JS.100';

  @override
  String get touristPolice => 'Tourist Police';

  @override
  String get tourismAuthority => 'Tourism Authority of Thailand (TAT)';

  @override
  String get harborDepartment => 'Harbor Department';

  @override
  String get waterAccident => 'Water Accident';

  @override
  String get expressway => 'Expressway Authority of Thailand';

  @override
  String get transportCooperative => 'Transport Cooperative';

  @override
  String get busVan => 'Bus / Van';

  @override
  String get taxiGrab => 'Taxi / Grab';

  @override
  String get meaElectricity => 'Metropolitan Electricity Authority (MEA)';

  @override
  String get peaElectricity => 'Provincial Electricity Authority (PEA)';

  @override
  String cannotCallPhone(String phoneNumber) {
    return 'Cannot call $phoneNumber\nPlease check if device supports phone calls';
  }

  @override
  String get selectCategory => 'Select Category';

  @override
  String selectedOfTotal(int selected, int total) {
    return '$selected of $total items';
  }

  @override
  String get categoryCheckpoint => 'Checkpoint';

  @override
  String get categoryAccident => 'Accident';

  @override
  String get categoryFire => 'Fire';

  @override
  String get categoryFloodRain => 'Rain/Flood';

  @override
  String get categoryTsunami => 'Tsunami';

  @override
  String get categoryEarthquake => 'Earthquake';

  @override
  String get categoryAnimalLost => 'Lost Animal';

  @override
  String get categoryQuestion => 'General Question';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get speedCameraSoundAlert => 'Speed Camera Sound Alert';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get enableNotificationsDesc => 'Notify when new events occur';

  @override
  String get general => 'General';

  @override
  String get thaiVoice => 'Thai Voice';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get thai => 'Thai';

  @override
  String get english => 'English';

  @override
  String get currentlySelected => 'Currently Selected';

  @override
  String get comingSoon => 'Coming Soon!';

  @override
  String get close => 'Close';

  @override
  String get shareApp => 'Share App';

  @override
  String get shareAppDesc => 'Share app with friends';

  @override
  String get reviewApp => 'Review App';

  @override
  String get reviewAppDesc => 'Rate app on App Store';

  @override
  String get aboutApp => 'About App';

  @override
  String get version => 'Version';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get sendFeedbackOrReport => 'Send feedback or report issues';

  @override
  String get email => 'Email';

  @override
  String get openEmailApp => 'Open email app';

  @override
  String get reportProblem => 'Report Problem';

  @override
  String get reportProblemDesc => 'Report usage issues';

  @override
  String get reportFeatureComingSoon => 'Report feature coming soon!';

  @override
  String get logoutTitle => 'Logout';

  @override
  String get logoutMessage => 'Do you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get logout => 'Logout';

  @override
  String get securityValidationFailed => 'Security validation failed';

  @override
  String get logoutFailed => 'Logout failed';

  @override
  String get welcomeTo => 'Welcome to';

  @override
  String get termsOfServiceTitle => 'Terms of Service';

  @override
  String get termsOfServiceHeader => '📋 CheckDarn Terms of Service';

  @override
  String get lastUpdated => 'Last Updated: August 8, 2025';

  @override
  String get acceptanceOfTermsTitle => '1. Acceptance of Terms';

  @override
  String get acceptanceOfTermsContent =>
      'By using the CheckDarn application, you agree to accept and comply with all terms of service. If you do not accept these terms, please stop using the application immediately.';

  @override
  String get purposeOfUseTitle => '2. Purpose of Use';

  @override
  String get purposeOfUseContent =>
      'CheckDarn is an application for reporting and alerting various events in the area, such as traffic, accidents, or other important events to help the community receive useful information.';

  @override
  String get appropriateUseTitle => '3. Appropriate Use';

  @override
  String get appropriateUseContent =>
      'Users must use the application responsibly. Do not post false, offensive, or illegal information. Reported information should be factual and beneficial to the community.';

  @override
  String get privacyTitle => '4. Privacy';

  @override
  String get privacyContent =>
      'We value user privacy. Personal data will be kept secure and used only for service development and improvement purposes.';

  @override
  String get responsibilityTitle => '5. Responsibility';

  @override
  String get responsibilityContent =>
      'Application developers are not responsible for any damages arising from the use of the application. Users must use their judgment when making decisions based on received information.';

  @override
  String get modificationsTitle => '6. Terms Modifications';

  @override
  String get modificationsContent =>
      'We reserve the right to modify the terms of service at any time. Modifications will take effect immediately after being announced in the application.';

  @override
  String get contactTitle => '7. Contact';

  @override
  String get contactContent =>
      'If you have questions or need to contact regarding the terms of service, you can contact through the application or designated channels.';

  @override
  String get thankYouForUsing => '✅ Thank you for using CheckDarn';

  @override
  String get communityMessage =>
      'Together building a safe community with good information';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicyHeader => '🔒 CheckDarn Privacy Policy';

  @override
  String get effectiveFrom => 'Effective from: August 8, 2025';

  @override
  String get dataCollectionTitle => '1. Data We Collect';

  @override
  String get dataCollectionContent =>
      'We collect information when you use the CheckDarn application, including:\n\n• Account Information: Email, username, profile picture\n• Location Data: GPS location to display and report events\n• Usage Data: Access time, reporting types\n• Device Information: Mobile model, operating system';

  @override
  String get dataUsageTitle => '2. Purpose of Data Usage';

  @override
  String get dataUsageContent =>
      'We use your data to:\n\n• Provide event reporting and notification services\n• Display events on maps according to appropriate locations\n• Improve and develop application quality\n• Send necessary and relevant notifications\n• Maintain security and prevent inappropriate usage';

  @override
  String get dataSharingTitle => '3. Data Sharing';

  @override
  String get dataSharingContent =>
      'We do not sell or rent your personal data to third parties\n\nWe may share data in the following cases:\n\n• When we receive your consent\n• To comply with laws or court orders\n• To protect users\' rights and safety\n• Publicly disclosed information (reports that users choose to share)';

  @override
  String get dataSecurityTitle => '4. Data Security';

  @override
  String get dataSecurityContent =>
      'We prioritize protecting your data:\n\n• Use data encryption during transmission and storage\n• Have secure authentication systems\n• Limit data access to necessary personnel only\n• Regularly check and update security systems';

  @override
  String get userRightsTitle => '5. User Rights';

  @override
  String get userRightsContent =>
      'You have rights regarding your personal data:\n\n• Access Right: Request to view data we collect\n• Correction Right: Request to correct incorrect data\n• Deletion Right: Request to delete personal data\n• Withdrawal Right: Cancel service usage at any time\n• Complaint Right: Report data usage issues';

  @override
  String get cookiesTitle => '6. Cookies and Tracking Technologies';

  @override
  String get cookiesContent =>
      'The application may use these technologies:\n\n• Local Storage: Store settings and temporary data\n• Analytics: Analyze usage to improve the app\n• Push Notifications: Send necessary notifications\n• Firebase Services: Cloud services for data storage';

  @override
  String get policyChangesTitle => '7. Policy Changes';

  @override
  String get policyChangesContent =>
      'We may update the privacy policy periodically\n\n• Will notify in advance if there are significant changes\n• Continued usage implies acceptance of new policy\n• Should check policy updates regularly';

  @override
  String get contactPrivacyTitle => '8. Contact';

  @override
  String get contactPrivacyContent =>
      'If you have questions about the privacy policy:\n\n• Contact through the application\n• Send email to support team\n• Use \"Contact Us\" feature in settings page';

  @override
  String get respectPrivacy => '🛡️ We respect your privacy';

  @override
  String get securityMessage =>
      'Your data is protected with the highest security standards';

  @override
  String get cannotOpenEmailApp =>
      'Cannot open email app. Please try another method';

  @override
  String get emailAppOpened => 'Opening email app...';

  @override
  String get nearMeTitle => 'Near Me';

  @override
  String get allCategories => 'All';

  @override
  String get myPosts => 'My Posts';

  @override
  String get noReportsYet => 'No reports yet';

  @override
  String get startWithFirstReport => 'Start with your first report';

  @override
  String get postStatistics => 'Post Statistics';

  @override
  String totalPosts(int count) {
    return 'Total posts: $count items';
  }

  @override
  String freshPosts(int count) {
    return 'Fresh posts (24 hrs): $count items';
  }

  @override
  String oldPosts(int count) {
    return 'Old posts: $count items';
  }

  @override
  String get autoDeleteNotice =>
      'Posts will be automatically deleted after 24 hours\nto maintain data freshness';

  @override
  String get deleteOldPostsNow => 'Delete old posts now';

  @override
  String get deletingOldPosts => 'Deleting old posts...';

  @override
  String deleteComplete(int count) {
    return 'Deletion complete! $count fresh posts remaining';
  }

  @override
  String deleteError(String error) {
    return 'Error deleting posts: $error';
  }

  @override
  String generalError(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get viewMap => 'View Map';

  @override
  String get clickToViewImage => 'Click to view image';

  @override
  String get devOnly => 'View Post Statistics (Dev Only)';

  @override
  String get meters => 'm';

  @override
  String get kilometers => 'km';

  @override
  String get reportScreenTitle => 'Report What?';

  @override
  String get selectEventType => 'Select Event Type *';

  @override
  String get detailsField => 'Details *';

  @override
  String get clickToSelectLocation => 'Click to select location';

  @override
  String get willTakeToCurrentLocation =>
      'Will take you to your current location *';

  @override
  String get findingCurrentLocation => 'Finding current location...';

  @override
  String get loadingAddressInfo => 'Loading address information...';

  @override
  String get tapToChangeLocation => 'Tap to change location';

  @override
  String get imageOnlyForLostAnimals =>
      'Images can only be attached for \"Lost Animals\" reports\nto prevent inappropriate content';

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get addImage => 'Add Image (Optional)';

  @override
  String get change => 'Change';

  @override
  String get save => 'Submit';

  @override
  String get sending => 'Sending...';

  @override
  String get securityValidationFailedImage =>
      'Security validation failed. Cannot upload image';

  @override
  String get webpCompression => 'WebP Compression...';

  @override
  String get imageUploadSuccess => 'Image uploaded successfully!';

  @override
  String get cannotProcessImage => 'Cannot process image';

  @override
  String imageSelectionError(String error) {
    return 'Error selecting image: $error';
  }

  @override
  String get securityValidationFailedGeneral =>
      'Security validation failed. Please try again';

  @override
  String pleaseSelectCoordinates(String field) {
    return 'Please select coordinates: $field';
  }

  @override
  String pleaseFillData(String field) {
    return 'Please fill in data: $field';
  }

  @override
  String get eventLocation => 'Event Location';

  @override
  String get userNotFound => 'User not found. Please login again';

  @override
  String get dailyLimitExceeded =>
      'Limit exceeded: 5 posts per day. Please wait 24 hrs';

  @override
  String get cannotGetLocation =>
      'Cannot determine location. Please select location manually';

  @override
  String get success => 'Submitted successfully';

  @override
  String get submitTimeoutError =>
      'Failed to submit report: Timeout. Please check your internet connection';

  @override
  String get submitError => 'Error submitting report';

  @override
  String get networkError => 'Network connection problem. Please check WiFi/4G';

  @override
  String get permissionError =>
      'No upload permission. Please contact system administrator';

  @override
  String get storageError =>
      'File upload problem. Please try sending without image';

  @override
  String get fileSizeError =>
      'Image file too large. Please try taking a new photo';

  @override
  String get persistentError =>
      'If the problem persists, try sending without image';

  @override
  String get tryAgainAction => 'Try Again';

  @override
  String get pleaseSelectEventType => 'Please select event type';

  @override
  String get pleaseFillDetails => 'Please fill in details';

  @override
  String get selectLocation => 'Select Location';

  @override
  String get tapOnMapToSelectLocation => 'Or tap on map to select location';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get addressInformation => 'Address Information';

  @override
  String get roadName => 'Road Name:';

  @override
  String get subDistrict => 'Sub-district:';

  @override
  String get district => 'District:';

  @override
  String get province => 'Province:';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get manualCoordinateEntry => 'Manual coordinate entry';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get apply => 'Apply';

  @override
  String get coordinatesOutOfRange => 'Coordinates must be in valid range';

  @override
  String get invalidCoordinateFormat => 'Invalid coordinate format';

  @override
  String get confirmLocation => 'Confirm Location';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get roadNameHint =>
      'Road name will be displayed automatically or type manually';

  @override
  String get reportComment => 'Report Comment';

  @override
  String get reportCommentConfirm =>
      'Do you want to report this comment as inappropriate?';

  @override
  String get reportCommentSuccess => 'Comment reported successfully';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get beFirstToComment => 'Be the first to comment!';

  @override
  String get addCommentHint => 'Add comment...';

  @override
  String get pleaseEnterComment => 'Please enter a comment';

  @override
  String get commentSentSuccess => 'Comment sent successfully';

  @override
  String get typeCommentHint => 'Type a comment...';

  @override
  String get soundSettingsTitle => 'Sound Alert Settings';

  @override
  String get enableSoundNotifications => 'Enable Sound Notifications';

  @override
  String get enableDisableSoundDesc => 'Enable/Disable all sound alerts';

  @override
  String get selectSoundType => '🔊 Select Sound Alert Type';

  @override
  String get testSound => 'Test Sound';

  @override
  String get soundTips => '💡 Tips';

  @override
  String get soundTipsDescription =>
      '• Voice: Reads text aloud in Thai, provides detailed and clear information\n• Silent: No sound alerts, suitable for quiet places';

  @override
  String get noSoundDescription => 'No sound alerts, completely silent';

  @override
  String get beepSoundDescription => 'Short beep sound (deprecated)';

  @override
  String get warningSoundDescription => 'Siren warning sound (deprecated)';

  @override
  String get ttsSoundDescription => 'Reads text aloud in Thai - Recommended';

  @override
  String get noSoundDisplayName => 'Silent';

  @override
  String get thaiVoiceDisplayName => 'Thai Voice';

  @override
  String testSoundSuccess(String soundType) {
    return 'Test sound: $soundType';
  }

  @override
  String cannotPlaySound(String error) {
    return 'Cannot play sound: $error';
  }

  @override
  String get cameraReportTitle => 'Speed Camera Reports';

  @override
  String get switchToNearbyView => 'Switch to nearby view';

  @override
  String get switchToNationwideView => 'Switch to nationwide view';

  @override
  String get newReportTab => 'New Report';

  @override
  String get votingTab => 'Voting';

  @override
  String get statisticsTab => 'Statistics';

  @override
  String get howToReportTitle => 'How to Report';

  @override
  String get howToReportDescription =>
      '• Report new cameras you encounter\n• Report speed limit changes\n• Data will be verified by the community\n• Once verified, the system will process automatically\n• You cannot vote on your own reports';

  @override
  String get reportSubmittedSuccess =>
      'Report submitted successfully! Check in the voting tab';

  @override
  String get showingNationwidePosts => 'Showing posts from nationwide';

  @override
  String get showingNearbyPosts => 'Showing nearby posts';

  @override
  String radiusKm(int radius) {
    return 'Radius: $radius km';
  }

  @override
  String totalPostsCount(int count) {
    return 'Total posts: $count';
  }

  @override
  String nearbyPostsCount(int count) {
    return 'Nearby posts: $count';
  }

  @override
  String get nearby => 'Nearby';

  @override
  String get nationwide => 'Nationwide';

  @override
  String get loginRequiredToVote => 'Login required to vote';

  @override
  String get loginThroughMapProfile =>
      'Please login through profile on map screen';

  @override
  String get tapProfileButtonOnMap =>
      'Tap the profile button at the top right of the map';

  @override
  String get loadingData => 'Loading data...';

  @override
  String get noPendingReports => 'No reports pending for voting';

  @override
  String get thankYouForVerifying => 'Thank you for helping verify data!';

  @override
  String get voting => 'Voting...';

  @override
  String get voteUpvoteSuccess => 'Vote \"Exists\" submitted successfully';

  @override
  String get voteDownvoteSuccess =>
      'Vote \"Doesn\'t exist\" submitted successfully';

  @override
  String get alreadyVoted => 'You have already voted on this report';

  @override
  String get voteSuccessfullyRecorded =>
      'Vote recorded successfully!\n(System verified that you have voted)';

  @override
  String get noPermissionToVote =>
      'No permission to vote\nTry logging out and logging in again';

  @override
  String get reportNotFound => 'Report not found, may have been deleted';

  @override
  String get connectionProblem =>
      'Connection problem\nPlease check your internet and try again';

  @override
  String get cannotVoteRetry => 'Cannot vote, please try again';

  @override
  String get retry => 'Retry';

  @override
  String get loginRequiredForStats => 'Login required to view statistics';

  @override
  String get contributionScore => 'Contribution Score';

  @override
  String get totalContributions => 'Total Contributions';

  @override
  String get reportsSubmitted => 'Reports Submitted';

  @override
  String get votesGiven => 'Votes Given';

  @override
  String get communityImpact => 'Community Impact';

  @override
  String get communityImpactDescription =>
      'Your participation helps:\n• Speed camera data accuracy\n• Community has up-to-date information\n• Safer driving experience';

  @override
  String get leaderboardAndRewards => 'Leaderboard and special rewards';

  @override
  String get loginThroughMapProfileRequired =>
      'Please login through map profile before voting';

  @override
  String get reportSubmissionSuccess =>
      'Report submitted successfully! Check in voting tab';

  @override
  String errorOccurred(String error) {
    return 'Error occurred: $error';
  }

  @override
  String get showPostsFromNationwide => 'Show posts from nationwide';

  @override
  String get showNearbyPosts => 'Show nearby posts';

  @override
  String radiusAllPosts(int radius, int count) {
    return 'Radius: $radius km. • All posts: $count';
  }

  @override
  String radiusNearbyPosts(int radius, int count) {
    return 'Radius: $radius km. • Nearby posts: $count';
  }

  @override
  String get pleaseLoginThroughMapProfile => 'Please login through map profile';

  @override
  String get tapProfileButtonInMap => 'Tap profile button at top right of map';

  @override
  String get voteExistsSuccess => 'Vote \"Exists\" submitted successfully';

  @override
  String get voteNotExistsSuccess =>
      'Vote \"Doesn\'t exist\" submitted successfully';

  @override
  String get cameraReportFormTitle => 'Speed Camera Report';

  @override
  String get reportTypeLabel => 'Report Type';

  @override
  String get newCameraLocationLabel => 'New Camera Location';

  @override
  String get selectNewCameraLocation => 'Select New Camera Location';

  @override
  String get selectLocationOnMap => 'Please select location on map';

  @override
  String get roadNameLabel => 'Road Name';

  @override
  String get pleaseEnterRoadName => 'Please enter road name';

  @override
  String get speedLimitLabel => 'Speed Limit (km/h)';

  @override
  String get newSpeedLimitLabel => 'New Speed Limit (km/h)';

  @override
  String get additionalDetailsLabel => 'Additional Details';

  @override
  String get selectExistingCameraLabel => 'Select existing camera from system';

  @override
  String get selectedLocationLabel => 'Selected Location';

  @override
  String get tapToSelectLocationOnMap => 'Tap to select location on map';

  @override
  String get locationDetailsLabel => 'Location details and landmarks';

  @override
  String get pleaseProvideLocationDetails =>
      'Please provide location details and landmarks';

  @override
  String get pleaseProvideAtLeast10Characters =>
      'Please provide at least 10 characters';

  @override
  String get reportNewCamera => 'Report New Camera';

  @override
  String get reportRemovedCamera => 'Report Removed Camera';

  @override
  String get reportSpeedChanged => 'Report Speed Limit Changed';

  @override
  String get noLocationDataFound => 'No location data found';

  @override
  String get loginRequiredToViewStats => 'Login required to view statistics';

  @override
  String get securityCheckFailed => 'Security check failed';

  @override
  String get pleaseLoginBeforeVoting =>
      'Please login through map page before voting';

  @override
  String get alreadyVotedDetected =>
      'Vote completed!\n(System detected you have already voted)';

  @override
  String get noVotingPermission =>
      'No voting permission\nTry logout and login again';

  @override
  String get engagementScore => 'Engagement Score';

  @override
  String get totalEngagement => 'Total Engagement';

  @override
  String get voteFor => 'Vote For';

  @override
  String get loadingCameraData => 'Loading camera data...';

  @override
  String get noCameraDataFound => 'No camera data found in system';

  @override
  String get selectedCamera => 'Selected Camera';

  @override
  String get tapToSelectCameraFromMap => 'Tap to select camera from map';

  @override
  String get pleaseSelectCameraFromMap => 'Please select camera from map';

  @override
  String oldSpeedToNewSpeed(int oldSpeed, int newSpeed) {
    return 'Old speed: $oldSpeed km/h → New: $newSpeed km/h';
  }

  @override
  String get locationExampleHint =>
      'e.g. Near Robinson Intersection, In front of school, Opposite gas station, Bridge area';

  @override
  String get pleaseLoginBeforeReportingCamera =>
      'Please login before reporting camera';

  @override
  String coordinatesFormat(String lat, String lng) {
    return 'Latitude: $lat, Longitude: $lng';
  }

  @override
  String get selectCamera => 'Select Camera';

  @override
  String get cannotFindCurrentLocationEnableGPS =>
      'Cannot find current location, please enable GPS';

  @override
  String get select => 'Select';

  @override
  String speedLimitFormat(int limit) {
    return 'Speed limit: $limit km/h';
  }

  @override
  String get confirmSelection => 'Confirm Selection';

  @override
  String get tapCameraIconOnMapToSelect => 'Tap camera icon on map to select';

  @override
  String get cameraNotFoundInSystem => 'Camera data not found in system';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get selectCameraFromMap => 'Select Camera from Map';

  @override
  String get searchingCurrentLocation => 'Searching for current location...';

  @override
  String get foundCurrentLocation => 'Found current location';

  @override
  String get cannotFindLocationUseMap =>
      'Cannot find location, use map to search for cameras instead';

  @override
  String get pleaseAllowLocationAccess =>
      'Please allow location access in app settings';

  @override
  String get showingBangkokMapNormalSearch =>
      'Showing Bangkok map (camera search works normally)';

  @override
  String get selectedCameraInfo => 'Selected Camera';

  @override
  String cameraCode(String code) {
    return 'Code: $code';
  }

  @override
  String speedAndType(int speed, String type) {
    return 'Speed: $speed km/h • $type';
  }

  @override
  String camerasCount(int count) {
    return '$count cameras';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get myReport => 'My Report';

  @override
  String get communityMember => 'Community Member';

  @override
  String get deleteReport => 'Delete Report';

  @override
  String speedLimitDisplay(int speed) {
    return 'Speed limit: $speed km/h';
  }

  @override
  String get viewMapButton => 'View Map';

  @override
  String get viewCameraOnMap => 'View Camera on Map';

  @override
  String viewLocationTitle(String roadName) {
    return 'View Location: $roadName';
  }

  @override
  String get win => 'Win';

  @override
  String get tied => 'Tied 3-3';

  @override
  String needsMoreVotes(int count) {
    return 'Needs $count more votes';
  }

  @override
  String get exists => 'Exists';

  @override
  String get trueVote => 'True';

  @override
  String get doesNotExist => 'Does Not Exist';

  @override
  String get falseVote => 'False';

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String get deleteConfirmMessage =>
      'Do you want to delete this report?\n\nOnce deleted, it cannot be recovered.';

  @override
  String get delete => 'Delete';

  @override
  String get deletingReport => 'Deleting report...';

  @override
  String get reportDeletedSuccess =>
      'Report deleted successfully 🎉 Updating screen...';

  @override
  String get deleteTimeoutError => 'Deletion took too long, please try again';

  @override
  String get newCameraType => '📷 New Camera';

  @override
  String get removedCameraType => '❌ Camera Removed';

  @override
  String get speedChangedType => '⚡ Speed Changed';

  @override
  String get yourReportPending => 'Your Report - Pending Votes';

  @override
  String get alreadyVotedStatus => 'You Have Already Voted';

  @override
  String get pendingReview => 'Pending Review';

  @override
  String get verified => 'Verified';

  @override
  String get rejected => 'Rejected';

  @override
  String get duplicate => 'Duplicate Data';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '$minutes minutes ago';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get locationAccessDenied => 'Location access denied';

  @override
  String get enableLocationInSettings =>
      'Please enable location access in settings';

  @override
  String get speedCameraTitle => 'Speed Camera';

  @override
  String get soundSettingsTooltip => 'Sound Alert Settings';

  @override
  String get loadingDataText => 'Loading data...';

  @override
  String get cannotDetermineLocation => 'Cannot determine location';

  @override
  String get cannotLoadSpeedCameraData => 'Cannot load speed camera data';

  @override
  String get speedLimitText => 'Limit';

  @override
  String predictedCameraAlert(String roadName, int speedLimit) {
    return 'Predicted speed camera in 10 seconds on $roadName limit $speedLimit km/h';
  }

  @override
  String get nearCameraReduceSpeed => 'Near speed camera, please reduce speed';

  @override
  String get nearCameraGoodSpeed => 'Near speed camera, appropriate speed';

  @override
  String cameraAheadDistance(int distance, int speedLimit) {
    return 'Speed camera ahead ${distance}m limit $speedLimit km/h';
  }

  @override
  String get speedCameraBadgeTitle => 'Speed Camera';

  @override
  String get badgeUpdatingCameraData => 'Updating camera data...';

  @override
  String badgeFoundNewCameras(int count) {
    return '🎉 Found $count new community verified cameras!';
  }

  @override
  String get badgeCameraDataUpdated => '✅ Camera data updated successfully';

  @override
  String get badgeCannotUpdateData => '⚠️ Cannot update data';

  @override
  String get badgeSecurityAnomalyDetected =>
      '🔒 System detected abnormal usage';

  @override
  String get badgeSystemBackToNormal => '✅ System back to normal operation';

  @override
  String get badgePredictedCameraAhead => '🔮 Camera detected in 10 seconds';

  @override
  String get badgeNearCameraReduceSpeed =>
      '⚠️ Near camera, please reduce speed';

  @override
  String get badgeNearCameraGoodSpeed => '✅ Near camera, appropriate speed';

  @override
  String badgeExceedingSpeed(int excessSpeed) {
    return '🚨 Exceeding $excessSpeed km/h';
  }

  @override
  String badgeCameraAhead(int distance) {
    return '📍 Camera ahead ${distance}m';
  }

  @override
  String badgeRadarDetection(int distance) {
    return '🔊 Camera radar ${distance}m';
  }

  @override
  String get soundTypeNone => 'Silent';

  @override
  String get soundTypeBeep => 'Real beep sound (not recommended)';

  @override
  String get soundTypeWarning => 'Real warning siren (not recommended)';

  @override
  String get soundTypeTts => 'Thai voice';

  @override
  String ttsDistanceKilometer(String distance) {
    return '$distance kilometers';
  }

  @override
  String ttsDistanceMeter(int distance) {
    return '$distance meters';
  }

  @override
  String ttsCameraDistance(String distance) {
    return 'Speed camera is $distance away from you';
  }

  @override
  String ttsEnteringRoadSpeed(String roadName, int speedLimit) {
    return 'Entering $roadName speed limit $speedLimit kilometers per hour';
  }

  @override
  String get ttsBeep => 'Beep';

  @override
  String get ttsWarning => 'Warning';

  @override
  String get ttsTestVoice => 'Test Thai voice';

  @override
  String get ttsCameraExample =>
      'Speed camera ahead speed limit 90 kilometers per hour';

  @override
  String get noMessage => 'No message';

  @override
  String get other => 'Other';

  @override
  String get report => 'Report';

  @override
  String get error => 'Error occurred';

  @override
  String errorWithDetails(String error) {
    return 'Error occurred: $error';
  }

  @override
  String categoryCount(int count) {
    return 'Category ($count)';
  }

  @override
  String get urgent => 'Urgent';

  @override
  String get listing => 'Listing';

  @override
  String get locationPermissionDenied => 'Location access denied';

  @override
  String get enableLocationPermission =>
      'Please enable location access in settings';

  @override
  String get cannotDetermineCurrentLocation =>
      'Cannot determine current location';

  @override
  String get coordinateValidationError =>
      'Invalid coordinates: Latitude (-90 to 90), Longitude (-180 to 180)';

  @override
  String get invalidCoordinates => 'Invalid coordinate format';

  @override
  String cameraLocation(String roadName) {
    return 'Camera location - $roadName';
  }

  @override
  String get closeButton => 'Close';

  @override
  String get manualCoordinates => 'Enter coordinates manually';

  @override
  String get tapMapToSelect => 'Or tap on map to select location';

  @override
  String get roadNameFieldLabel => 'Road name';

  @override
  String get roadNameHintText =>
      'Road name will be displayed automatically or type manually';

  @override
  String get selectedLocationText => 'Selected location:';

  @override
  String get cameraLocationText => 'Camera location:';

  @override
  String speedLimitInfo(int speedLimit) {
    return 'Speed limit: $speedLimit km/h';
  }

  @override
  String get noDetails => 'No details';

  @override
  String get noLocation => 'No location specified';

  @override
  String get details => 'Details';

  @override
  String get location => 'Location';

  @override
  String get coordinatesLabel => 'Coordinates';

  @override
  String get closeDialog => 'Close';

  @override
  String get removedDetailPage => 'Detail page has been removed';

  @override
  String get viewDetails => 'View Details';

  @override
  String get saveSettingsSuccess => '✅ Settings saved successfully';

  @override
  String saveSettingsError(String error) {
    return '❌ Error occurred: $error';
  }

  @override
  String get testingNotification => '🔔 Testing notification...';

  @override
  String get testNotificationSent => '✅ Test notification sent';

  @override
  String testNotificationError(String error) {
    return '❌ Error testing: $error';
  }

  @override
  String get notificationTitle => 'Notifications';

  @override
  String get saveSettingsTooltip => 'Save settings';

  @override
  String get mainSettingsTitle => '⚙️ Main Settings';

  @override
  String get enableNotificationTitle => 'Enable Notifications';

  @override
  String get enableNotificationSubtitle =>
      'Receive notifications from CheckDarn app';

  @override
  String get notificationTypesTitle => '🔔 Notification Types';

  @override
  String get newEventsTitle => 'New Events';

  @override
  String get newEventsSubtitle =>
      'Notify when new events are reported near you';

  @override
  String get commentsSubtitle => 'Notify when someone comments on your posts';

  @override
  String get systemTitle => 'System';

  @override
  String get systemSubtitle => 'System notifications and updates';

  @override
  String get statusTitle => '📊 Status';

  @override
  String get userTitle => 'User';

  @override
  String get deviceTitle => 'Device';

  @override
  String get deviceConnected => 'Connected';

  @override
  String get notificationDisabled => 'Notifications disabled';

  @override
  String get testTitle => '🧪 Test';

  @override
  String get testNotification => 'Test Notification';

  @override
  String get tipsTitle => '💡 Tips';

  @override
  String get privacySettingTitle => 'Privacy';

  @override
  String get privacySettingSubtitle =>
      'We won\'t notify you when you post yourself';

  @override
  String get batterySavingTitle => 'Battery Saving';

  @override
  String get batterySavingSubtitle =>
      'Turn off unnecessary notifications to save battery';

  @override
  String get loginProcessStarted => '🚀 Starting login process...';

  @override
  String loginSuccessWelcome(String name) {
    return 'Login successful! Welcome $name';
  }

  @override
  String loginFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String get platformDescription =>
      'Event reporting platform\nfor your community';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get loginBenefit =>
      'Signing in allows you to\nreport events and comment';

  @override
  String get welcome => 'Welcome';

  @override
  String get appSlogan => '\"Know First, Survive First, Safe First\"';

  @override
  String get appVersion => 'Version 1.0';

  @override
  String get readyToTest => 'Ready to test';

  @override
  String get alreadyLoggedIn => 'Already logged in';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get testingLogin => 'Testing login...';

  @override
  String get startLoginTest => '🧪 Starting login test...';

  @override
  String loginSuccessEmail(String email) {
    return 'Login successful: $email';
  }

  @override
  String loginSuccessName(String name) {
    return 'Login successful: $name';
  }

  @override
  String get userCancelledLogin => 'User cancelled login';

  @override
  String loginTestFailed(String error) {
    return '❌ Login test failed: $error';
  }

  @override
  String loginFailedGeneral(String error) {
    return 'Login failed: $error';
  }

  @override
  String get loggedOut => 'Logged out';

  @override
  String get logoutSuccess => 'Logout successful';

  @override
  String logoutFailedError(String error) {
    return 'Logout failed: $error';
  }

  @override
  String get loginTestTitle => 'Login Test';

  @override
  String get loginStatusTitle => 'Login Status';

  @override
  String get userDataTitle => 'User Data';

  @override
  String get testingTitle => 'Testing';

  @override
  String get testing => 'Testing...';

  @override
  String get testLogin => 'Test Login';

  @override
  String get logoutButton => 'Logout';

  @override
  String get notesTitle => 'Notes:';

  @override
  String get debugConsole => '• Check Console/Log for debug details';

  @override
  String get checkGoogleServices =>
      '• Check Google Services and Firebase Console';

  @override
  String get checkSHA1 => '• Check SHA-1 fingerprint in Firebase';

  @override
  String get testOnDevice => '• Test on real device, not Emulator';

  @override
  String get simpleTestReady => 'Ready to test';

  @override
  String get simpleTesting => 'Testing...';

  @override
  String get simpleTestStart => '🧪 === Starting login test ===';

  @override
  String authServiceInitialized(bool status) {
    return 'AuthService initialized\nLogin status: $status';
  }

  @override
  String categoryWithCount(int count) {
    return 'Category ($count)';
  }

  @override
  String get urgentReport => 'Urgent';

  @override
  String get listView => 'List';

  @override
  String get postStatisticsTitle => '📊 Post Statistics';

  @override
  String totalPostsWithEmoji(int count) {
    return '📄 Total posts: $count items';
  }

  @override
  String freshPostsWithEmoji(int count) {
    return '✨ Fresh posts (24 hrs): $count items';
  }

  @override
  String oldPostsWithEmoji(int count) {
    return '🗑️ Old posts: $count items';
  }

  @override
  String get autoDeleteInfo =>
      '💡 Posts will be automatically deleted after 24 hours\nto maintain data freshness';

  @override
  String get cleanupOldPosts => '🧹 Delete old posts now';

  @override
  String get cleaningPosts => '🧹 Deleting old posts...';

  @override
  String cleanupComplete(int count) {
    return '✅ Cleanup complete! $count fresh posts remaining';
  }

  @override
  String cleanupError(String error) {
    return 'Error deleting posts: $error';
  }

  @override
  String get postStatisticsTooltip => 'View post statistics';

  @override
  String loadingDataError(String error) {
    return 'Error occurred: $error';
  }

  @override
  String get loadingText => 'Loading data...';

  @override
  String get noReportsTitle => 'No reports yet';

  @override
  String get startReporting => 'Start with your first report';

  @override
  String get reportListTitle => 'Report List';

  @override
  String get unspecifiedLocation => 'Location not specified';

  @override
  String get showComments => 'Show Comments';

  @override
  String eventsInAreaFull(int count) {
    return 'Events in this area ($count items)';
  }

  @override
  String get unspecifiedUser => 'Unspecified';

  @override
  String get unknownUser => 'Anonymous user';

  @override
  String get maskedUserFallback => 'Anonymous user';

  @override
  String loginSuccessWithName(String name) {
    return 'Login successful! Welcome $name';
  }

  @override
  String loginError(String error) {
    return 'Login error: $error';
  }

  @override
  String get logoutSuccessful => 'Logout successful';

  @override
  String logoutError(String error) {
    return 'Logout error: $error';
  }

  @override
  String get loginThroughMapRequired => 'Please login through map profile';

  @override
  String get fallbackOther => 'Other';

  @override
  String get developmentOnly => '(Dev Only)';

  @override
  String get user => 'User';

  @override
  String get defaultUser => 'User';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get roadNamePlaceholder => 'Road name';

  @override
  String get eventLocationLabel => 'Event location';

  @override
  String get unspecified => 'Unspecified';

  @override
  String get securityTimeout => 'Security check timeout';

  @override
  String get locationRequest => '📍 Requesting current location...';

  @override
  String locationReceived(String location) {
    return '✅ Location received: $location';
  }

  @override
  String get cannotGetLocationManual =>
      'Cannot determine location. Please select location manually';

  @override
  String get reportTimeoutWarning =>
      'Report submission timeout. Please check internet connection';

  @override
  String get reportSuccessTitle => 'Success';

  @override
  String get reportTimeoutError =>
      'Failed to submit report: Timeout. Please check your internet connection';
}
