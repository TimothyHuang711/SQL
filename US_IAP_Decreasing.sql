-- IAP Monthly payer, revenue and AUPPR
-- SELECT 
--   tzMonth
--   ,COUNT(DISTINCT user.userID) AS payer
--   ,SUM(listPrice) AS purchaseRevenue
--   ,SUM(listPrice)/COUNT(DISTINCT user.userID) AS ARPPU
--   -- first payer
--   ,COUNT(DISTINCT 
--     IF(purchaseInfo.isFirstPurchase = "true", user.userID, NULL)
--   ) AS firstPayer
--   -- existing payer
--   ,COUNT(DISTINCT 
--     IF(purchaseInfo.isFirstPurchase = "false", user.userID, NULL)
--   ) AS existingPayer
-- FROM `media17-1119.MatomoDataSource.PayingBehaviorAssetGain` 
-- WHERE tzMonth < "2022-07-01"
--   AND operationRegionGroup = 'United States'
--   AND channelType = "IAP"
--   AND RefundType = "Excluding Refund Records"
-- GROUP BY tzMonth
-- ORDER BY tzMonth

-- New Payer decrease: never-paid user and their pay conversion rate
WITH
  FirstPayLeadTime AS (
    SELECT
      tzMonth
      ,AVG(purchaseInfo.firstPayLeadTime) AS firstPayLeadTime
    FROM `media17-1119.MatomoDataSource.PayingBehaviorAssetGain`
    WHERE tzMonth < "2022-07-01"
      AND operationRegionGroup = 'United States'
      AND channelType = "IAP"
      AND RefundType = "Excluding Refund Records"
    GROUP BY tzMonth
  )
  ,MonthlyActiveUser AS (
    -- MAU and monthly unique payer
    SELECT DATE_TRUNC(timezoneDate, MONTH) AS tzMonth
      ,COUNT(DISTINCT userID) AS MAU
      ,COUNT(DISTINCT 
        IF(UD.purchaseInfo.firstPayTime IS NULL, userID, NULL)
      ) AS MAU_NP
      -- Pay Later
      ,COUNT(DISTINCT
        IF(DATE(
              UD.purchaseInfo.firstPayTime,
              "America/Los_Angeles"
              ) >= DATE_ADD(DATE_TRUNC(timezoneDate, MONTH), INTERVAL 1 MONTH),
            userID, NULL)
      ) AS MAU_PL
      -- Pay in current month or before
      ,COUNT(DISTINCT IF(
        DATE(UD.purchaseInfo.firstPayTime, "America/Los_Angeles") < 
          DATE_ADD(DATE_TRUNC(timezoneDate, MONTH), INTERVAL 1 MONTH),
        userID, NULL)) AS MAU_P
      -- Conversion month for pay later users
      ,SUM(IF(
        DATE(
          UD.purchaseInfo.firstPayTime,
          "America/Los_Angeles"
        ) >= DATE_ADD(DATE_TRUNC(timezoneDate, MONTH), INTERVAL 1 MONTH),
        DATE_DIFF(
          DATE(UD.purchaseInfo.firstPayTime, "America/Los_Angeles"),
          DATE_TRUNC(timezoneDate, MONTH), DAY
        ), NULL
      )) / COUNT(DISTINCT
        IF(DATE(
          UD.purchaseInfo.firstPayTime,
          "America/Los_Angeles"
          ) >= DATE_ADD(DATE_TRUNC(timezoneDate, MONTH), INTERVAL 1 MONTH),
          userID, NULL)
      ) AS conversionMonth_PL
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior`
    LEFT JOIN `MatomoCore.dim_userdimension` AS UD
      USING(userID)
    WHERE timezoneDate BETWEEN "2019-01-01" AND "2022-06-30"
      AND operationRegionGroup = "United States"
    GROUP BY tzMonth
  )
SELECT
  MAU.tzMonth
  ,MAU.MAU
  ,MAU.MAU_NP
  ,MAU.MAU_PL
  ,MAU.conversionMonth_PL
  ,F.firstPayLeadTime
FROM MonthlyActiveUser AS MAU
FULL JOIN FirstPayLeadTime AS F
  USING(tzMonth)
ORDER BY tzMonth

-- Existing Payer decrease: 
-- WITH
--   MonthlyPayer AS (
--     SELECT DISTINCT
--       tzMonth
--       ,user.userID
--       ,DATE_TRUNC(DATE(purchaseInfo.firstPayTime, "America/Los_Angeles"), MONTH) AS firstPayMonth
--     FROM `media17-1119.MatomoDataSource.PayingBehaviorAssetGain` 
--     WHERE tzMonth < "2022-07-01"
--       AND operationRegionGroup = 'United States'
--       AND channelType = "IAP"
--       AND RefundType = "Excluding Refund Records"
--   )
--   ,PayerDecom AS (
--     SELECT 
--       MP1.tzMonth
--       ,MP1.userID
--       ,CASE
--         WHEN MAX(MP1.firstPayMonth) = MP1.tzMonth THEN "newPayer"
--         WHEN MAX(MP2.tzMonth) = DATE_SUB(MP1.tzMonth, INTERVAL 1 MONTH) THEN "lastMonthPayer"
--         ELSE "otherPayer"
--       END AS payerType
--     FROM MonthlyPayer AS MP1
--     LEFT JOIN MonthlyPayer AS MP2
--       ON MP1.tzMonth > MP2.tzMonth
--       AND MP1.userID = MP2.userID
--     GROUP BY tzMonth, userID
--   )
-- SELECT *
-- FROM PayerDecom AS PT
--   PIVOT (
--     COUNT(DISTINCT PT.userID) AS MAU
--     FOR PT.payerType IN ("newPayer", "lastMonthPayer", "otherPayer")
--   )
-- ORDER BY tzMonth

-- Stop paying user retention
-- Last purchase
-- WITH
--   USPayer AS (
--     SELECT user.userID
--       ,DATE_TRUNC(DATE(purchaseInfo.lastPayTime, 'America/Los_Angeles'), MONTH) AS lastPayMonth
--     FROM `media17-1119.MatomoDataSource.PayingBehaviorAssetGain`
--     WHERE operationRegionGroup = 'United States'
--       AND channelType = 'IAP'
--       AND purchaseInfo.isLastPurchase = "true"
--       AND tzDate >= "2019-01-01"
--   )
--   ,MUB_USP AS (
--     SELECT 
--       DUB.userID
--       ,USP.lastPayMonth
--       ,MAX(DATE_TRUNC(DUB.timezoneDate, MONTH)) AS lastActiveMonth
--     FROM `media17-1119.MatomoDataMart.DailyUserBehavior`  AS DUB
--     INNER JOIN USPayer AS USP
--       ON DUB.userID = USP.userID
--       AND DATE_TRUNC(DUB.timezoneDate, MONTH) >= USP.lastPayMonth
--     GROUP BY userID, lastPayMonth
--   )
--   ,LastPayer AS (
--     SELECT
--       lastPayMonth
--       ,COUNT(DISTINCT userID) AS lastPayer
--       ,COUNT(DISTINCT IF(lastPayMonth = lastActiveMonth, userID, NULL)) AS leftPayer
--       ,COUNT(DISTINCT IF(DATE_DIFF(lastActiveMonth, lastPayMonth, MONTH) = 1, userID, NULL)) AS retained1MPayer
--       ,COUNT(DISTINCT IF(DATE_DIFF(lastActiveMonth, lastPayMonth, MONTH) = 2, userID, NULL)) AS retained2MPayer
--       ,COUNT(DISTINCT IF(DATE_DIFF(lastActiveMonth, lastPayMonth, MONTH) >= 3, userID, NULL)) AS retained3MPayer
--       ,COUNT(DISTINCT IF(lastPayMonth < lastActiveMonth AND lastActiveMonth = "2022-07-01", userID, NULL)) AS survivedPayer
--       ,SAFE_DIVIDE(
--         SUM(DATE_DIFF(lastActiveMonth, lastPayMonth, MONTH)),
--         COUNT(DISTINCT userID)
--       ) AS avgRetainedMonth
--     FROM MUB_USP
--     GROUP BY lastPayMonth
--   )
--   ,PercentileRetainedMonth AS (
--     SELECT DISTINCT
--       lastPayMonth
--       ,PERCENTILE_CONT(DATE_DIFF(lastActiveMonth, lastPayMonth, MONTH), 0.5 RESPECT NULLS) OVER(PARTITION BY lastPayMonth) AS medianRetainedMonth
--       ,PERCENTILE_CONT(DATE_DIFF(lastActiveMonth, lastPayMonth, MONTH), 0.75 RESPECT NULLS) OVER(PARTITION BY lastPayMonth) AS P75RetainedMonth
--       ,PERCENTILE_CONT(DATE_DIFF(lastActiveMonth, lastPayMonth, MONTH), 0.9 RESPECT NULLS) OVER(PARTITION BY lastPayMonth) AS P90RetainedMonth
--     FROM MUB_USP
--   )
-- SELECT 
--   LP.*
--   ,PRM.* EXCEPT(lastPayMonth)
-- FROM LastPayer AS LP
-- LEFT JOIN PercentileRetainedMonth AS PRM
--   USING(lastPayMonth)
-- ORDER BY lastPayMonth