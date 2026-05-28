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
const todayDate = () => new Date().toISOString().split("T")[0];

async function getTodayLeaderboard(userId) {
  const friendsResult = await ddb.send(new QueryCommand({
    TableName: FRIENDS_TABLE,
    KeyConditionExpression: "userId = :uid",
    ExpressionAttributeValues: { ":uid": userId },
  }));

  const friendIds = (friendsResult.Items ?? []).map((f) => f.friendId);
  const allIds = [userId, ...friendIds];
  const date = todayDate();

  const [stepsResult, usersResult] = await Promise.all([
    ddb.send(new BatchGetCommand({
      RequestItems: {
        [STEPS_TABLE]: { Keys: allIds.map((id) => ({ userId: id, date })) },
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
    .map((id) => ({
      userId: id,
      username: usersMap[id]?.username ?? id,
      displayName: usersMap[id]?.displayName ?? null,
      avatarUrl: usersMap[id]?.avatarUrl ?? null,
      points: stepsMap[id]?.points ?? 0,
    }))
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

  try {
    if (date) {
      const entries = await getHistoricalLeaderboard(userId, date);
      if (!entries) return res(404, { message: "No snapshot available for that date" });
      return res(200, entries);
    }
    return res(200, await getTodayLeaderboard(userId));
  } catch (err) {
    console.error(err);
    return res(500, { message: "Internal server error" });
  }
};
