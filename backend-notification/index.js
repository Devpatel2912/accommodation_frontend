const admin = require('firebase-admin');
const express = require('express');
const bodyParser = require('body-parser');

// Initialize Firebase Admin
// Replace './serviceAccountKey.json' with the path to your service account key file
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const app = express();
app.use(bodyParser.json());

/**
 * Send notification to a specific topic
 * Body: { topic, title, body, data }
 */
app.post('/send-to-topic', async (req, res) => {
  const { topic, title, body, data } = req.body;

  if (!topic || !title || !body) {
    return res.status(400).send({ error: 'Missing required fields: topic, title, body' });
  }

  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: data || {}, // Optional data payload
    topic: topic,
    android: {
      priority: 'high',
      ttl: 86400 * 1000,
      notification: {
        channel_id: 'high_importance_channel',
        priority: 'max',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        visibility: 'public',
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    res.status(200).send({ success: true, messageId: response });
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).send({ error: error.message });
  }
});

/**
 * Use Case: Room Allocation Notification
 */
app.post('/notify-allocation', async (req, res) => {
  const { userId, roomNumber, houseName } = req.body;

  const topic = `user_${userId}`; // Example: user subscribes to their own ID topic
  const title = 'Room Allocated!';
  const body = `You have been allocated to Room ${roomNumber} in ${houseName}.`;

  const message = {
    notification: { title, body },
    data: {
      type: 'ALLOCATION',
      roomNumber: roomNumber.toString(),
      houseName
    },
    topic: topic,
    android: {
      notification: {
        channel_id: 'high_importance_channel',
        priority: 'high',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      }
    }
  };

  try {
    await admin.messaging().send(message);
    res.status(200).send({ success: true });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

/**
 * Use Case: Admin Announcement
 */
app.post('/admin-announcement', async (req, res) => {
  const { title, body } = req.body;

  const message = {
    notification: { title, body },
    topic: 'all_users',
    android: {
      notification: {
        channel_id: 'high_importance_channel',
        priority: 'high',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      }
    }
  };

  try {
    await admin.messaging().send(message);
    res.status(200).send({ success: true });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => {
  console.log(`Notification server running on port ${PORT}`);
});
