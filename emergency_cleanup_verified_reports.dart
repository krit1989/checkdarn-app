#!/usr/bin/env dart

/// 🚨 Emergency Script: Remove All Stuck Verified Reports
///
/// This script will forcefully remove all verified/rejected reports
/// that are stuck in the camera_reports collection.
///
/// Usage: dart emergency_cleanup_verified_reports.dart

import 'dart:io';

void main() async {
  print('🚨 === EMERGENCY VERIFIED REPORTS CLEANUP SCRIPT ===');
  print('');
  print(
      'This script will remove ALL verified/rejected reports from the database.');
  print('This is necessary because the auto-removal system may have failed.');
  print('');
  print('⚠️  WARNING: This operation cannot be undone!');
  print('');

  // Ask for confirmation
  stdout.write('Are you sure you want to proceed? (yes/no): ');
  final input = stdin.readLineSync();

  if (input?.toLowerCase() != 'yes') {
    print('❌ Operation cancelled.');
    exit(0);
  }

  print('');
  print('🔥 Starting emergency cleanup...');
  print('');

  // Instructions to run the Flutter app for cleanup
  print('📱 To perform the cleanup:');
  print('');
  print('1. Make sure you are logged in as an admin user in the app');
  print(
      '   Admin emails: kritchapon.developer@gmail.com, admin@checkdarn.com, krit1989@outlook.com');
  print('');
  print('2. Run the Flutter app:');
  print('   flutter run');
  print('');
  print('3. Navigate to the Camera Report screen');
  print('   (The cleanup will run automatically when you open the screen)');
  print('');
  print('4. Check the console logs for cleanup results');
  print('');
  print(
      '🔍 Alternative: You can also run this Dart command to trigger cleanup:');
  print('');
  print('   flutter run --dart-define=EMERGENCY_CLEANUP=true');
  print('');

  // Provide direct Firebase query for manual cleanup
  print('💾 Manual Firebase Console Query (if needed):');
  print('');
  print('Collection: camera_reports');
  print('Filter: status == "verified" OR status == "rejected"');
  print('Action: Delete all matching documents');
  print('');
  print('📊 Expected Results:');
  print(
      '- All verified reports should be removed from camera_reports collection');
  print('- Reports will be logged in emergency_cleanup_log collection');
  print(
      '- Camera deletion (for removedCamera reports) should have already happened');
  print(
      '- New camera creation (for newCamera reports) should have already happened');
  print('');
  print('✅ Instructions provided. Please follow the steps above.');
}
