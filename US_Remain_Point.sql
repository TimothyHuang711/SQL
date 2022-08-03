-- US users' remian points by purchase channel and last active date 
-- with last date of spending on US streamer
WITH
  DateRange AS (
    SELECT
      DATE_SUB(CURRENT_DATE('Asia/Taipei'), INTERVAL 1 DAY) AS inputDateStart,
      DATE_SUB(CURRENT_DATE('Asia/Taipei'), INTERVAL 1 DAY) AS inputDateEnd
  )
  ,tzDateKeySet AS (
    SELECT DISTINCT twDate AS tzDate
    FROM UNNEST(
      GENERATE_DATE_ARRAY('2015-01-01', DATE_SUB(CURRENT_DATE('Asia/Taipei'), INTERVAL 1 DAY))
    ) AS twDate
  )
  ,Income AS (
    SELECT
      DATE(PGL.timestamp, IFNULL(ORG.timezone, 'Asia/Taipei')) AS tzDate,
      IF(UD.region.registerCountry IS NOT NULL
        AND UD.region.registerCountry != 'Unknown',
        IFNULL(ORG.operationRegionGroup, 'RoW'), 'Unknown') AS country,
      PGL.userID,
      CASE
        WHEN PGL.listPrice = 0 THEN 'Free'
        WHEN (UPPER(PGL.channel) like '%IOS%' OR UPPER(PGL.channel) like '%ANDROID%') THEN 'IAP'
        ELSE 'VIP'
      END AS PurchaseChannel,
      SUM(PGL.point) AS point,
      SUM(PGL.listPrice) AS price
    FROM `media17-1119.FinancePartition.PointGainLogWithAccountInfo` AS PGL
    LEFT JOIN `media17-1119.MatomoCore.dim_userdimension` UD
      ON UD.userID = PGL.userID
    INNER JOIN `media17-1119.MatomoCore.lookup_region` ORG
      ON ORG.country = UD.region.registerCountry
        AND PGL.timestamp >= ORG.groupStartTime
        AND PGL.timestamp < ORG.groupEndTime
        AND ORG.operationRegionGroup = "United States"
    WHERE
      DATE(PGL.timestamp, IFNULL(ORG.timezone, 'Asia/Taipei')) >= '2015-01-01'
      AND DATE(PGL.timestamp,'Asia/Taipei')>= '2015-01-01'
      AND PGL.productID NOT LIKE "ARMY_RELEASE"
      -- Gain Revenue Remove PGL of Game Pool, '016a2c96-1d1d-4530-97d7-fb3e9866bc7e' openID is FruitFarm
      AND PGL.userID not IN ('016a2c96-1d1d-4530-97d7-fb3e9866bc7e')
    GROUP BY
      tzDate,
      country,
      PurchaseChannel,
      userID
  )
  ,Usage AS (
    SELECT
      DATE(PUL.timestamp_utc, IFNULL(ORG.timezone, 'Asia/Taipei')) AS tzDate,
      IF(PUL.registerCountry != 'Unknown' AND PUL.registerCountry IS NOT NULL,
        IFNULL(ORG.operationRegionGroup, 'RoW'), 'Unknown') AS country,
      user_id AS userID,
      CASE
        WHEN PUL.listPurchaseIncome = 0 THEN 'Free'
        WHEN (UPPER(PGL.channel) like '%IOS%' OR UPPER(PGL.channel) like '%ANDROID%') THEN 'IAP'
        ELSE 'VIP'
      END AS PurchaseChannel,
      SUM(send_point) AS point,
      SUM(PUL.listPurchaseIncome) AS price
    FROM `media17-1119.MatomoCore.fact_usage` AS PUL
    INNER JOIN `media17-1119.MatomoCore.lookup_region` ORG
    ON PUL.registerCountry=ORG.country
      AND PUL.timestamp_utc>=ORG.groupStartTime
      AND PUL.timestamp_utc<ORG.groupEndTime
      AND ORG.operationRegionGroup = "United States"
      # join PGL to make sure the PUL channel can map exactly to PGL channel
    LEFT JOIN (
      SELECT
        bundleID,
        channel
      FROM `media17-1119.FinancePartition.PointGainLogWithAccountInfo`
      WHERE timestamp IS NOT NULL
      AND productID NOT LIKE "ARMY_RELEASE"
    ) AS PGL
    ON PUL.id=PGL.bundleID
    LEFT JOIN `media17-1119.MatomoCore.dim_userdimension` UD
    ON UD.userID = PUL.user_id
    WHERE
      DATE(PUL.timestamp_utc, IFNULL(ORG.timezone, 'Asia/Taipei')) >= '2015-01-01'
      -- Spend Revenue Remove PUL from Game Pool, '016a2c96-1d1d-4530-97d7-fb3e9866bc7e' openID is FruitFarm
      AND PUL.user_id NOT IN ('016a2c96-1d1d-4530-97d7-fb3e9866bc7e')
    GROUP BY
      tzDate,
      country,
      PurchaseChannel,
      user_id
  )
  ,KeySet AS (
    SELECT *
    FROM tzDateKeySet
    CROSS JOIN (
      SELECT
        country,
        PurchaseChannel,
        userID
      FROM Income
      UNION DISTINCT
      SELECT
        country,
        PurchaseChannel,
        userID
      FROM Usage
    )
  ),
  Remain AS(
    SELECT
      tzDate,
      country,
      userID,
      PurchaseChannel,
      IFNULL(Income.point, 0) - IFNULL(Usage.point, 0) AS remainPoint,
      IFNULL(Income.price, 0) - IFNULL(Usage.price, 0) AS remainPrice
    FROM KeySet
    FULL JOIN Income
      USING(tzDate, country, PurchaseChannel, userID)
    FULL JOIN Usage
      USING(tzDate, country, PurchaseChannel, userID)
  )
  ,CumRemainPoints As (
    SELECT DISTINCT 
      tzDate,
      userID,
      country,
      PurchaseChannel,
      SUM(remainPrice) OVER w2 AS remainPrice,
      SUM(remainPoint) OVER w2 AS remainPoint
    FROM Remain
    WINDOW
      w2 AS (
      PARTITION BY
        country,
        PurchaseChannel,
        userID
      ORDER BY
        tzDate ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    )
  )
  ,SpentOnUS AS (
    SELECT 
      spenderUserID AS userID
      ,MAX(timezoneDate) AS lastSpentOnUSDate
    FROM `media17-1119.MatomoDataSource.SpenderReport_DailyOverview`
    WHERE spentOperationRegionGroup = "United States"
      AND receiverOperationRegionGroup = "United States"
    GROUP BY userID
  )
  ,LastActiveDate AS (
    SELECT
      userID
      ,MAX(timezoneDate) AS lastActiveDate
    FROM `MatomoDataMart.DailyUserBehavior`
    WHERE operationRegionGroup = "United States"
    GROUP BY userID
  )
  ,FinalResult AS (
    SELECT 
      CRP.userID
      ,UD.profile.openID
      ,CS.email
      ,CRP.PurchaseChannel
      ,CRP.remainPoint
      ,CRP.remainPrice
      ,LAD.lastActiveDate
      ,CASE
        WHEN DATE_DIFF(CRP.tzDate, LAD.lastActiveDate, DAY) <= 7 
          THEN 'Group A (0~7)'
        WHEN DATE_DIFF(CRP.tzDate, LAD.lastActiveDate, DAY) <= 28 
          THEN 'Group B (8~28)'
        WHEN DATE_DIFF(CRP.tzDate, LAD.lastActiveDate, DAY) <= 84 
          THEN 'Group C (29~84)'
        ELSE 'Group D (85~)'
      END AS lastActiveDateGroup
      ,S.lastSpentOnUSDate
    FROM CumRemainPoints AS CRP
    LEFT JOIN `MatomoCore.dim_userdimension` AS UD
      USING(userID)
    LEFT JOIN LastActiveDate AS LAD
      USING(userID)
    LEFT JOIN SpentOnUS AS S
      USING(userID)
    LEFT JOIN `media17-1119.MatomoCore.dim_contracted_streamer` AS CS
      USING(userID)
    WHERE 
      CRP.tzDate BETWEEN (SELECT inputDateStart FROM DateRange) AND (SELECT inputDateEnd FROM DateRange)
  )
SELECT 
  *
  ,remainPoint_VIP+remainPoint_IAP+remainPoint_Free AS remainPoint_All
  ,remainPrice_VIP+remainPrice_IAP+remainPrice_Free AS remainPrice_All
FROM FinalResult
  PIVOT (
    SUM(remainPoint) AS remainPoint
    ,SUM(remainPrice) AS remainPrice
    FOR PurchaseChannel IN ("VIP", "IAP", "Free")
  )
ORDER BY lastActiveDateGroup, remainPrice_All DESC