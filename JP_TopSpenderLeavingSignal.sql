WITH
  DateRange AS (
    SELECT
      DATE("2022-08-01") AS startDate,
      DATE("2022-09-30") AS endDate
  )
  ,PrevTopSpender AS (
    SELECT 
      tzDate,
      userID,
      spentRevenue
    FROM `MatomoDataMart.MonthlySpentRevenue`
    WHERE tzDate BETWEEN (SELECT startDate FROM DateRange) AND (SELECT endDate FROM DateRange)
      AND operationRegionGroup = "Japan"
      AND spentRevenue >= 1000
  )
  ,NextSpender AS (
    SELECT 
      tzDate,
      userID,
      spentRevenue
    FROM `MatomoDataMart.MonthlySpentRevenue`
    WHERE tzDate BETWEEN (SELECT startDate FROM DateRange) AND (SELECT endDate FROM DateRange)
      AND operationRegionGroup = "Japan"
  )
  ,TopSpender AS (
    SELECT
      P.tzDate,
      P.userID,
      CASE
        WHEN N.userID IS NULL THEN "Viewer" 
        WHEN N.spentRevenue < 1000 THEN "Regular"
        WHEN N.spentRevenue >= 1000 THEN "Top"
      END AS spenderType_next
    FROM PrevTopSpender AS P
    LEFT JOIN NextSpender AS N
      ON P.userID = N.userID
      AND DATE_DIFF(N.tzDate, P.tzDate, MONTH) = 1
  )
  ,OpenTotal AS (
    SELECT
      DATE_TRUNC(DUB.timezoneDate, MONTH) AS tzDate,
      TS.userID,
      COUNT(DISTINCT DUB.timezoneDate) AS openDays
    FROM TopSpender AS TS
    LEFT JOIN `MatomoDataMart.DailyUserBehavior_ViewRegion` AS DUB
      ON TS.userID = DUB.userID
    WHERE timezoneDate BETWEEN (SELECT startDate FROM DateRange) AND (SELECT endDate FROM DateRange)
      AND operationRegionGroup = "Japan"
    GROUP BY tzDate, userID
  )
SELECT *
FROM OpenTotal
WHERE userID = "8c60fc0e-5cf1-48f4-5bf7-1e7c06c6b19c"
ORDER BY tzDate