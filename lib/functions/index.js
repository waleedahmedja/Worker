const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const USERS_COLLECTION = "users";
const JOBS_COLLECTION = "jobs";

/**
 * Notify all available workers of a new job request.
 */
exports.notifyWorkersOfJobRequest = functions.firestore
  .document(`${JOBS_COLLECTION}/{jobId}`)
  .onCreate(async (snap, context) => {
    const jobData = snap.data();

    if (jobData.status === "pending") {
      try {
        const tokens = [];
        let lastDoc = null;

        // Fetch available workers with pagination
        do {
          let query = admin.firestore()
            .collection(USERS_COLLECTION)
            .where("role", "==", "worker")
            .where("isAvailable", "==", true)
            .limit(500);

          if (lastDoc) {
            query = query.startAfter(lastDoc);
          }

          const snapshot = await query.get();
          snapshot.forEach((doc) => {
            const workerData = doc.data();
            if (workerData.fcmToken) tokens.push(workerData.fcmToken);
          });

          lastDoc = snapshot.docs[snapshot.docs.length - 1];
        } while (lastDoc);

        // Send notifications to workers
        if (tokens.length > 0) {
          const payload = {
            notification: {
              title: "New Job Request",
              body: `A new job is available at ${jobData.location.latitude}, ${jobData.location.longitude}.`,
            },
          };

          const response = await admin.messaging().sendMulticast({
            tokens,
            ...payload,
          });

          console.log(`Notifications sent: ${response.successCount}/${tokens.length}`);
        } else {
          console.log("No workers available with FCM tokens.");
        }
      } catch (error) {
        console.error("Error notifying workers:", error);
      }
    }
  });

/**
 * Notify the customer of a job status update.
 */
exports.notifyCustomerOfJobStatus = functions.firestore
  .document(`${JOBS_COLLECTION}/{jobId}`)
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const prevData = change.before.data();

    if (newData.status !== prevData.status) {
      try {
        const customerDoc = await admin
          .firestore()
          .collection(USERS_COLLECTION)
          .doc(newData.customerId)
          .get();

        if (customerDoc.exists) {
          const customerData = customerDoc.data();

          if (customerData.fcmToken) {
            const payload = {
              notification: {
                title: "Job Status Update",
                body: `Your job is now ${newData.status}.`,
              },
            };

            await admin.messaging().sendToDevice(customerData.fcmToken, payload);
            console.log(`Notification sent to customer: ${newData.customerId}`);
          } else {
            console.log("Customer does not have an FCM token.");
          }
        } else {
          console.log("Customer document does not exist.");
        }
      } catch (error) {
        console.error("Error notifying customer:", error);
      }
    }
  });
