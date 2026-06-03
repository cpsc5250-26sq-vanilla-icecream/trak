import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, BatchGetCommand, DeleteCommand, GetCommand, PutCommand, QueryCommand, TransactWriteCommand } from "@aws-sdk/lib-dynamodb";
import admin from "firebase-admin";
import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const ssm = new SSMClient({});
const USERS_TABLE = process.env.USERS_TABLE;
const FRIENDS_TABLE = process.env.FRIENDS_TABLE;
const FRIEND_REQUESTS_TABLE = process.env.FRIEND_REQUESTS_TABLE;

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

const res = (statusCode, body) => ({
  statusCode,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body),
});

const getUserId = (event) => event.requestContext.authorizer.jwt.claims.sub;

async function sendFriendRequest(event) {
  const userId = getUserId(event);
  const { username } = JSON.parse(event.body || "{}");

  if (!username) return res(400, { message: "username is required" });

  const result = await ddb.send(new QueryCommand({
    TableName: USERS_TABLE,
    IndexName: "username-index",
    KeyConditionExpression: "username = :u",
    ExpressionAttributeValues: { ":u": username },
  }));

  if (!result.Items?.length) return res(404, { message: "User not found" });
  const target = result.Items[0];
  if (target.userId === userId) return res(400, { message: "Cannot add yourself" });

  const [existingFriend, existingRequest, reverseRequest, currentUserResult] = await Promise.all([
    ddb.send(new GetCommand({ TableName: FRIENDS_TABLE, Key: { userId, friendId: target.userId } })),
    ddb.send(new GetCommand({ TableName: FRIEND_REQUESTS_TABLE, Key: { toUserId: target.userId, fromUserId: userId } })),
    ddb.send(new GetCommand({ TableName: FRIEND_REQUESTS_TABLE, Key: { toUserId: userId, fromUserId: target.userId } })),
    ddb.send(new GetCommand({ TableName: USERS_TABLE, Key: { userId } })),
  ]);

  if (existingFriend.Item) return res(409, { message: "Already friends" });
  if (existingRequest.Item) return res(409, { message: "Request already sent" });

  const now = new Date().toISOString();
  const currentUser = currentUserResult.Item ?? {};

  if (reverseRequest.Item) {
    // They already sent us a request — auto-accept both sides
    await ddb.send(new TransactWriteCommand({
      TransactItems: [
        { Put: { TableName: FRIENDS_TABLE, Item: { userId, friendId: target.userId, createdAt: now } } },
        { Put: { TableName: FRIENDS_TABLE, Item: { userId: target.userId, friendId: userId, createdAt: now } } },
        { Delete: { TableName: FRIEND_REQUESTS_TABLE, Key: { toUserId: userId, fromUserId: target.userId } } },
      ],
    }));
    return res(200, { status: "accepted" });
  }

  await ddb.send(new PutCommand({
    TableName: FRIEND_REQUESTS_TABLE,
    Item: {
      toUserId: target.userId,
      fromUserId: userId,
      fromUsername: currentUser.username ?? userId,
      fromDisplayName: currentUser.displayName ?? null,
      fromAvatarUrl: currentUser.avatarUrl ?? null,
      createdAt: now,
    },
  }));
const token = target.fcmToken;

if (token) {
  try {
    await ensureFirebase();
    const senderName =
      currentUser.displayName ??
      currentUser.username ??
      "A user";

    await admin.messaging().send({
      token,
      notification: {
        title: "New Friend Request",
        body: `${senderName} sent you a friend request.`,
      },
    });
  } catch (err) {
    console.error("Failed to send friend request notification", err);
  }
}
  return res(200, { status: "pending" });
}

async function listIncomingRequests(event) {
  const userId = getUserId(event);
  const result = await ddb.send(new QueryCommand({
    TableName: FRIEND_REQUESTS_TABLE,
    KeyConditionExpression: "toUserId = :uid",
    ExpressionAttributeValues: { ":uid": userId },
  }));
  return res(200, result.Items ?? []);
}

async function acceptRequest(event) {
  const userId = getUserId(event);
  const fromUserId = event.pathParameters.fromUserId;

  const requestResult = await ddb.send(new GetCommand({
    TableName: FRIEND_REQUESTS_TABLE,
    Key: { toUserId: userId, fromUserId },
  }));
  if (!requestResult.Item) return res(404, { message: "Friend request not found" });

  const now = new Date().toISOString();
  await ddb.send(new TransactWriteCommand({
    TransactItems: [
      { Put: { TableName: FRIENDS_TABLE, Item: { userId, friendId: fromUserId, createdAt: now } } },
      { Put: { TableName: FRIENDS_TABLE, Item: { userId: fromUserId, friendId: userId, createdAt: now } } },
      { Delete: { TableName: FRIEND_REQUESTS_TABLE, Key: { toUserId: userId, fromUserId } } },
    ],
  }));
 const senderResult = await ddb.send(
    new GetCommand({
      TableName: USERS_TABLE,
      Key: { userId: fromUserId },
    }),
  );

  const token = senderResult.Item?.fcmToken;

  if (token) {
    try {
      await ensureFirebase();
      await admin.messaging().send({
        token,
        notification: {
          title: "Friend Request Accepted",
          body: "Your friend request was accepted.",
        },
      });
    } catch (err) {
      console.error(
        "Failed to send friend accepted notification",
        err,
      );
    }
  }
  return res(200, { message: "Friend request accepted" });
}

async function declineRequest(event) {
  const userId = getUserId(event);
  const fromUserId = event.pathParameters.fromUserId;
  await ddb.send(new DeleteCommand({
    TableName: FRIEND_REQUESTS_TABLE,
    Key: { toUserId: userId, fromUserId },
  }));
  return res(200, { message: "Request declined" });
}

async function removeFriend(event) {
  const userId = getUserId(event);
  const { friendId } = event.pathParameters;
  await ddb.send(new TransactWriteCommand({
    TransactItems: [
      { Delete: { TableName: FRIENDS_TABLE, Key: { userId, friendId } } },
      { Delete: { TableName: FRIENDS_TABLE, Key: { userId: friendId, friendId: userId } } },
    ],
  }));
  return res(200, { message: "Friend removed" });
}

async function listFriends(event) {
  const userId = getUserId(event);
  const result = await ddb.send(new QueryCommand({
    TableName: FRIENDS_TABLE,
    KeyConditionExpression: "userId = :uid",
    ExpressionAttributeValues: { ":uid": userId },
  }));

  const friends = result.Items ?? [];
  if (friends.length === 0) return res(200, []);

  const batchResult = await ddb.send(new BatchGetCommand({
    RequestItems: {
      [USERS_TABLE]: {
        Keys: friends.map((f) => ({ userId: f.friendId })),
        ProjectionExpression: "userId, username, displayName",
      },
    },
  }));

  const userMap = Object.fromEntries(
    (batchResult.Responses?.[USERS_TABLE] ?? []).map((u) => [u.userId, u])
  );

  return res(200, friends.map((f) => ({
    ...f,
    username: userMap[f.friendId]?.username ?? null,
    displayName: userMap[f.friendId]?.displayName || null,
  })));
}

export const handler = async (event) => {
  const { method, path } = event.requestContext.http;
  const route = path.replace(/^\/prod/, "");
  try {
    if (method === "GET" && route === "/friends/requests") return await listIncomingRequests(event);
    if (method === "POST" && route.endsWith("/accept")) return await acceptRequest(event);
    if (method === "DELETE" && route.startsWith("/friends/requests/")) return await declineRequest(event);
    if (method === "POST" && route === "/friends") return await sendFriendRequest(event);
    if (method === "DELETE") return await removeFriend(event);
    if (method === "GET" && route === "/friends") return await listFriends(event);
    return res(404, { message: "Not found" });
  } catch (err) {
    console.error(err);
    return res(500, { message: "Internal server error" });
  }
};
