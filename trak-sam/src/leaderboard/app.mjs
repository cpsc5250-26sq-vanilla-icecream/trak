import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, BatchGetCommand, GetCommand, QueryCommand } from "@aws-sdk/lib-dynamodb";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const USERS_TABLE = process.env.USERS_TABLE;
const FRIENDS_TABLE = process.env.FRIENDS_TABLE;
const STEPS_TABLE = process.env.STEPS_TABLE;
const SNAPSHOTS_TABLE = process.env.SNAPSHOTS_TABLE;

const res = (statusCode, body) => ({
  statusCode,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body),
});

const getUserId = (event) => event.requestContext.authorizer.jwt.claims.sub;
const todayDate = () => new Date().toLocaleDateString('en-CA', { timeZone: 'America/Los_Angeles' });
const stepsToPoints = (steps) => Math.floor((steps ?? 0) / 100);

function todayResetUtcMs() {
  const now = new Date();
  const todayPst = now.toLocaleDateString('en-CA', { timeZone: 'America/Los_Angeles' });
  const utcMs = Number(new Date(now.toLocaleString('en-US', { timeZone: 'UTC' })));
  const pacMs = Number(new Date(now.toLocaleString('en-US', { timeZone: 'America/Los_Angeles' })));
  return new Date(`${todayPst}T00:00:00Z`).getTime() + (utcMs - pacMs);
}

async function getTodayLeaderboard(userId, date) {
  const friendsResult = await ddb.send(new QueryCommand({
    TableName: FRIENDS_TABLE,
    KeyConditionExpression: "userId = :uid",
    ExpressionAttributeValues: { ":uid": userId },
  }));

  const friendIds = (friendsResult.Items ?? []).map((f) => f.friendId);
  const allIds = [userId, ...friendIds];

  const [stepsResult, usersResult] = await Promise.all([
    ddb.send(new BatchGetCommand({
      RequestItems: {
        [STEPS_TABLE]: { Keys: allIds.map((id) => ({ userId: id, date })), ConsistentRead: true },
      },
    })),
    ddb.send(new BatchGetCommand({
      RequestItems: {
        [USERS_TABLE]: {
          Keys: allIds.map((id) => ({ userId: id })),
          ProjectionExpression: "userId, username, displayName, avatarUrl",
        },
      },
    })),
  ]);

  const stepsMap = Object.fromEntries(
    (stepsResult.Responses?.[STEPS_TABLE] ?? []).map((s) => [s.userId, s])
  );
  const usersMap = Object.fromEntries(
    (usersResult.Responses?.[USERS_TABLE] ?? []).map((u) => [u.userId, u])
  );

  return allIds
    .map((id) => {
      const entry = stepsMap[id];
      const points = entry
        ? Math.max(0, stepsToPoints(entry.stepCount) + (entry.adjustments ?? 0))
        : 0;
      return {
        userId: id,
        username: usersMap[id]?.username || id,
        displayName: usersMap[id]?.displayName || null,
        avatarUrl: usersMap[id]?.avatarUrl ?? null,
        points,
      };
    })
    .sort((a, b) => b.points - a.points)
    .map((u, i) => ({ ...u, rank: i + 1 }));
}

async function getHistoricalLeaderboard(userId, date) {
  const result = await ddb.send(new GetCommand({
    TableName: SNAPSHOTS_TABLE,
    Key: { userId, date },
  }));
  return result.Item?.entries ?? null;
}

export const handler = async (event) => {
  const userId = getUserId(event);
  const date = event.queryStringParameters?.date;
  const today = event.queryStringParameters?.today ?? todayDate();

  try {
    if (date) {
      const entries = await getHistoricalLeaderboard(userId, date);
      if (!entries) return res(404, { message: "No snapshot available for that date" });
      return res(200, entries);
    }
    return res(200, { entries: await getTodayLeaderboard(userId, today), resetTimeUtc: todayResetUtcMs() });
  } catch (err) {
    console.error(err);
    return res(500, { message: "Internal server error" });
  }
};
