const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

// Sends a notifications to all users when a new message is posted.
exports.sendNotifications = functions.firestore.document('messages/{messagesID}/chat/{messageID}').onCreate(
  async (snapshot) => {
    // Notification details.
    const text = snapshot.data().content;
    const type = snapshot.data().contentType;
    const payload = {
      notification: {
        title: `${snapshot.data().name} posted ${type == 0 ? 'a message' : 'an image'}`,
        body: snapshot.data().contentType == 0 ? text ? (text.length <= 100 ? text : text.substring(0, 97) + '...') : '' : '',
        icon: snapshot.data().profilePicUrl || '/images/profile_placeholder.png',
        priority: 'high',
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        sound: 'default',
        screen: 'message_route',
      }
    };

    // Get the list of device tokens.
    const allTokens = await admin.firestore().collection('fcmTokens').get();
    const tokens = [];
    allTokens.forEach((tokenDoc) => {
      tokens.push(tokenDoc.id);
    });

    if (tokens.length > 0) {
      // Send notifications to all tokens.
      const response = await admin.messaging().sendToDevice(tokens, payload);
      await cleanupTokens(response, tokens);
      console.log('Notifications have been sent and tokens cleaned up.');
    }
  });