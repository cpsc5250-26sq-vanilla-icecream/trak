import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, BatchGetCommand, BatchWriteCommand, QueryCommand, ScanCommand } from "@aws-sdk/lib-dynamodb";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const USERS_TABLE = process.env.USERS_TABLE;
const FRIENDS_TABLE = process.env.FRIENDS_TABLE;
const STEPS_TABLE = process.env.STEPS_TABLE;
const SNAPSHOTS_TABLE = process.env.SNAPSHOTS_TABLE;

function yesterdayDate() {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() - 1);
  return d.toISOString().split("T")[0];
}

export const handler = async () => {
  const date = yesterdayDate();
  const now = new Date().toISOString();

  // Find all users who have at least one friend
  const scan = await ddb.send(new ScanCommand({
    TableName: FRIENDS_TABLE,
    ProjectionExpression: "userId",
  }));

  const userIds = [...new Set((scan.Items ?? []).map((f) => f.userId))];
  console.log(`Snapshotting leaderboard for ${userIds.length} users, date ${date}`);

  for (const userId of userIds) {
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

    const entries = allIds
      .map((id) => ({
        userId: id,
        username: usersMap[id]?.username ?? id,
        displayName: usersMap[id]?.displayName ?? null,
        avatarUrl: usersMap[id]?.avatarUrl ?? null,
        points: stepsMap[id]?.points ?? 0,
      }))
      .sort((a, b) => b.points - a.points)
      .map((u, i) => ({ ...u, rank: i + 1 }));

    await ddb.send(new BatchWriteCommand({
      RequestItems: {
        [SNAPSHOTS_TABLE]: [{
          PutRequest: {
            Item: { userId, date, entries, createdAt: now },
          },
        }],
      },
    }));
  }
};
