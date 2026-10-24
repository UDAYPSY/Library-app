const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Task 3.3 — Push Notifications for Fee Due Reminders
 * Runs daily at 09:00 AM IST (03:30 AM UTC) to alert library owners about student fee expiries.
 */
exports.scheduledFeeDueReminder = functions.pubsub
  .schedule('30 3 * * *')
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    const db = admin.firestore();
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStr = tomorrow.toISOString().split('T')[0];

    const librariesSnapshot = await db.collection('libraries').get();

    for (const libDoc of librariesSnapshot.docs) {
      const libraryId = libDoc.id;
      const settingsDoc = await db.doc(`libraries/${libraryId}/settings/profile`).get();
      const fcmToken = settingsDoc.data()?.device_fcm_token;

      if (!fcmToken) continue;

      const studentsSnapshot = await db
        .collection(`libraries/${libraryId}/students`)
        .where('status', 'in', ['ACTIVE', 'DUES'])
        .get();

      const expiringStudents = [];
      studentsSnapshot.forEach((doc) => {
        const data = doc.data();
        if (data.fee_due_date && data.fee_due_date.startsWith(tomorrowStr)) {
          expiringStudents.push(data.name || 'Student');
        }
      });

      if (expiringStudents.length > 0) {
        const message = {
          token: fcmToken,
          notification: {
            title: 'TrackMyLibrary — Expiry Reminder',
            body: `${expiringStudents.length} member(s) fee expires tomorrow: ${expiringStudents.slice(0, 3).join(', ')}${expiringStudents.length > 3 ? '...' : ''}`,
          },
          data: {
            type: 'fee_due_alert',
            count: String(expiringStudents.length),
          },
        };

        try {
          await admin.messaging().send(message);
          console.log(`Sent reminder for library ${libraryId}: ${expiringStudents.length} students`);
        } catch (err) {
          console.error(`Error sending FCM to library ${libraryId}:`, err);
        }
      }
    }
    return null;
  });
