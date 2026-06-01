import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand, PutCommand, QueryCommand } from "@aws-sdk/lib-dynamodb";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const STEPS_TABLE = process.env.STEPS_TABLE;
const INVENTORY_TABLE = process.env.INVENTORY_TABLE;

const POINTS_PER_STEP = 1 / 100; // 100 steps = 1 point

const res = (statusCode, body) => ({
  statusCode,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body),
});

const getUserId = (event) => event.requestContext.authorizer.jwt.claims.sub;
const stepsToPoints = (steps) => Math.floor(steps * POINTS_PER_STEP);

function endOfDayMs() {
  const d = new Date();
  d.setUTCHours(23, 59, 59, 999);
  return d.getTime();
}

function generateItem(userId) {
  const type = Math.random() < 0.5 ? "powerup" : "attack";
  return {
    userId,
    itemId: `${type}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    name: type === "powerup" ? "Point Boost" : "Point Drain",
    description: type === "powerup"
      ? "Boost your points by 7."
      : "Drain a friend's points by 7.",
    type,
    expiresAt: endOfDayMs(),
    createdAt: new Date().toISOString(),
  };
}

async function submitSteps(event) {
  const userId = getUserId(event);
  const { stepCount, date } = JSON.parse(event.body || "{}");

  if (typeof stepCount !== "number" || stepCount < 0) {
    return res(400, { message: "stepCount must be a non-negative number" });
  }

  const today = date ?? new Date().toISOString().split("T")[0];
  const now = new Date().toISOString();

  const existing = await ddb.send(new GetCommand({ TableName: STEPS_TABLE, Key: { userId, date: today } }));
  const prevStepCount = existing.Item?.stepCount ?? 0;
  const resolvedStepCount = Math.max(stepCount, prevStepCount);
  const adjustments = existing.Item?.adjustments ?? 0;
  const newPoints = Math.max(0, stepsToPoints(resolvedStepCount) + adjustments);

  await ddb.send(new PutCommand({
    TableName: STEPS_TABLE,
    Item: { userId, date: today, stepCount: resolvedStepCount, adjustments, points: newPoints, createdAt: existing.Item?.createdAt ?? now, updatedAt: now },
  }));

  const prevMilestone = Math.floor(prevStepCount / 1000);
  const newMilestone = Math.floor(resolvedStepCount / 1000);
  for (let i = prevMilestone + 1; i <= newMilestone; i++) {
    if (Math.random() < 0.5) {
      await ddb.send(new PutCommand({ TableName: INVENTORY_TABLE, Item: generateItem(userId) }));
    }
  }

  return res(200, { userId, date: today, stepCount, adjustments, points: newPoints });
}

async function getSteps(event) {
  const userId = getUserId(event);
  const limit = Math.min(parseInt(event.queryStringParameters?.limit ?? "7"), 30);

  const result = await ddb.send(new QueryCommand({
    TableName: STEPS_TABLE,
    KeyConditionExpression: "userId = :uid",
    ExpressionAttributeValues: { ":uid": userId },
    ScanIndexForward: false,
    Limit: limit,
  }));

  return res(200, result.Items ?? []);
}

export const handler = async (event) => {
  const { method } = event.requestContext.http;
  try {
    if (method === "POST") return await submitSteps(event);
    if (method === "GET") return await getSteps(event);
    return res(404, { message: "Not found" });
  } catch (err) {
    console.error(err);
    return res(500, { message: "Internal server error" });
  }
};
