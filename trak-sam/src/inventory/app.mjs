import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, DeleteCommand, GetCommand, PutCommand, QueryCommand, TransactWriteCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const INVENTORY_TABLE = process.env.INVENTORY_TABLE;
const USERS_TABLE = process.env.USERS_TABLE;
const STEPS_TABLE = process.env.STEPS_TABLE;
const FRIENDS_TABLE = process.env.FRIENDS_TABLE;

const stepsToPoints = (steps) => Math.floor(steps / 100);

const POINT_DELTA = { powerup: 250, attack: -250 };

const res = (statusCode, body) => ({
  statusCode,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body),
});

const getUserId = (event) => event.requestContext.authorizer.jwt.claims.sub;

async function getInventory(event) {
  const userId = getUserId(event);
  const result = await ddb.send(new QueryCommand({
    TableName: INVENTORY_TABLE,
    KeyConditionExpression: "userId = :uid",
    ExpressionAttributeValues: { ":uid": userId },
  }));
  return res(200, result.Items ?? []);
}

async function useItem(event) {
  const userId = getUserId(event);
  const { itemId, targetUserId } = JSON.parse(event.body || "{}");

  if (!itemId || !targetUserId) {
    return res(400, { message: "itemId and targetUserId are required" });
  }

  const itemResult = await ddb.send(new GetCommand({
    TableName: INVENTORY_TABLE,
    Key: { userId, itemId },
  }));

  if (!itemResult.Item) {
    return res(404, { message: "Item not found" });
  }

  const { type } = itemResult.Item;
  const adjustmentDelta = POINT_DELTA[type];
  if (adjustmentDelta === undefined) {
    return res(400, { message: `Unknown item type: ${type}` });
  }

  if (type === "powerup" && targetUserId !== userId) {
    return res(403, { message: "Powerup items can only be used on yourself" });
  }

  if (type === "attack") {
    const friendCheck = await ddb.send(new GetCommand({
      TableName: FRIENDS_TABLE,
      Key: { userId, friendId: targetUserId },
    }));
    if (!friendCheck.Item) {
      return res(403, { message: "Target must be on your friends list" });
    }
  }

  const today = new Date().toISOString().split("T")[0];
  const now = new Date().toISOString();

  const stepsResult = await ddb.send(new GetCommand({
    TableName: STEPS_TABLE,
    Key: { userId: targetUserId, date: today },
  }));

  const existing = stepsResult.Item;
  const stepCount = existing?.stepCount ?? 0;
  const prevAdjustments = existing?.adjustments ?? 0;
  const prevPoints = existing?.points ?? 0;

  const newAdjustments = prevAdjustments + adjustmentDelta;
  const newPoints = Math.max(0, stepsToPoints(stepCount) + newAdjustments);
  const pointDelta = newPoints - prevPoints;

  await ddb.send(new TransactWriteCommand({
    TransactItems: [
      {
        Delete: {
          TableName: INVENTORY_TABLE,
          Key: { userId, itemId },
        },
      },
      {
        Put: {
          TableName: STEPS_TABLE,
          Item: {
            userId: targetUserId,
            date: today,
            stepCount,
            adjustments: newAdjustments,
            points: newPoints,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          },
        },
      },
      {
        Update: {
          TableName: USERS_TABLE,
          Key: { userId: targetUserId },
          UpdateExpression: "SET points = if_not_exists(points, :zero) + :delta, updatedAt = :now",
          ExpressionAttributeValues: { ":delta": pointDelta, ":zero": 0, ":now": now },
        },
      },
    ],
  }));

  return res(200, { success: true, itemId, targetUserId, pointDelta });
}

// Grants an item to the authenticated user — used for testing / admin seeding
async function grantItem(event) {
  const userId = getUserId(event);
  const { itemId, name, description, type, expiresAt } = JSON.parse(event.body || "{}");

  if (!itemId || !name || !description || !type) {
    return res(400, { message: "itemId, name, description, and type are required" });
  }
  if (!POINT_DELTA.hasOwnProperty(type)) {
    return res(400, { message: `type must be one of: ${Object.keys(POINT_DELTA).join(", ")}` });
  }

  const item = {
    userId,
    itemId,
    name,
    description,
    type,
    expiresAt: expiresAt ?? 253402300800000, // ~year 9999
    createdAt: new Date().toISOString(),
  };

  await ddb.send(new PutCommand({ TableName: INVENTORY_TABLE, Item: item }));
  return res(200, item);
}

export const handler = async (event) => {
  const { method, path } = event.requestContext.http;
  const route = path.replace(/^\/prod/, "");
  try {
    if (method === "GET" && route === "/inventory") return await getInventory(event);
    if (method === "POST" && route === "/inventory/use") return await useItem(event);
    if (method === "POST" && route === "/inventory") return await grantItem(event);
    return res(404, { message: "Not found" });
  } catch (err) {
    console.error(err);
    return res(500, { message: "Internal server error" });
  }
};
