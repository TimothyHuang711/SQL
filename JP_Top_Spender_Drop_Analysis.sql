-- JP spenders
-- WITH 
--   Contract AS (
--     SELECT
--       CCLWRD.userID,
--       CCLWRD.region,
--       CCLWRD.operationRegionGroup,
--       CCLWRD.timezone,
--       CCLWRD.timeStart,
--       CCLWRD.timeEnd,
--       CCLWRD.isContracted
--     FROM
--       `media17-1119.datamart_view.ContractChangeLogWithRegionDetail` AS CCLWRD
--     WHERE
--       isContracted IS true
--   ),
--   MonthlyWithoutExpired AS(
--     SELECT
--       DATE_TRUNC(
--         DATE(
--           PUI.timestamp_utc,
--           IF(
--             isContracted IS true,
--             Contract.timezone,
--             IF(
--               ReceiverUD.region.registerCountry IS NOT NULL
--               AND ReceiverUD.region.registerCountry != 'Unknown',
--               IFNULL(ReceiverORG.timezone, 'Asia/Taipei'),
--               'Asia/Taipei'
--             )
--           )
--         ),
--         MONTH
--       ) AS month,
--       PUI.user_id AS userID,
--       SUM(PUI.listPurchaseIncome) as spentRevenue
--     FROM
--       `media17-1119.MatomoCore.fact_usage` AS PUI
--     LEFT JOIN `media17-1119.MatomoCore.dim_userdimension` AS ReceiverUD 
--       ON ReceiverUD.userID = PUI.receive_user_id
--     LEFT JOIN `media17-1119.MatomoCore.lookup_region` AS ReceiverORG 
--       ON ReceiverORG.country = ReceiverUD.region.registerCountry
--       AND PUI.timestamp_utc >= ReceiverORG.groupStartTime
--       AND PUI.timestamp_utc < ReceiverORG.groupEndTime
--     LEFT JOIN Contract 
--       ON Contract.userID = PUI.receive_user_id
--       AND PUI.timestamp_utc >= Contract.timeStart
--       AND PUI.timestamp_utc < Contract.timeEnd
--     WHERE
--       DATE(
--         PUI.timestamp_utc,
--         IF(
--           isContracted IS true,
--           Contract.timezone,
--           IF(
--             ReceiverUD.region.registerCountry IS NOT NULL
--             AND ReceiverUD.region.registerCountry != 'Unknown',
--             IFNULL(ReceiverORG.timezone, 'Asia/Taipei'),
--             'Asia/Taipei'
--           )
--         )
--       ) BETWEEN "2015-01-01" AND "2022-08-31"
--       AND PUI.giftID NOT IN (
--         'expiredPaidGiftID',
--         'expiredFreeGiftID',
--         'system_recycle',
--         'system_cancel_order',
--         'system_no_reason_recycle'
--       )
--       -- Revenue Remove GamePool lose(user win) usage and GamePool bet usage
--       AND NOT (
--         PUI.user_id IN ('016a2c96-1d1d-4530-97d7-fb3e9866bc7e', 'bb4582dc-3657-4360-9fe8-64809509a2ff')
--         AND PUI.giftID IN (
--             'fruit_farm_gpool_lose_points'
--         )
--       )
--       AND NOT (
--         PUI.receive_user_id IN ('016a2c96-1d1d-4530-97d7-fb3e9866bc7e', 'bb4582dc-3657-4360-9fe8-64809509a2ff')
--         AND PUI.giftID IN (
--             'fruit_farm_user_bet_points'
--         )
--       )
--       AND IF(
--         isContracted IS true,
--         Contract.operationRegionGroup,
--         IF(
--           ReceiverUD.region.registerCountry IS NOT NULL
--           AND ReceiverUD.region.registerCountry != 'Unknown',
--           IFNULL(ReceiverORG.operationRegionGroup, 'RoW'),
--           'Unknown'
--         )
--       ) = "Japan"
--     GROUP BY
--       month,
--       userID
--   )
-- SELECT *
-- FROM MonthlyWithoutExpired
-- ORDER BY month, userID

-- Current situation of gross revenue and sVIP in 2022
-- WITH
--   MonthlyReceivedRevenue AS (
--     SELECT
--       tzDate AS month,
--       SUM(monthlySendPrice) AS receivedRevenue
--     FROM `media17-1119.MatomoDataSourceForKPI.CoinRevenue_Receiver_Cash_Monthly`
--     WHERE tzDate BETWEEN "2022-01-01" AND "2022-08-31"
--       AND operationRegionGroup = "Japan"
--     GROUP BY month
--   )
-- SELECT
--   month,
--   R.receivedRevenue,
--   COUNTIF(S.spentRevenue < 1000) AS normalSpenders,
--   COUNTIF(S.spentRevenue >= 1000) AS TopSpenders,
--   SUM(IF(S.spentRevenue < 1000, S.spentRevenue, 0)) AS normalSpentRev,
--   SUM(IF(S.spentRevenue >= 1000, S.spentRevenue, 0)) AS topSpentRev
-- FROM MonthlyReceivedRevenue AS R
-- INNER JOIN `media17-1119.DataLab_Timothy.JPSpenders` AS S
--   USING(month)
-- GROUP BY month, receivedRevenue
-- ORDER BY month

-- sVIP decomposition - new users, existing users & existing sVIP
-- WITH
--   SVIP AS (
--     SELECT *
--     FROM `media17-1119.DataLab_Timothy.JPSpenders`
--     WHERE spentRevenue >= 1000
--   )
--   ,SVIPStatus AS (
--     SELECT
--       T1.month,
--       T1.userID,
--       IFNULL(MIN(DATE_DIFF(T1.month, T2.month, MONTH)), 0) AS diff
--     FROM SVIP AS T1
--     LEFT JOIN SVIP AS T2
--       ON T1.userID = T2.userID
--       AND T1.month > T2.month
--     GROUP BY month, userID
--   )
--   ,Registers AS (
--     SELECT
--       S.month,
--       S.userID,
--       S.diff,
--       DATE_TRUNC(DATE(UD.profile.registerTime, IFNULL(LR.timezone, "Asia/Taipei")), MONTH) AS registerMonth
--     FROM SVIPStatus AS S
--     LEFT JOIN `MatomoCore.dim_userdimension` AS UD
--       USING(userID)
--     LEFT JOIN `MatomoCore.lookup_region` AS LR
--       ON UD.region.registerCountry = LR.country
--     WHERE month >= "2022-01-01"
--   )
-- SELECT
--   month AS Month,
--   COUNT(DISTINCT userID) AS Total,
--   COUNT(DISTINCT IF(diff=0 AND month=registerMonth, userID, NULL)) AS `NewUsers`,
--   COUNT(DISTINCT IF(diff=0 AND month>registerMonth, userID, NULL)) AS `ExistingUsers`,
--   COUNT(DISTINCT IF(diff>0, userID, NULL)) AS `ExistingSVIP`
-- FROM Registers 
-- GROUP BY Month
-- ORDER BY Month

-- Conversion rate of new users to sVIP
-- WITH
--   Register AS (
--     SELECT 
--       S.month,
--       S.userID,
--       DATE_TRUNC(DATE(UD.profile.registerTime, IFNULL(LR.timezone, "Asia/Taipei")), MONTH) AS registerMonth,
--       spentRevenue
--     FROM `media17-1119.DataLab_Timothy.JPSpenders` AS S
--     LEFT JOIN `MatomoCore.dim_userdimension` AS UD
--       USING(userID)
--     LEFT JOIN `MatomoCore.lookup_region` AS LR
--       ON UD.region.registerCountry = LR.country
--   )
--   ,NewSVIPLeadMonth AS (
--     SELECT
--       registerMonth AS month,
--       COUNT(DISTINCT userID) AS newUsers
--     FROM Register
--     WHERE spentRevenue >= 1000
--       AND registerMonth = month
--     GROUP BY month
--   )
--   ,Registers AS (
--     SELECT
--       tzDate AS month,
--       SUM(numAttributionType) AS registers
--     FROM `media17-1119.MatomoDataSourceForKPI.NewRegistration_Monthly`
--     WHERE tzDate >= "2022-01-01"
--       AND operationRegionGroup = "Japan"
--     GROUP BY tzDate
--   )
-- SELECT 
--   T1.month AS month,
--   T1.newUsers/T2.registers AS conversionrate,
--   T1.newUsers,
--   T2.registers
-- FROM NewSVIPLeadMonth AS T1
-- LEFT JOIN Registers AS T2
--   USING(month)
-- WHERE T1.month >= "2022-01-01"
-- GROUP BY month, registers, newUsers
-- ORDER BY month

-- Conversion rate of existing users to sVIP
WITH
  Register AS (
    SELECT 
      S.month,
      S.userID,
      DATE_TRUNC(DATE(UD.profile.registerTime, IFNULL(LR.timezone, "Asia/Taipei")), MONTH) AS registerMonth,
      spentRevenue
    FROM `media17-1119.DataLab_Timothy.JPSpenders` AS S
    LEFT JOIN `MatomoCore.dim_userdimension` AS UD
      USING(userID)
    LEFT JOIN `MatomoCore.lookup_region` AS LR
      ON UD.region.registerCountry = LR.country
  )
  ,LeadMonth AS (
    SELECT
      userID,
      MIN(month) AS firstMonth,
      DATE_DIFF(MIN(month), registerMonth, MONTH) AS monthDiff,
    FROM Register
    WHERE spentRevenue >= 1000
    GROUP BY userID, registerMonth
  )
  ,LeadMonthSummary AS (
    SELECT
      firstMonth AS month,
      COUNT(DISTINCT userID) AS existingUsersToTopSpenders,
      -- AVG(monthDiff) AS leadMonth,
      COUNT(DISTINCT IF(monthDiff = 1, userID, NULL)) AS M1,
      COUNT(DISTINCT IF(monthDiff BETWEEN 2 AND 3, userID, NULL)) AS M2ToM3,
      COUNT(DISTINCT IF(monthDiff BETWEEN 4 AND 6, userID, NULL)) AS M4ToM6,
      COUNT(DISTINCT IF(monthDiff BETWEEN 7 AND 12, userID, NULL)) AS M7ToM12,
      COUNT(DISTINCT IF(monthDiff > 12, userID, NULL)) AS M12before,
    FROM LeadMonth
    WHERE firstMonth >= "2022-01-01"
      AND monthDiff > 0
    GROUP BY month
  )
  ,MAUList AS (
    SELECT DISTINCT
      DATE_TRUNC(timezoneDate, MONTH) AS month,
      userID,
    FROM `MatomoDataMart.DailyUserBehavior_ViewRegion`
    WHERE operationRegionGroup = 'Japan'
      AND timezoneDate BETWEEN "2022-01-01" AND "2022-08-31"
      AND DATE_TRUNC(registerDate, MONTH) < DATE_TRUNC(timezoneDate, MONTH)
  )
  ,ExistingNonTopMAU AS (
    SELECT
      T1.month,
      COUNT(DISTINCT T1.userID) AS MAU,
      COUNT(DISTINCT IF(T2.firstMonth IS NULL OR T2.firstMonth >= T1.month, T1.userID, NULL)) AS existingMAU
    FROM MAUList AS T1
    LEFT JOIN LeadMonth AS T2
      USING(userID)
    GROUP BY month
  )
SELECT
  T1.*,
  T2.existingUsersToTopSpenders/T1.existingMAU AS conversionRate,
  T2.* EXCEPT(month)
FROM ExistingNonTopMAU AS T1
LEFT JOIN LeadMonthSummary AS T2
  USING(month)
ORDER BY month

-- Existing sVIP renewal interval
-- WITH
--   SVIPInterval AS (
--   SELECT DISTINCT
--     month,
--     userID,
--     DATE_DIFF(month, LAG(month) OVER (PARTITION BY userID ORDER BY month), MONTH) AS monthDiff
--   FROM `media17-1119.DataLab_Timothy.JPSpenders`
--   WHERE spentRevenue >= 1000
--   )
-- SELECT DISTINCT
--   month,
--   COUNT(DISTINCT IF(monthDiff IS NOT NULL, userID, NULL)) OVER (PARTITION BY month) AS existingSVIP,
--   AVG(monthDiff) OVER (PARTITION BY month) AS monthDiff_avg,
--   PERCENTILE_CONT(monthDiff, 0.75 IGNORE NULLS) OVER (PARTITION BY month) AS monthDiff_P75,
--   PERCENTILE_CONT(monthDiff, 0.9) OVER (PARTITION BY month) AS monthDiff_P90,
--   PERCENTILE_CONT(monthDiff, 0.99) OVER (PARTITION BY month) AS monthDiff_P99,
--   COUNT(DISTINCT IF(monthDiff = 1, userID, NULL)) OVER (PARTITION BY month) AS M1,
--   COUNT(DISTINCT IF(monthDiff BETWEEN 2 AND 3, userID, NULL)) OVER (PARTITION BY month) AS M2ToM3,
--   COUNT(DISTINCT IF(monthDiff BETWEEN 4 AND 6, userID, NULL)) OVER (PARTITION BY month) AS M4ToM6,
--   COUNT(DISTINCT IF(monthDiff BETWEEN 7 AND 12, userID, NULL)) OVER (PARTITION BY month) AS M7ToM12,
--   COUNT(DISTINCT IF(monthDiff > 12, userID, NULL)) OVER (PARTITION BY month) AS M12before,
-- FROM SVIPInterval
-- WHERE month >= "2022-01-01"
-- ORDER BY month

-- sVIP retention
-- WITH
--   SVIP AS (
--     SELECT *
--     FROM `media17-1119.DataLab_Timothy.JPSpenders`
--     WHERE spentRevenue >= 1000
--   )
--   ,SVIPRetention AS (
--     SELECT
--       T1.month,
--       T1.userID,
--       DATE_DIFF(T2.month, T1.month, MONTH) AS monthDiff
--     FROM SVIP AS T1
--     LEFT JOIN SVIP AS T2
--       ON T1.userID = T2.userID
--       AND T1.month <= T2.month
--   )
-- SELECT
--   month,
--   COUNT(DISTINCT userID) AS existingSVIP,
--   COUNT(DISTINCT IF(monthDiff=0, userID, NULL))/COUNT(DISTINCT userID) AS M0,
--   COUNT(DISTINCT IF(monthDiff=1, userID, NULL))/COUNT(DISTINCT userID) AS M1,
--   COUNT(DISTINCT IF(monthDiff=2, userID, NULL))/COUNT(DISTINCT userID) AS M2,
--   COUNT(DISTINCT IF(monthDiff=3, userID, NULL))/COUNT(DISTINCT userID) AS M3,
--   COUNT(DISTINCT IF(monthDiff=4, userID, NULL))/COUNT(DISTINCT userID) AS M4,
--   COUNT(DISTINCT IF(monthDiff=5, userID, NULL))/COUNT(DISTINCT userID) AS M5,
--   COUNT(DISTINCT IF(monthDiff=6, userID, NULL))/COUNT(DISTINCT userID) AS M6,
--   COUNT(DISTINCT IF(monthDiff>6, userID, NULL))/COUNT(DISTINCT userID) AS M6Above
-- FROM SVIPRetention
-- WHERE month >= "2022-01-01"
-- GROUP BY month
-- ORDER BY month

-- sVIP churn
-- WITH
--   SVIP AS (
--     SELECT *
--     FROM `media17-1119.DataLab_Timothy.JPSpenders`
--     WHERE spentRevenue >= 1000
--   )
--   ,SVIPChurn AS (
--     SELECT
--       T1.month,
--       T1.userID,
--       MIN(DATE_DIFF(T2.month, T1.month, MONTH)) AS monthDiff
--     FROM SVIP AS T1
--     LEFT JOIN SVIP AS T2
--       ON T1.userID = T2.userID
--       AND T1.month < T2.month
--     GROUP BY month, userID
--   )
-- SELECT
--   month,
--   COUNT(DISTINCT userID) AS existingSVIP,
--   -- COUNT(DISTINCT IF(monthDiff=1, userID, NULL))/COUNT(DISTINCT userID) AS M1,
--   COUNT(DISTINCT IF(monthDiff>1 OR monthDiff IS NULL, userID, NULL))/COUNT(DISTINCT userID) AS M1,
--   COUNT(DISTINCT IF(monthDiff>2 OR monthDiff IS NULL, userID, NULL))/COUNT(DISTINCT userID) AS M2,
--   COUNT(DISTINCT IF(monthDiff>3 OR monthDiff IS NULL, userID, NULL))/COUNT(DISTINCT userID) AS M3,
--   COUNT(DISTINCT IF(monthDiff>4 OR monthDiff IS NULL, userID, NULL))/COUNT(DISTINCT userID) AS M4,
--   COUNT(DISTINCT IF(monthDiff>5 OR monthDiff IS NULL, userID, NULL))/COUNT(DISTINCT userID) AS M5,
--   COUNT(DISTINCT IF(monthDiff>6 OR monthDiff IS NULL, userID, NULL))/COUNT(DISTINCT userID) AS M6
-- FROM SVIPChurn
-- WHERE month >= "2021-01-01"
-- GROUP BY month
-- ORDER BY month

-- ARPPU per sVIP
-- SELECT DISTINCT
--   month,
--   AVG(spentRevenue) OVER (PARTITION BY month) AS ARPPU,
--   PERCENTILE_CONT(spentRevenue, 0.5) OVER (PARTITION BY month) AS ARPPU_P50,
--   PERCENTILE_CONT(spentRevenue, 0.75) OVER (PARTITION BY month) AS ARPPU_P75,
--   PERCENTILE_CONT(spentRevenue, 0.9) OVER (PARTITION BY month) AS ARPPU_P90,
--   PERCENTILE_CONT(spentRevenue, 0.95) OVER (PARTITION BY month) AS ARPPU_P95,
--   PERCENTILE_CONT(spentRevenue, 0.99) OVER (PARTITION BY month) AS ARPPU_P99
-- FROM `media17-1119.DataLab_Timothy.JPSpenders`
-- WHERE spentRevenue >= 1000
--   AND month >= "2022-01-01"
-- ORDER BY month

-- ARPPU by sVIP group
-- SELECT DISTINCT
--   month,
--   COUNT(DISTINCT IF(spentRevenue < 1000, userID, NULL)) 
--     OVER (PARTITION BY month) AS spenders_below1K,
--   COUNT(DISTINCT IF(spentRevenue >= 1000 AND spentRevenue < 5000, userID, NULL)) 
--     OVER (PARTITION BY month) AS spenders_1K,
--   COUNT(DISTINCT IF(spentRevenue >= 5000 AND spentRevenue < 10000, userID, NULL)) 
--     OVER (PARTITION BY month) AS spenders_5K,
--   COUNT(DISTINCT IF(spentRevenue >= 10000 AND spentRevenue < 20000, userID, NULL)) 
--     OVER (PARTITION BY month) AS spenders_10K,
--   COUNT(DISTINCT IF(spentRevenue >= 20000 AND spentRevenue < 50000, userID, NULL)) 
--     OVER (PARTITION BY month) AS spenders_20K,
--   COUNT(DISTINCT IF(spentRevenue >= 50000, userID, NULL)) 
--     OVER (PARTITION BY month) AS spenders_50K,
--   SUM(IF(spentRevenue < 1000, spentRevenue, NULL)) 
--     OVER (PARTITION BY month) AS spentRevenue_below1K,
--   SUM(IF(spentRevenue >= 1000 AND spentRevenue < 5000, spentRevenue, NULL)) 
--     OVER (PARTITION BY month) AS spentRevenue_1K,
--   SUM(IF(spentRevenue >= 5000 AND spentRevenue < 10000, spentRevenue, NULL)) 
--     OVER (PARTITION BY month) AS spentRevenue_5K,
--   SUM(IF(spentRevenue >= 10000 AND spentRevenue < 20000, spentRevenue, NULL)) 
--     OVER (PARTITION BY month) AS spentRevenue_10K,
--   SUM(IF(spentRevenue >= 20000 AND spentRevenue < 50000, spentRevenue, NULL)) 
--     OVER (PARTITION BY month) AS spentRevenue_20K,
--   SUM(IF(spentRevenue >= 50000, spentRevenue, NULL)) 
--     OVER (PARTITION BY month) AS spentRevenue_50K,
--   AVG(IF(spentRevenue < 1000, spentRevenue, NULL)) 
--     OVER (PARTITION BY month) AS ARPPU_below1K,
--   AVG(IF(spentRevenue >= 1000 AND spentRevenue < 5000, spentRevenue, NULL)) 
--     OVER (PARTITION BY month) AS ARPPU_1K,
--   AVG(IF(spentRevenue >= 5000 AND spentRevenue < 10000, spentRevenue, NULL)) 
--     OVER (PARTITION BY month) AS ARPPU_5K,
--   AVG(IF(spentRevenue >= 10000 AND spentRevenue < 20000, spentRevenue, NULL)) 
--     OVER (PARTITION BY month) AS ARPPU_10K,
--   AVG(IF(spentRevenue >= 20000 AND spentRevenue < 50000, spentRevenue, NULL)) 
--     OVER (PARTITION BY month) AS ARPPU_20K,
--   AVG(IF(spentRevenue >= 50000, spentRevenue, NULL)) 
--     OVER (PARTITION BY month) AS ARPPU_50K
-- FROM `media17-1119.DataLab_Timothy.JPSpenders`
-- WHERE month >= "2022-01-01"
-- ORDER BY month