WITH
  NewVLevel AS (
    SELECT DISTINCT
      userID,
      LAST_VALUE(newLevel) OVER (
        PARTITION BY userID 
        ORDER BY timestamp
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
      ) AS vLevel
    FROM `media17-1119.BackendEvent.VLevelUpdate`
    WHERE isSandbox = FALSE
      AND DATE(timestamp) >= DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 1 MONTH)
  )
SELECT 
  V.userID,
  UD.profile.openID,
  V.vLevel,
  SUM(P.point) AS purchasedPoints_LastMonth,
  UD.purchaseInfo.lifeTimeSpent
FROM NewVLevel AS V
INNER JOIN `MatomoCore.dim_userdimension` AS UD
  ON V.userID = UD.userID
  AND UD.region.registerCountry = "United States"
LEFT JOIN `media17-1119.MatomoDataSource.PayingBehaviorAssetGain` AS P
  ON V.userID = P.user.userID
  AND P.tzMonth = DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 1 MONTH)
  AND P.isPurchase = TRUE
  AND P.RefundType = "Excluding Refund Records"
  AND P.operationRegionGroup = "United States"
WHERE V.vLevel > 0
GROUP BY userID, openID, vLevel, lifeTimeSpent
ORDER BY lifeTimeSpent DESC