WITH
  Income AS (
    SELECT
        DATE(
            PUI.timestamp_utc,
            PUI.receiver_inferStreamerTimezone
        ) AS tzDate,
        PUI.receive_user_id AS userID,
        SUM(PUI.receive_point) AS dailyReceivedPoints,
        SUM(PUI.listPurchaseIncome) AS dailyReceivedPrice
    FROM
        `media17-1119.MatomoCore.fact_usage` PUI
    WHERE
        DATE(
            PUI.timestamp_utc,
            PUI.receiver_inferStreamerTimezone
        ) BETWEEN "2022-06-01" AND '2022-09-05'
        AND DATE_SUB(
            DATE(PUI.timestamp_utc, 'Asia/Taipei'),
            INTERVAL 1 DAY
        ) < CURRENT_DATE('Asia/Taipei')
        AND PUI.giftID NOT IN (
            'expiredPaidGiftID',
            'expiredFreeGiftID',
            'system_recycle',
            'system_cancel_order',
            'system_no_reason_recycle'
        )
        -- Receive Revenue Remove GamePool lose(user win) usage and GamePool bet usage
        AND NOT (
            PUI.user_id IN ('016a2c96-1d1d-4530-97d7-fb3e9866bc7e', 'bb4582dc-3657-4360-9fe8-64809509a2ff') 
            AND PUI.giftID IN (
                'fruit_farm_gpool_lose_points'
            )
        )
        AND NOT (
            PUI.receive_user_id IN ('016a2c96-1d1d-4530-97d7-fb3e9866bc7e', 'bb4582dc-3657-4360-9fe8-64809509a2ff') 
            AND PUI.giftID IN (
                'fruit_farm_user_bet_points'
            )
        )
        AND receiver_inferStreamerRegionGroup = "United States"
    GROUP BY
        tzDate,
        userID
  )
  ,IncomeWithLevel AS (
    SELECT
      I.tzDate,
      I.userID,
      CASE 
        WHEN DUB.maxlevel BETWEEN  1 AND 10  THEN  'Level 1-10'
        WHEN DUB.maxlevel BETWEEN 11 AND 30  THEN  'Level 11-30'
        WHEN DUB.maxlevel BETWEEN 31 AND 50  THEN  'Level 31-50'
        WHEN DUB.maxlevel BETWEEN 51 AND 70  THEN  'Level 51-70'
        WHEN DUB.maxlevel BETWEEN 71 AND 100 THEN  'Level 71-100'
        WHEN 100 < DUB.maxlevel  THEN 'Level GT 100'
        ELSE 'OTHERS (ZERO or NULL)'
      END AS maxlevel,
      I.dailyReceivedPoints,
      I.dailyReceivedPrice
    FROM Income AS I
    LEFT JOIN `media17-1119.MatomoDataMart.DailyUserBehavior` AS DUB
      ON I.tzDate = DUB.timezoneDate
      AND I.userID = DUB.userID
      AND DUB.timezoneDate BETWEEN "2022-06-01" AND "2022-09-05"
  )
SELECT DISTINCT
  DATE_TRUNC(tzDate, MONTH) AS week,
  maxlevel,
  SUM(dailyReceivedPrice) OVER (PARTITION BY DATE_TRUNC(tzDate, MONTH), maxlevel) AS revenueByLevel,
  SUM(dailyReceivedPrice) OVER (PARTITION BY DATE_TRUNC(tzDate, MONTH)) AS revenue,
  SUM(dailyReceivedPrice) OVER (PARTITION BY DATE_TRUNC(tzDate, MONTH), maxlevel) /
  SUM(dailyReceivedPrice) OVER (PARTITION BY DATE_TRUNC(tzDate, MONTH)) AS contribution
FROM IncomeWithLevel
ORDER BY week, maxlevel