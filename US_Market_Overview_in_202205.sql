-- US Market Overview in 202205
-- MAS Profile
-- Gender
SELECT 
  UD.profile.gender
  ,COUNT(DISTINCT LS.streamerID)
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
LEFT JOIN `media17-1119.MatomoCore.dim_userdimension` AS UD
  ON LS.streamerID = UD.userID
WHERE LS.streamer.operationRegionGroup = 'United States'
  AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
GROUP BY LS.gender

-- Age
SELECT 
  CASE
    WHEN U.age <=0 THEN '<=0'
    WHEN U.age BETWEEN 1 AND 10 THEN '1~10'
    WHEN U.age BETWEEN 11 AND 20 THEN '11~20'
    WHEN U.age BETWEEN 21 AND 30 THEN '21~30'
    WHEN U.age BETWEEN 31 AND 40 THEN '31~40'
    WHEN U.age BETWEEN 41 AND 50 THEN '41~50'
    WHEN U.age BETWEEN 51 AND 60 THEN '51~60'
    WHEN U.age BETWEEN 61 AND 70 THEN '61~70'
    WHEN U.age BETWEEN 71 AND 80 THEN '71~80'
    WHEN U.age >= 81 THEN '>=81'
  END AS ageGroup
  ,COUNT(DISTINCT LS.streamerID) AS counts
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
LEFT JOIN `media17-1119.mongodb.User` AS U
  ON LS.streamerID = U.userID
WHERE LS.streamer.operationRegionGroup = 'United States'
  AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
GROUP BY ageGroup

-- Register country
SELECT 
  LS.streamer.registerCountry AS registerCountry
  ,COUNT(DISTINCT LS.streamerID) AS Counts
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
WHERE LS.streamer.operationRegionGroup = 'United States'
  AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
GROUP BY registerCountry
ORDER BY Counts DESC

-- Contract status
SELECT 
  LS.streamer.contractStatus AS contractStatus
  ,COUNT(DISTINCT LS.streamerID) AS Counts
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
WHERE LS.streamer.operationRegionGroup = 'United States'
  AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
GROUP BY contractStatus

-- Stream mode
SELECT 
  LS.stream.streamMode AS streamMode
  ,COUNT(DISTINCT LS.streamerID) AS Counts
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
WHERE LS.streamer.operationRegionGroup = 'United States'
  AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
GROUP BY streamMode

-- Content type
SELECT 
  IFNULL(T.en_us, subtab) AS contentType
  ,COUNT(DISTINCT LS.streamerID) AS Counts
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
  ,UNNEST(LS.stream.subtab) AS subtab
LEFT JOIN `media17-1119.MatomoCore.SubtabTranslation` AS T
  ON subtab = T.ID
WHERE LS.streamer.operationRegionGroup = 'United States'
  AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
GROUP BY contentType

-- MAS revenue contribution
WITH
  Event AS(
    SELECT
      giftID,
      ARRAY_AGG(STRUCT(eventID, startTime, endTime)) AS eventInfo
    FROM
      `media17-1119.MatomoCore.dim_event`
    WHERE
      giftID IS NOT NULL
      AND giftID != ''
    GROUP BY
      giftID
  ),
  Income AS (
    SELECT
      PUI.receive_user_id AS streamerID,
      PUI.receiverOpenID AS streamerOpenID,
      SUM(PUI.receive_point) AS monthlyReceivedPoints,
      SUM(PUI.listPurchaseIncome) AS monthlyReceivedRevenue,
      CASE 
        WHEN SUM(PUI.receive_point) >= 2500000 THEN 'Top'
        WHEN SUM(PUI.receive_point) BETWEEN 80000 AND 2499999 THEN 'Mid-tier'
        ELSE 'Standard'
      END AS streamerGroup
    FROM
      `media17-1119.MatomoCore.fact_usage` AS PUI
    LEFT JOIN Event
      ON Event.giftID = PUI.giftID
    WHERE
      DATE(PUI.timestamp_utc, PUI.receiver_inferStreamerTimezone) BETWEEN '2022-05-01' AND '2022-05-31'
      AND PUI.receiver_inferStreamerRegionGroup = 'United States'
      AND PUI.giftID NOT IN (
        'expiredPaidGiftID',
        'expiredFreeGiftID',
        'system_recycle',
        'system_cancel_order',
        'system_no_reason_recycle'
      )
      -- Receive Revenue Remove GamePool lose(user win) usage and GamePool bet usage
      AND NOT (
        PUI.user_id IN ('016a2c96-1d1d-4530-97d7-fb3e9866bc7e')
        AND PUI.giftID IN (
          'fruit_farm_gpool_lose_points'
        )
      )
      AND NOT (
        PUI.receive_user_id IN ('016a2c96-1d1d-4530-97d7-fb3e9866bc7e')
        AND PUI.giftID IN (
          'fruit_farm_user_bet_points'
        )
      )
    GROUP BY
      streamerID
      ,streamerOpenID
  )

-- Below section can be run one by one with CTEs above
-- Revenue Contribution
SELECT 
  streamerGroup
  ,COUNT(DISTINCT streamerID) AS counts
  ,SUM(monthlyReceivedPoints) AS receivedPoints
  ,SUM(monthlyReceivedRevenue) AS grossRevenue
FROM Income
GROUP BY streamerGroup

-- Viewer gender
SELECT 
  Income.streamerGroup AS streamerGroup
  ,UD.profile.gender AS gender
  ,COUNT(DISTINCT LS.viewer.userID) AS counts
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
INNER JOIN Income
  USING(streamerID)
LEFT JOIN `media17-1119.MatomoCore.dim_userdimension` AS UD
  ON LS.viewer.userID = UD.userID
WHERE LS.streamer.operationRegionGroup = 'United States'
  AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
GROUP BY streamerGroup, gender

-- Viewer operation region group
SELECT 
  Income.streamerGroup AS streamerGroup
  ,LS.viewer.operationRegionGroup AS viewerRegion
  ,COUNT(DISTINCT LS.viewer.userID) AS Counts
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
INNER JOIN Income
  USING(streamerID)
WHERE LS.streamer.operationRegionGroup = 'United States'
  AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
GROUP BY streamerGroup, viewerRegion

-- Viewer attribution type
SELECT 
  Income.streamerGroup AS streamerGroup
  ,LS.viewer.attributionType AS attributionType
  ,COUNT(DISTINCT LS.viewer.userID) AS Counts
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
INNER JOIN Income
  USING(streamerID)
WHERE LS.streamer.operationRegionGroup = 'United States'
  AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
GROUP BY streamerGroup, attributionType

-- What other contries do viewers of top streamers watches?
  ,ViewerList AS (
    SELECT DISTINCT
      LS.viewer.userID
    FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
    WHERE LS.streamer.operationRegionGroup = 'United States'
      AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
      -- Select one top streamer ID
      AND LS.streamerID = '64929430-6308-479e-89c3-f402d3d8a618'
  )
SELECT
  LS.streamer.operationRegionGroup AS operationRegionGroup
  ,COUNT(DISTINCT LS.viewer.userID) AS counts
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
WHERE DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
  AND LS.viewer.userID IN (
    SELECT *
    FROM ViewerList
  )
GROUP BY operationRegionGroup

-- MAU profile
-- USer gender
SELECT 
  UD.profile.gender AS gender
  ,COUNT(DISTINCT DUB.userID) AS counts
FROM `media17-1119.MatomoDataMart.DailyUserBehavior` AS DUB
LEFT JOIN `media17-1119.MatomoCore.dim_userdimension` AS UD
  ON DUB.userID = UD.userID
WHERE DUB.timezoneDate BETWEEN '2022-05-01' AND '2022-05-31'
  AND DUB.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
GROUP BY gender

-- User age
SELECT 
  CASE
    WHEN U.age <=0 THEN '<=0'
    WHEN U.age BETWEEN 1 AND 10 THEN '1~10'
    WHEN U.age BETWEEN 11 AND 20 THEN '11~20'
    WHEN U.age BETWEEN 21 AND 30 THEN '21~30'
    WHEN U.age BETWEEN 31 AND 40 THEN '31~40'
    WHEN U.age BETWEEN 41 AND 50 THEN '41~50'
    WHEN U.age BETWEEN 51 AND 60 THEN '51~60'
    WHEN U.age BETWEEN 61 AND 70 THEN '61~70'
    WHEN U.age BETWEEN 71 AND 80 THEN '71~80'
    WHEN U.age >= 81 THEN '>=81'
  END AS ageGroup
  ,COUNT(DISTINCT DUB.userID) AS counts
FROM `media17-1119.MatomoDataMart.DailyUserBehavior` AS DUB
LEFT JOIN `media17-1119.mongodb.User` AS U
  ON DUB.userID = U.userID
WHERE DUB.timezoneDate BETWEEN '2022-05-01' AND '2022-05-31'
  AND DUB.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
GROUP BY ageGroup

-- User register country
SELECT 
  DUB.registerCountry AS registerCountry
  ,COUNT(DISTINCT DUB.userID) AS counts
FROM `media17-1119.MatomoDataMart.DailyUserBehavior` AS DUB
WHERE DUB.timezoneDate BETWEEN '2022-05-01' AND '2022-05-31'
  AND DUB.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
GROUP BY registerCountry
ORDER BY Counts DESC

-- User attribution type
SELECT 
  DUB.attributionType AS attributionType
  ,COUNT(DISTINCT DUB.userID) AS counts
FROM `media17-1119.MatomoDataMart.DailyUserBehavior` AS DUB
WHERE DUB.timezoneDate BETWEEN '2022-05-01' AND '2022-05-31'
  AND DUB.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
GROUP BY attributionType
ORDER BY Counts DESC

-- User actions
SELECT
  viewOrNot
  ,COUNT(DISTINCT userID) AS counts
FROM (
  SELECT DUB.userID, LOGICAL_OR(DUB.view.duration IS NOT NULL) AS viewOrNot
  FROM `media17-1119.MatomoDataMart.DailyUserBehavior` AS DUB
  WHERE DUB.timezoneDate BETWEEN '2022-05-01' AND '2022-05-31'
    AND DUB.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
  GROUP BY userID
  ) AS t
GROUP BY viewOrNot

-- Streamer country
SELECT 
  LS.streamer.operationRegionGroup AS streamerCountry
  ,COUNT(DISTINCT LS.viewer.userID) AS counts
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
WHERE LS.viewer.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
  AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
  AND LS.viewer.userID IN (
    SELECT DISTINCT DUB.userID
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior` AS DUB
    WHERE DUB.timezoneDate BETWEEN '2022-05-01' AND '2022-05-31'
      AND DUB.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
      AND DUB.view.duration IS NOT NULL
  ) 
GROUP BY streamerCountry

-- Viewer wathcing stream mode
SELECT
  streamMode
  ,COUNT(userID) AS counts
FROM (
  SELECT 
    LS.viewer.userID AS userID
    ,STRING_AGG(DISTINCT LS.stream.streamMode ORDER BY LS.stream.streamMode) AS streamMode
  FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
  WHERE LS.viewer.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
    AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
    AND LS.viewer.userID IN (
      SELECT DISTINCT DUB.userID
      FROM `media17-1119.MatomoDataMart.DailyUserBehavior` AS DUB
      WHERE DUB.timezoneDate BETWEEN '2022-05-01' AND '2022-05-31'
        AND DUB.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
        AND DUB.view.duration IS NOT NULL
    )
  GROUP BY userID
) AS tmp
GROUP BY streamMode

-- Content type
SELECT
  IFNULL(T.en_us, subtab) AS contentType
  ,COUNT(DISTINCT LS.viewer.userID) AS counts
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
  ,UNNEST(LS.stream.subtab) AS subtab
LEFT JOIN `media17-1119.MatomoCore.SubtabTranslation` AS T
  ON subtab = T.ID
WHERE LS.viewer.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
  AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
  AND LS.viewer.userID IN (
    SELECT DISTINCT DUB.userID
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior` AS DUB
    WHERE DUB.timezoneDate BETWEEN '2022-05-01' AND '2022-05-31'
      AND DUB.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
      AND view.duration IS NOT NULL
  )
GROUP BY contentType
ORDER counts

-- Number of streamers viewed
SELECT
  CASE
    WHEN numStreamer <= 5 THEN CAST(numStreamer AS STRING)
    WHEN numStreamer BETWEEN 6 AND 10 THEN '6~10'
    WHEN numStreamer BETWEEN 11 AND 20 THEN '11~20'
    ELSE '>20'
  END AS numStreamer
  ,COUNT(userID) AS counts
FROM (
  SELECT 
    LS.viewer.userID AS userID
    ,COUNT(DISTINCT LS.streamerID) AS numStreamer
  FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
  WHERE LS.viewer.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
    AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
    AND LS.viewer.userID IN (
      SELECT DISTINCT DUB.userID
      FROM `media17-1119.MatomoDataMart.DailyUserBehavior` AS DUB
      WHERE DUB.timezoneDate BETWEEN '2022-05-01' AND '2022-05-31'
        AND DUB.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
        AND DUB.view.duration IS NOT NULL
    ) 
  GROUP BY userID
)AS T
GROUP BY numStreamer

-- Streamer country X content Type
WITH 
  AllContentType AS (
    SELECT
      LS.streamer.operationRegionGroup AS streamerCountry
      ,CASE
        WHEN LS.streamer.operationRegionGroup IN ('Japan') THEN IFNULL(T.ja, subtab)
        WHEN LS.streamer.operationRegionGroup IN ('Taiwan','Malaysia','Singapore', 'Philippines', 'Indonesia') THEN IFNULL(T.zh_TW, subtab)
        WHEN LS.streamer.operationRegionGroup IN ('Hong Kong', 'Macau') THEN IFNULL(T.zh_TW, subtab)
        WHEN LS.streamer.operationRegionGroup IN ('United States', 'Australia', 'Mexico', 'Canada', 'Colombia') THEN IFNULL(T.en_us, subtab)
        ELSE subtab
      END AS contentType
      ,COUNT(DISTINCT LS.viewer.userID) AS counts
    FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
      ,UNNEST(LS.stream.subtab) AS subtab
    LEFT JOIN `media17-1119.MatomoCore.SubtabTranslation` AS T
      ON subtab = T.ID
    WHERE LS.viewer.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
      AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
      AND LS.viewer.userID IN (
        SELECT DISTINCT DUB.userID
        FROM `media17-1119.MatomoDataMart.DailyUserBehavior` AS DUB
        WHERE DUB.timezoneDate BETWEEN '2022-05-01' AND '2022-05-31'
          AND DUB.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
          AND view.duration IS NOT NULL
      )
    GROUP BY streamerCountry, contentType
  )
  ,AllContentTypeOrder AS (
    SELECT
      *
      ,ROW_NUMBER() OVER (PARTITION BY streamerCountry ORDER BY counts DESC) AS numRow
    FROM AllContentType
  )
SELECT 
  streamerCountry
  ,contentType
  ,counts
FROM AllContentTypeOrder
WHERE numRow <= 5
UNION ALL
SELECT
  streamerCountry
  ,'Remainder' AS contentType
  ,SUM(counts)
FROM AllContentTypeOrder
WHERE numRow > 5
GROUP BY streamerCountry, contentType
ORDER BY streamerCountry, contentType, counts DESC

-- Streamer country X content type top 20
SELECT
  LS.streamer.operationRegionGroup AS streamerCountry
  ,CASE
    WHEN LS.streamer.operationRegionGroup IN ('Japan') THEN IFNULL(T.ja, subtab)
    WHEN LS.streamer.operationRegionGroup IN ('Taiwan','Malaysia','Singapore', 'Philippines', 'Indonesia') THEN IFNULL(T.zh_TW, subtab)
    WHEN LS.streamer.operationRegionGroup IN ('Hong Kong', 'Macau') THEN IFNULL(T.zh_TW, subtab)
    WHEN LS.streamer.operationRegionGroup IN ('United States', 'Australia', 'Mexico', 'Canada', 'Colombia') THEN IFNULL(T.en_us, subtab)
    ELSE subtab
  END AS contentType
  ,COUNT(DISTINCT LS.viewer.userID) AS counts
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LS
  ,UNNEST(LS.stream.subtab) AS subtab
LEFT JOIN `media17-1119.MatomoCore.SubtabTranslation` AS T
  ON subtab = T.ID
WHERE LS.viewer.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
  AND DATE(LS.beginTime, LS.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
  AND LS.viewer.userID IN (
    SELECT DISTINCT DUB.userID
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior` AS DUB
    WHERE DUB.timezoneDate BETWEEN '2022-05-01' AND '2022-05-31'
      AND DUB.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
      AND view.duration IS NOT NULL
  )
GROUP BY streamerCountry, contentType
ORDER BY counts DESC