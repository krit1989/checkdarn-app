#!/bin/bash

echo "🧪 Testing FCM notification function..."

# สร้าง test report ด้วย Firebase CLI
firebase firestore:create "reports" --data '{
  "userId": "test-user-123",
  "description": "Test FCM 404 fix - using sendEachForMulticast",
  "category": "traffic",
  "lat": 13.7563,
  "lng": 100.5018,
  "location": "Bangkok",
  "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"
}' --project checkdarn-app

echo "📱 Report created! Checking function logs in 5 seconds..."
sleep 5

echo "📋 Function logs:"
firebase functions:log --only sendNewPostNotificationByToken | head -30
