import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, BatchGetCommand, QueryCommand } from "@aws-sdk/lib-dynamodb";

const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
const USERS_TABLE = process.env.USERS_TABLE;
const FRIENDS_TABLE = process.env.FRIENDS_TABLE;

const res = (statusCode, body) => ({
  statusCode,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(body),
});

const getUserId = (event) => event.requestContext.authorizer.jwt.claims.sub;

export const handler = async (event) => {
  const userId = getUserId(event);

  try {
    const friendsResult = await ddb.send(new QueryCommand({
      TableName: FRIENDS_TABLE,
      KeyConditionExpression: "userId = :uid",
      ExpressionAttributeValues: { ":uid": userId },
    }));

    const friendIds = (friendsResult.Items ?? []).map((f) => f.friendId);
    const allIds = [userId, ...friendIds];

    const usersResult = await ddb.send(new BatchGetCommand({
      RequestItems: {
        [USERS_TABLE]: {
          Keys: allIds.map((id) => ({ userId: id })),
          ProjectionExpression: "userId, username, displayName, avatarUrl, points",
        },
      },
    }));

    const ranked = (usersResult.Responses?.[USERS_TABLE] ?? [])
      .sort((a, b) => (b.points ?? 0) - (a.points ?? 0))
      .map((u, i) => ({ rank: i + 1, ...u }));

    return res(200, ranked);
  } catch (err) {
    console.error(err);
    return res(500, { message: "Internal server error" });
  }
};
