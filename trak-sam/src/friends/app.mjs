import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, BatchGetCommand, DeleteCommand, PutCommand, QueryCommand } from "@aws-sdk/lib-dynamodb";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const USERS_TABLE = process.env.USERS_TABLE;
const FRIENDS_TABLE = process.env.FRIENDS_TABLE;

const res = (statusCode, body) => ({
  statusCode,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body),
});

const getUserId = (event) => event.requestContext.authorizer.jwt.claims.sub;

async function addFriend(event) {
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
  const friend = result.Items[0];
  if (friend.userId === userId) return res(400, { message: "Cannot add yourself" });

  await ddb.send(new PutCommand({
    TableName: FRIENDS_TABLE,
    Item: { userId, friendId: friend.userId, createdAt: new Date().toISOString() },
  }));

  return res(200, { friendId: friend.userId, username: friend.username, displayName: friend.displayName });
}

async function removeFriend(event) {
  const userId = getUserId(event);
  const { friendId } = event.pathParameters;
  await ddb.send(new DeleteCommand({ TableName: FRIENDS_TABLE, Key: { userId, friendId } }));
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

  const enriched = friends.map((f) => {
    const user = userMap[f.friendId];
    return {
      ...f,
      username: user?.username ?? null,
      displayName: user?.displayName ?? null,
    };
  });

  return res(200, enriched);
}

export const handler = async (event) => {
  const { method, path } = event.requestContext.http;
  const route = path.replace(/^\/prod/, "");
  try {
    if (method === "POST" && route === "/friends") return await addFriend(event);
    if (method === "DELETE") return await removeFriend(event);
    if (method === "GET" && route === "/friends") return await listFriends(event);
    return res(404, { message: "Not found" });
  } catch (err) {
    console.error(err);
    return res(500, { message: "Internal server error" });
  }
};
