const admin = require('firebase-admin');
const User = require('../models/User');
const path = require('path');

try {
    // Look for the service account file in the backend root
    // The user needs to provide this file
    const serviceAccount = require('../firebase-service-account.json');

    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin Initialized');
} catch (error) {
    console.error('CRITICAL: Firebase Admin could not be initialized.');
    console.error('Error Details:', error.message);
    console.warn('Push notifications will be DISABLED until "firebase-service-account.json" is added to the backend folder.');
}

const sendPushNotification = async (userId, title, body) => {
    try {
        const user = await User.findById(userId);
        if (!user || !user.fcmToken) {
            return;
        }

        const message = {
            notification: {
                title: title,
                body: body
            },
            token: user.fcmToken
        };

        const response = await admin.messaging().send(message);
        console.log('Successfully sent push notification:', response);
    } catch (error) {
        console.error('Error sending push notification:', error);
    }
};

module.exports = { sendPushNotification };
