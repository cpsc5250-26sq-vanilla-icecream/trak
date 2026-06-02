import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand, PutCommand, QueryCommand } from "@aws-sdk/lib-dynamodb";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const s3 = new S3Client({});
const USERS_TABLE = process.env.USERS_TABLE;
const AVATARS_BUCKET = process.env.AVATARS_BUCKET;

const res = (statusCode, body) => ({
  statusCode,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body),
});

const getUserId = (event) => event.requestContext.authorizer.jwt.claims.sub;

async function upsertUser(event) {
  const userId = getUserId(event);
  const { username, displayName, avatarUrl, colorScheme, font } = JSON.parse(event.body || "{}");

  if (username) {
    const hit = await ddb.send(new QueryCommand({
      TableName: USERS_TABLE,
      IndexName: "username-index",
      KeyConditionExpression: "username = :u",
      ExpressionAttributeValues: { ":u": username },
    }));
    if (hit.Items?.length && hit.Items[0].userId !== userId) {
      return res(409, { message: "Username already taken" });
    }
  }

  const now = new Date().toISOString();
  const existing = await ddb.send(new GetCommand({ TableName: USERS_TABLE, Key: { userId } }));
  const prev = existing.Item ?? {};

  const resolvedUsername = username ?? prev.username;
  const resolvedAvatarUrl = avatarUrl ?? prev.avatarUrl;
  const resolvedDisplayName = displayName ?? prev.displayName;

  const user = {
    userId,
    ...(resolvedUsername && { username: resolvedUsername }),
    ...(resolvedAvatarUrl && { avatarUrl: resolvedAvatarUrl }),
    ...(resolvedDisplayName && { displayName: resolvedDisplayName }),
    colorScheme: colorScheme ?? prev.colorScheme ?? "default",
    font: font ?? prev.font ?? "default",
    createdAt: prev.createdAt ?? now,
    updatedAt: now,
  };

  await ddb.send(new PutCommand({ TableName: USERS_TABLE, Item: user }));
  return res(200, user);
}

async function getMe(event) {
  const userId = getUserId(event);
  const result = await ddb.send(new GetCommand({ TableName: USERS_TABLE, Key: { userId } }));
  if (!result.Item) return res(404, { message: "User not found" });
  return res(200, result.Item);
}

async function getAvatarUploadUrl(event) {
  const userId = getUserId(event);
  const { contentType = "image/jpeg" } = JSON.parse(event.body || "{}");
  const ext = contentType.split("/")[1] || "jpg";
  const key = `avatars/${userId}/${Date.now()}.${ext}`;

  const command = new PutObjectCommand({
    Bucket: AVATARS_BUCKET,
    Key: key,
    ContentType: contentType,
  });

  const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 300 });
  const publicUrl = `https://${AVATARS_BUCKET}.s3.amazonaws.com/${key}`;

  return res(200, { uploadUrl, publicUrl, contentType });
}

async function getUser(event) {
  const { userId } = event.pathParameters;
  const result = await ddb.send(new GetCommand({ TableName: USERS_TABLE, Key: { userId } }));
  if (!result.Item) return res(404, { message: "User not found" });
  const { userId: id, username, displayName, avatarUrl, colorScheme, font } = result.Item;
  return res(200, { userId: id, username, displayName, avatarUrl, colorScheme, font });
}

export const handler = async (event) => {
  const { method, path } = event.requestContext.http;
  const route = path.replace(/^\/prod/, "");
  try {
    if (method === "POST" && route === "/users") return await upsertUser(event);
    if (method === "POST" && route === "/users/avatar") return await getAvatarUploadUrl(event);
    if (method === "GET" && route === "/users/me") return await getMe(event);
    if (method === "GET") return await getUser(event);
    return res(404, { message: "Not found" });
  } catch (err) {
    console.error(err);
    return res(500, { message: "Internal server error" });
  }
};
