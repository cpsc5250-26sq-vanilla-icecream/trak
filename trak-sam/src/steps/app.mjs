import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand, PutCommand, QueryCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const USERS_TABLE = process.env.USERS_TABLE;
const STEPS_TABLE = process.env.STEPS_TABLE;

const POINTS_PER_STEP = 1 / 100; // 100 steps = 1 point

const res = (statusCode, body) => ({
  statusCode,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body),
});

const getUserId = (event) => event.requestContext.authorizer.jwt.claims.sub;
const stepsToPoints = (steps) => Math.floor(steps * POINTS_PER_STEP);

async function submitSteps(event) {
  const userId = getUserId(event);
  const { stepCount, date } = JSON.parse(event.body || "{}");

  if (typeof stepCount !== "number" || stepCount < 0) {
    return res(400, { message: "stepCount must be a non-negative number" });
  }

  const today = date ?? new Date().toISOString().split("T")[0];
  const now = new Date().toISOString();

  const existing = await ddb.send(new GetCommand({ TableName: STEPS_TABLE, Key: { userId, date: today } }));
  const prevPoints = existing.Item ? stepsToPoints(existing.Item.stepCount) : 0;
  const newPoints = stepsToPoints(stepCount);
  const pointDelta = newPoints - prevPoints;

  await ddb.send(new PutCommand({
    TableName: STEPS_TABLE,
    Item: { userId, date: today, stepCount, createdAt: existing.Item?.createdAt ?? now, updatedAt: now },
  }));

  if (pointDelta !== 0) {
    await ddb.send(new UpdateCommand({
      TableName: USERS_TABLE,
      Key: { userId },
      UpdateExpression: "SET points = if_not_exists(points, :zero) + :delta, updatedAt = :now",
      ExpressionAttributeValues: { ":delta": pointDelta, ":zero": 0, ":now": now },
    }));
  }

  return res(200, { userId, date: today, stepCount, points: newPoints });
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
