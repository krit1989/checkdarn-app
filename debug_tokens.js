// Debug script เพื่อตรวจสอบ FCM Tokens
const admin = require('./functions/node_modules/firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'checkdarn-bd46b'
});

async function debugTokens() {
  try {
    console.log('🔍 Debugging FCM Tokens...');
    
    const snapshot = await admin.firestore()
      .collection('user_tokens')
      .limit(5)
      .get();
      
    console.log(`📊 Found ${snapshot.size} user_tokens documents`);
    
    snapshot.docs.forEach((doc, index) => {
      const data = doc.data();
      console.log(`\n📱 User ${index + 1}: ${doc.id}`);
      console.log('   isActive:', data.isActive);
      console.log('   tokens type:', typeof data.tokens);
      console.log('   tokens value:', data.tokens);
      
      if (Array.isArray(data.tokens)) {
        console.log(`   tokens array length: ${data.tokens.length}`);
        data.tokens.forEach((token, i) => {
          console.log(`   token ${i}: ${typeof token} - ${token ? token.substring(0, 30) + '...' : 'null'}`);
        });
      }
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

debugTokens();
