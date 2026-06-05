import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import admin from "firebase-admin";
import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const ssm = new SSMClient({});
const USERS_TABLE = process.env.USERS_TABLE;

let firebaseReady = false;
async function ensureFirebase() {
  if (firebaseReady) return;
  const { Parameter } = await ssm.send(new GetParameterCommand({
    Name: process.env.FIREBASE_PRIVATE_KEY_PARAM,
    WithDecryption: true,
  }));
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: Parameter.Value.replace(/\\n/g, "\n"),
      }),
    });
  }
  firebaseReady = true;
}

async function clearToken(userId) {
  await ddb.send(new UpdateCommand({
    TableName: USERS_TABLE,
    Key: { userId },
    UpdateExpression: "REMOVE fcmToken",
  }));
}

export const handler = async () => {
  await ensureFirebase();

  const result = await ddb.send(new ScanCommand({
    TableName: USERS_TABLE,
    FilterExpression: "attribute_exists(fcmToken)",
    ProjectionExpression: "userId, fcmToken",
  }));

  const users = result.Items ?? [];
  console.log(`Sending step-sync wakeup to ${users.length} devices`);

  await Promise.all(users.map(async ({ userId, fcmToken }) => {
    try {
      await admin.messaging().send({
        token: fcmToken,
        apns: {
          headers: {
            "apns-push-type": "background",
            "apns-priority": "5",
          },
          payload: {
            aps: { "content-available": 1 },
          },
        },
        android: { priority: "normal" },
        data: { type: "step_sync" },
      });
    } catch (err) {
      if (
        err.code === "messaging/registration-token-not-registered" ||
        err.code === "messaging/invalid-registration-token"
      ) {
        await clearToken(userId);
        console.log(`Cleared stale token for ${userId}`);
      } else {
        console.error(`Failed to notify ${userId}:`, err.message);
      }
    }
  }));
};
