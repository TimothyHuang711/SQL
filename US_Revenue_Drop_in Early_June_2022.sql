-- Number of unique spenders and spent revenue
SELECT
  DATE_TRUNC(timezoneDate, WEEK) AS week
  ,SUM(gift.totalListPrice) AS spendRevenue
  ,COUNT(DISTINCT userID) AS numSpender
FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion`
WHERE operationRegionGroup = 'United States'
  AND timezoneDate BETWEEN '2022-05-29' AND '2022-06-11'
  AND gift IS NOT NULL
GROUP BY week
ORDER BY week

-- Number of receivers
SELECT
  DATE_TRUNC(timezoneDate, WEEK) AS week
  ,COUNT(DISTINCT receivers.streamerID) AS numReceiver
  ,SUM(receivers.listPrice) AS receivedRevenue
FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion`
CROSS JOIN UNNEST(gift.receivers) AS receivers
WHERE operationRegionGroup = 'United States'
  AND timezoneDate BETWEEN '2022-05-29' AND '2022-06-11'
  AND gift IS NOT NULL
GROUP BY week
ORDER BY week

-- Split spender into spent in only one week or both weeks
SELECT 
  '2022-05-29' AS week
  ,'firstWeek' AS label
  ,SUM(gift.totalListPrice) AS spendRevenue
  ,COUNT(DISTINCT userID) AS numSpender
FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion`
WHERE operationRegionGroup = 'United States'
  AND timezoneDate BETWEEN '2022-05-29' AND '2022-06-04'
  AND gift IS NOT NULL
  AND userID NOT IN (
    SELECT DISTINCT userID
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion`
    WHERE operationRegionGroup = 'United States'
      AND timezoneDate BETWEEN '2022-06-05' AND '2022-06-11'
      AND gift IS NOT NULL
  )
UNION ALL
SELECT 
  '2022-05-29' AS week
  ,'bothWeek' AS label
  ,SUM(gift.totalListPrice) AS spendRevenue
  ,COUNT(DISTINCT userID) AS numSpender
FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion`
WHERE operationRegionGroup = 'United States'
  AND timezoneDate BETWEEN '2022-05-29' AND '2022-06-04'
  AND gift IS NOT NULL
  AND userID IN (
    SELECT DISTINCT userID
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion`
    WHERE operationRegionGroup = 'United States'
      AND timezoneDate BETWEEN '2022-06-05' AND '2022-06-11'
      AND gift IS NOT NULL
  )
UNION ALL
SELECT 
  '2022-06-05' AS week
  ,'bothWeek' AS label
  ,SUM(gift.totalListPrice) AS spendRevenue
  ,COUNT(DISTINCT userID) AS numSpender
FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion`
WHERE operationRegionGroup = 'United States'
  AND timezoneDate BETWEEN '2022-06-05' AND '2022-06-11'
  AND gift IS NOT NULL
  AND userID IN (
    SELECT DISTINCT userID
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion`
    WHERE operationRegionGroup = 'United States'
      AND timezoneDate BETWEEN '2022-05-29' AND '2022-06-04'
      AND gift IS NOT NULL
  )
UNION ALL
SELECT 
  '2022-06-05' AS week
  ,'secondWeek' AS label
  ,SUM(gift.totalListPrice) AS spendRevenue
  ,COUNT(DISTINCT userID) AS numSpender
FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion`
WHERE operationRegionGroup = 'United States'
  AND timezoneDate BETWEEN '2022-06-05' AND '2022-06-11'
  AND gift IS NOT NULL
  AND userID NOT IN (
    SELECT DISTINCT userID
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion`
    WHERE operationRegionGroup = 'United States'
      AND timezoneDate BETWEEN '2022-05-29' AND '2022-06-04'
      AND gift IS NOT NULL
  )

-- Event revenue
SELECT
  DATE_TRUNC(tzDate, WEEK) AS week
  ,eventType
  ,SUM(dailySendPrice) AS recenue
FROM `media17-1119.MatomoDataTaggingUserSystem.CoinRevenue_Receiver_Cash_Daily`
WHERE tzDate BETWEEN '2022-05-29' AND '2022-06-11'
  AND operationRegionGroup = 'United States'
GROUP BY week, eventType

Event counts
SELECT 
  department
  ,COUNT(DISTINCT eventName) AS numEvent
FROM `media17-1119.MatomoDataSource.EventAnalysisUnnestAll`
WHERE startUTCDatetime <= '2022-06-05'
  AND endUTCDatetime >= '2022-06-11'
  AND receiverInfo.streamInferRegionGroup = 'United States'
GROUP BY department
ORDER BY tzDate DESC

-- Event revenue by department and not event
WITH
  USEventRevenue AS (
    SELECT 
      tzDate
      ,SUM(pointUsageIncome) AS revenue
    FROM `media17-1119.MatomoDataSource.EventAnalysisUnnestAll`
    WHERE tzDate BETWEEN '2022-05-22' AND '2022-06-21'
      AND receiverInfo.streamInferRegionGroup = 'United States'
      AND department = 'US-Event'
      AND (
        eventName IS NULL
        OR eventName NOT IN ('June Agency Event')
      )
    GROUP BY tzDate
  )
  ,NonEventRevene AS (
    SELECT
      tzDate
      ,SUM(pointUsageIncome) AS revenue
    FROM `media17-1119.MatomoDataSource.EventAnalysis`
    WHERE tzDate BETWEEN '2022-05-22' AND '2022-06-21'
      AND receiverInfo.streamInferRegionGroup = 'United States'
      AND isEventGift IS FALSE
    GROUP BY tzDate
  )
  ,EventRevenue AS (
    SELECT
      tzDate
      ,SUM(pointUsageIncome) AS revenue
    FROM `media17-1119.MatomoDataSource.EventAnalysis`
    WHERE tzDate BETWEEN '2022-05-22' AND '2022-06-21'
      AND receiverInfo.streamInferRegionGroup = 'United States'
      AND isEventGift IS True
    GROUP BY tzDate
  )
SELECT
  tzDate
  ,USR.revenue AS usEventRevenue
  ,ER.revenue - USR.revenue AS otherEventRevenue
  ,NER.revenue AS nonEventRevenue
FROM USEventRevenue AS USR
LEFT JOIN EventRevenue AS ER
  USING(tzDate)
LEFT JOIN NonEventRevene AS NER
  USING(tzDate)
  ,department

-- US Event revenue by event name
SELECT 
  tzDate
  ,eventName
  ,SUM(pointUsageIncome) AS revenue
FROM `media17-1119.MatomoDataSource.EventAnalysisUnnestAll`
WHERE tzDate BETWEEN '2022-05-22' AND '2022-06-21'
  AND receiverInfo.streamInferRegionGroup = 'United States'
  AND isEventGift IS TRUE
  AND department = 'US-Event'
  AND (
    eventName IS NOT NULL
    -- This agency event counts all event points in the month so will double the points
    OR eventName != 'June Agency Event'
  )
GROUP BY
  tzDate
  ,eventName

-- US event number by department
SELECT 
  tzDate
  ,department
  ,COUNT(DISTINCT eventName) AS counts
FROM `media17-1119.MatomoDataSource.EventAnalysisUnnestAll`
WHERE tzDate >= '2022-05-22'
  AND receiverInfo.streamInferRegionGroup = 'United States'
  AND isEventGift IS TRUE
GROUP BY
  tzDate
  ,department

-- Numbers of active, starting and ending events by date
WITH
  Events AS (
    SELECT DISTINCT
      eventName
      ,DATE(TIMESTAMP(startUTCDatetime)) AS eventStartDate
      ,DATE(TIMESTAMP(endUTCDatetime)) AS eventEndDate
    FROM `media17-1119.MatomoDataSource.EventAnalysisUnnestAll`
    WHERE department = 'US-Event'
      AND NOT (
        (
          DATE(TIMESTAMP(startUTCDatetime)) < '2022-05-12' 
          AND DATE(TIMESTAMP(endUTCDatetime)) < '2022-05-12'
        )
        OR (
          DATE(TIMESTAMP(startUTCDatetime)) > '2022-06-17' 
          AND DATE(TIMESTAMP(endUTCDatetime)) > '2022-06-17'
        )
      )
    ORDER BY eventStartDate, eventEndDate
  )
  ,LabelDate AS (
    SELECT
      daterange
      ,eventName
      ,eventStartDate
      ,eventEndDate
      ,1 AS active
      ,IF(daterange = Date(eventStartDate), 1, 0) AS isStart
      ,IF(daterange = Date(eventEndDate), 1, 0) AS isEnd
    FROM Events
    CROSS JOIN UNNEST(GENERATE_DATE_ARRAY('2022-05-01', '2022-06-17')) AS daterange
      ON daterange >= DATE(eventStartDate)
        AND daterange <= DATE(eventEndDate)
    ORDER BY daterange, eventStartDate, eventEndDate
  )
SELECT
  daterange
  ,SUM(active) AS numActiveEvent
  ,SUM(isStart) AS numStartingEvent
  ,SUM(isEnd) AS numEndEvent
FROM LabelDate
GROUP BY daterange
ORDER BY daterange

-- Streamer performance in week 05/29 and 06/05
WITH  
  ViewPoint AS(
    SELECT 
      tzDate
      ,openID
      ,livestreamDuration
      ,viewDuration
      ,receivedPoint
    FROM `media17-1119.MatomoDataSource.StreamerPerformance_Weekly`
    WHERE tzDate IN ('2022-05-29', '2022-06-05') 
      AND operationRegionGroup = 'United States'
      AND receivedPoint IS NOT NULL
  )
  ,ViewPointPivot AS (
    SELECT *
    FROM ViewPoint
      PIVOT(
        SUM(viewDuration) AS viewDuration
        ,SUM(receivedPoint) AS receivedPoint
        ,SUM(livestreamDuration) AS livestreamDuration
        FOR tzDate IN ('2022-05-29' AS week1, '2022-06-05' AS week2)
      )
  )
  ,Revenue AS (
    SELECT
      DATE_TRUNC(timezoneDate, WEEK) AS week
      -- ,receivers.streamerID
      ,UD_S.profile.openID AS openID
      ,SUM(receivers.listPrice) AS receivedRevenue
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion` AS DUB
    CROSS JOIN UNNEST(DUB.gift.receivers) AS receivers
    LEFT JOIN  `media17-1119.MatomoCore.dim_userdimension` AS UD_S
      ON receivers.streamerID = UD_S.userID
    WHERE DUB.operationRegionGroup = 'United States'
      AND DUB.timezoneDate BETWEEN '2022-05-29' AND '2022-06-11'
      AND DUB.gift IS NOT NULL
    GROUP BY week, streamerID, openID
    -- ORDER BY week, openID, receivedRevenue DESC
  )
  ,PivotRevenue AS (
    SELECT *
    FROM Revenue 
      PIVOT(
        SUM(receivedRevenue) AS receivedRevenue 
        FOR week IN ('2022-05-29' AS week1, '2022-06-05' AS week2)
      )
  )
SELECT *
FROM ViewPointPivot AS VP
FULL JOIN PivotRevenue AS PR
  USING(openID)

-- Top 100 less spent spenders
WITH
  Revenue AS (
    SELECT
      DATE_TRUNC(timezoneDate, WEEK) AS week
      ,receivers.streamerID
      ,UD_S.profile.openID AS streamerOpenID
      ,DUB.userID
      ,UD.profile.openID AS userOpenID
      ,DUB.registerCountry
      ,SUM(receivers.listPrice) AS spentRevenue
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion` AS DUB
    CROSS JOIN UNNEST(DUB.gift.receivers) AS receivers
    LEFT JOIN  `media17-1119.MatomoCore.dim_userdimension` AS UD_S
      ON receivers.streamerID = UD_S.userID
    LEFT JOIN `media17-1119.MatomoCore.dim_userdimension` AS UD
      ON DUB.userID = UD.userID
    WHERE DUB.operationRegionGroup = 'United States'
      AND DUB.timezoneDate BETWEEN '2022-05-29' AND '2022-06-11'
      AND DUB.gift IS NOT NULL
    GROUP BY week, streamerID, streamerOpenID, userID, userOpenID, registerCountry
    ORDER BY week, streamerOpenID, spentRevenue DESC
  )
  ,PivotRevenue AS (
    SELECT *
    FROM Revenue 
      PIVOT(SUM(spentRevenue) AS spentRevenue
      FOR week IN ('2022-05-29' AS `0529`, '2022-06-05' AS `0605`))
  )
  ,Top100LessSpent AS (
    SELECT
      *
      ,IFNULL(spentRevenue_0605, 0) - spentRevenue_0529 AS changes
    FROM PivotRevenue AS PR
    WHERE spentRevenue_0529 IS NOT NULL
    ORDER BY changes
    LIMIT 100
  )
  ,Top100Behavior0529 AS (
    SELECT
      DUB.userID
      ,SUM(view.duration) AS viewDuration_0529
      ,SUM(gift.totalCount) AS giftCount_0529
      ,SUM(gift.totalPoint) AS giftPoint_0529
      ,SUM(gift.totalListPrice) AS giftPrice_0529
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior` AS DUB
    WHERE DUB.timezoneDate BETWEEN '2022-05-29' AND '2022-06-04'
      AND DUB.userID IN (
        SELECT userID
        FROM Top100LessSpent
      )
    GROUP BY userID
  )
  ,Top100Behavior0605 AS (
    SELECT
      DUB.userID
      ,SUM(view.duration) AS viewDuration_0605
      ,SUM(gift.totalCount) AS giftCount_0605
      ,SUM(gift.totalPoint) AS giftPoint_0605
      ,SUM(gift.totalListPrice) AS giftPrice_0605
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior` AS DUB
    WHERE DUB.timezoneDate BETWEEN '2022-06-05' AND '2022-06-11'
      AND DUB.userID IN (
        SELECT userID
        FROM Top100LessSpent
      )
    GROUP BY userID
  )
SELECT *
FROM Top100LessSpent
LEFT JOIN Top100Behavior0529
  USING(userID)
LEFT JOIN Top100Behavior0605
  USING(userID)

-- Top 20 streamers top 10 spenders in each week
WITH
  Revenue AS (
    SELECT
      DATE_TRUNC(timezoneDate, WEEK) AS week
      ,receivers.streamerID
      ,UD_S.profile.openID AS streamerOpenID
      ,DUB.userID
      ,UD.profile.openID AS userOpenID
      ,SUM(receivers.point) AS receivedPoints
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion` AS DUB
    CROSS JOIN UNNEST(DUB.gift.receivers) AS receivers
    LEFT JOIN  `media17-1119.MatomoCore.dim_userdimension` AS UD_S
      ON receivers.streamerID = UD_S.userID
    LEFT JOIN `media17-1119.MatomoCore.dim_userdimension` AS UD
      ON DUB.userID = UD.userID
    WHERE DUB.operationRegionGroup = 'United States'
      AND DUB.timezoneDate BETWEEN '2022-05-29' AND '2022-06-11'
      AND DUB.gift IS NOT NULL
    GROUP BY week, streamerID, streamerOpenID, userID, userOpenID
    ORDER BY week, streamerOpenID, receivedPoints DESC
  )
  ,StreamerRank AS (
    WITH 
      StreamerRevenue AS (
        SELECT
          week
          ,streamerID
          ,SUM(receivedPoints) AS receivedPoints
        FROM Revenue
        GROUP BY week, streamerID
      )
      ,StreamerRow AS (
        SELECT
          week
          ,streamerID
          ,ROW_NUMBER() OVER (PARTITION BY week ORDER BY receivedPoints DESC) AS rowNum
        FROM StreamerRevenue
      )
      SELECT 
        week
        ,streamerID
        ,rowNum
      FROM StreamerRow
      WHERE rowNum <= 20
  )
  ,SpenderRank AS (
    WITH SpenderRow AS (
      SELECT
        week
        ,streamerID
        ,userID
        ,ROW_NUMBER() OVER (PARTITION BY week, streamerID ORDER BY receivedPoints DESC) AS rowNum
      FROM Revenue
    )
    SELECT 
      week
      ,streamerID
      ,userID
      ,rowNum
    FROM SpenderRow
    WHERE rowNum <= 10
  )

SELECT *
FROM Revenue
INNER JOIN StreamerRank
  USING(week, streamerID)
INNER JOIN SpenderRank
  USING(week, streamerID, userID)