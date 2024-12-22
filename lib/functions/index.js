const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Notify all available workers of a new job request.
 */
exports.notifyWorkersOfJobRequest = functions.firestore
  .document("jobs/{jobId}")
  .onCreate(async (snap, context) => {
    const jobData = snap.data();

    // Only notify if the job status is 'pending'
    if (jobData.status === "pending") {
      try {
        // Fetch all available workers
        const workersSnapshot = await admin
          .firestore()
          .collection("users")
          .where("role", "==", "worker")
          .where("isAvailable", "==", true)
          .get();

        // Collect FCM tokens of workers
        const tokens = [];
        workersSnapshot.forEach((doc) => {
          const workerData = doc.data();
          if (workerData.fcmToken) {
            tokens.push(workerData.fcmToken);
          }
        });

        // Send notifications if there are tokens
        if (tokens.length > 0) {
          const payload = {
            notification: {
              title: "New Job Request",
              body: `A new job is available at location: ${jobData.location.latitude}, ${jobData.location.longitude}`,
            },
          };

          await admin.messaging().sendToDevice(tokens, payload);
          console.log(`Notifications sent to ${tokens.length} workers.`);
        } else {
          console.log("No available workers with FCM tokens.");
        }
      } catch (error) {
        console.error("Error notifying workers of job request:", error);
      }
    }
  });

/**
 * Notify the customer of a job status update.
 */
exports.notifyCustomerOfJobStatus = functions.firestore
  .document("jobs/{jobId}")
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const prevData = change.before.data();

    // Only notify if the job status has changed
    if (newData.status !== prevData.status) {
      try {
        // Fetch the customer details
        const customerDoc = await admin
          .firestore()
          .collection("users")
          .doc(newData.customerId)
          .get();

        if (customerDoc.exists) {
          const customerData = customerDoc.data();

          // Check if the customer has an FCM token
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
        console.error("Error notifying customer of job status:", error);
      }
    }
  });
