WITH
  DateRange AS(
    SELECT
      -- DATE_SUB(CURRENT_DATE('Asia/Taipei'), INTERVAL 7 DAY) AS dateStart,
      DATE("2018-01-01") AS dateStart,
      CURRENT_DATE('Asia/Taipei') AS dateEnd
  )
  ,MonthlySpentRevenue AS(
    SELECT
      DATE_TRUNC(DATE(timestamp_utc, IFNULL(timezone, 'Asia/Taipei')), MONTH) AS month,
      receiver_inferStreamerRegionGroup AS operationRegionGroup,
      user_id AS userID,
      operationRegionGroup AS senderOperationRegionGroup,
      DATE_TRUNC(DATE(registerTime, IFNULL(timezone, "Asia/Taipei")), MONTH) AS registerMonth,
      SUM(listPurchaseIncome) as spentRevenue
    FROM
      `media17-1119.MatomoCore.fact_usage` AS PUI
    WHERE
      DATE(timestamp_utc, IFNULL(timezone, 'Asia/Taipei')) BETWEEN
        (SELECT dateStart FROM DateRange) AND (SELECT dateEnd FROM DateRange)
      AND giftID NOT IN (
        'expiredPaidGiftID',
        'expiredFreeGiftID',
        'system_recycle',
        'system_cancel_order',
        'system_no_reason_recycle'
      )
      -- Revenue Remove GamePool lose(user win) usage and GamePool bet usage
      AND NOT (
        user_id IN ('016a2c96-1d1d-4530-97d7-fb3e9866bc7e', 'bb4582dc-3657-4360-9fe8-64809509a2ff')
        AND giftID IN (
            'fruit_farm_gpool_lose_points'
        )
      )
      AND NOT (
        receive_user_id IN ('016a2c96-1d1d-4530-97d7-fb3e9866bc7e', 'bb4582dc-3657-4360-9fe8-64809509a2ff')
        AND giftID IN (
            'fruit_farm_user_bet_points'
        )
      )
    GROUP BY
      month,
      operationRegionGroup,
      userID,
      senderOperationRegionGroup,
      registerMonth
  )
  ,TopSpender AS (
    SELECT *
    FROM MonthlySpentRevenue
    WHERE spentRevenue >= 1000
  )
  ,FirstTimeTopSpender AS (
    SELECT
      userID,
      MIN(month) AS firstMonth
    FROM MonthlySpentRevenue
    WHERE spentRevenue >= 1000
    GROUP BY userID
  )
  ,TopSpenderSegment AS (
    SELECT
      TS.month,
      TS.operationRegionGroup,
      TS.userID,
      TS.senderOperationRegionGroup,
      TS.registerMonth,
      TS.spentRevenue,
      CASE
        WHEN TS.month = TS.registerMonth THEN "New User"
        WHEN TS.month = FTTS.firstMonth THEN "Existing User"
        WHEN TS.month > FTTS.firstMonth THEN "Existing Top Spender"
        ELSE "Not Yet"
      END AS conversionType,
      CASE
        WHEN TS.spentRevenue >= 1000 AND TS.spentRevenue < 10000 THEN "1K~10K"
        WHEN TS.spentRevenue >= 10000 AND TS.spentRevenue < 100000 THEN "10K~100K"
        WHEN TS.spentRevenue >= 100000 THEN ">=100K"
      END AS spenderLevel,
      DATE_DIFF(TS.month, TS.registerMonth, MONTH) AS monthFromRegister,
      DATE_DIFF(TS.month, LAG(TS.month) OVER (PARTITION BY TS.userID ORDER BY TS.month), MONTH) AS monthFromLast,
      DATE_DIFF(LEAD(TS.month) OVER (PARTITION BY TS.userID ORDER BY TS.month), TS.month, MONTH) AS monthToNext,
    FROM TopSpender AS TS
    LEFT JOIN FirstTimeTopSpender AS FTTS
      ON TS.userID = FTTS.userID
  )
  ,RegularSpenderSegment AS (
    SELECT
      month,
      operationRegionGroup,
      userID,
      senderOperationRegionGroup,
      registerMonth,
      spentRevenue,
      "Not Yet" AS conversionType,
      CASE
        WHEN spentRevenue < 100 THEN "<100"
        WHEN spentRevenue >= 100 AND spentRevenue < 1000 THEN "100~1K"
      END AS spenderLevel,
      NULL AS monthFromRegister,
      NULL AS monthFromLast,
      NULL AS monthToNext,
    FROM MonthlySpentRevenue AS TS
    WHERE TS.spentRevenue < 1000
  )
  ,SpenderSegment AS (
    (SELECT * FROM TopSpenderSegment)
    UNION ALL
    (SELECT * FROM RegularSpenderSegment)
  )
  ,Registers AS (
    SELECT
      tzDate AS month,
      operationRegionGroup,
      SUM(numAttributionType) AS registers
    FROM `media17-1119.MatomoDataSourceForKPI.NewRegistration_Monthly`
    GROUP BY month, operationRegionGroup
  )
  ,ExistingMAUList AS (
    SELECT
      DATE_TRUNC(DUB.timezoneDate, MONTH) AS month,
      DUB.operationRegionGroup,
      userID,
      DATE_TRUNC(DUB.registerDate, MONTH) AS registerMonth
    FROM `MatomoDataMart.DailyUserBehavior_ViewRegion` AS DUB
    WHERE DATE_TRUNC(DUB.registerDate, MONTH) < DATE_TRUNC(DUB.timezoneDate, MONTH)
  )
  ,ExistingNonTopMAU AS (
    SELECT
      T1.month,
      T1.operationRegionGroup,
      COUNT(DISTINCT T1.userID) AS existingNonTopMAU
    FROM ExistingMAUList AS T1
    LEFT JOIN FirstTimeTopSpender AS T2
      ON T1.userID = T2.userID
    WHERE T2.firstMonth IS NULL 
      OR T2.firstMonth >= T1.month
    GROUP BY month, operationRegionGroup
  )
  ,FinalTable AS (
    SELECT
      S.month,
      S.operationRegionGroup,
      S.userID,
      S.senderOperationRegionGroup,
      S.registerMonth,
      S.spentRevenue,
      S.conversionType,
      S.spenderLevel,
      S.monthFromRegister,
      S.monthFromLast,
      S.monthToNext,
      R.registers,
      U.existingNonTopMAU
    FROM SpenderSegment AS S
    LEFT JOIN Registers AS R
      USING(month, operationRegionGroup)
    LEFT JOIN ExistingNonTopMAU AS U
      USING(month, operationRegionGroup)
    ORDER BY month, operationRegionGroup
  )
SELECT
  month,
  SUM(IF(spentRevenue >= 1000, spentRevenue, 0)) AS topSpentRevenue,
  SUM(IF(spentRevenue < 1000, spentRevenue, 0)) AS regularSpentRevenue,
  COUNTIF(spentRevenue >= 1000) AS topSpenders,
  COUNTIF(spentRevenue < 1000) AS regularSpenders,
  COUNTIF(spentRevenue >= 1000 AND conversionType = "New User") AS newUserToTopSpender,
  COUNTIF(spentRevenue >= 1000 AND conversionType = "Existing User") AS existingUserToTopSpender,
  COUNTIF(spentRevenue >= 1000 AND conversionType = "Existing Top Spender") AS existingTopSpender,
  COUNTIF(spentRevenue >= 1000 AND conversionType = "New User")/AVG(registers) AS conversionRate_newUser,
  COUNTIF(spentRevenue >= 1000 AND conversionType = "Existing User")/AVG(existingNonTopMAU) AS conversionRate_existingUser,
  AVG(IF(spentRevenue >= 1000 AND conversionType = "Existing Top Spender", monthToNext, NULL)) AS resurrectMonth,
  COUNTIF(spentRevenue >= 1000 AND (monthToNext > 1 OR monthToNext IS NULL))/COUNTIF(spentRevenue >= 1000) AS churnRate_1M,
  COUNTIF(spentRevenue >= 1000 AND (monthToNext > 3 OR monthToNext IS NULL))/COUNTIF(spentRevenue >= 1000) AS churnRate_3M,
  COUNTIF(spentRevenue >= 1000 AND (monthToNext > 6 OR monthToNext IS NULL))/COUNTIF(spentRevenue >= 1000) AS churnRate_6M,
  AVG(IF(spentRevenue >= 1000, spentRevenue, NULL)) AS ARPPU
FROM FinalTable
WHERE operationRegionGroup = "Japan" AND month >= "2022-07-01"
GROUP BY month, operationRegionGroup
ORDER BY month, operationRegionGroup