DECLARE startDate DATE DEFAULT DATE("2022-03-01");
DECLARE endDate DATE DEFAULT DATE("2022-11-24");
DECLARE platform_par ARRAY <STRING> DEFAULT ['ANDROID', 'IOS'];
DECLARE app_id_par ARRAY <STRING> DEFAULT ['com.machipopo.media17', "id988259048"];
DECLARE operationRegionGroup_par STRING DEFAULT "Taiwan";
DECLARE geo_par STRING DEFAULT "TW";
DECLARE media_source_par STRING DEFAULT "social";

WITH
  After AS (
    SELECT
      timeZoneDate,
      platform,
      IFNULL(media_source, agency) AS media_source,
      campaign,
      SUM(InstallCnt) AS InstallCnt,
      SUM(RegisterCnt) AS RegisterCnt,
      SUM(cost) AS cost
    FROM `media17-1119.MatomoDataSource.UAAggrTable`
    WHERE timeZoneDate BETWEEN startDate AND endDate
      AND platform IN UNNEST(platform_par)
      AND operationRegionGroup = operationRegionGroup_par
      AND media_source = media_source_par
    GROUP BY 
      timeZoneDate,
      platform,
      media_source,
      campaign
  )
  ,Install AS (
    SELECT
      DATE(timestamp_start_utc, IFNULL(ORG.timezone, 'Asia/Taipei')) AS timeZoneDate,
      platform,
      IFNULL(DMSCL.appsflyerInfo.media_source, DMSCL.appsflyerInfo.agency) AS media_source,
      DMSCL.appsflyerInfo.campaign,
      COUNT(1) AS InstallCnt
    FROM `MatomoDataMart.DeviceMediaSourceChangeLog` AS DMSCL
    LEFT JOIN `media17-1119.MatomoCore.lookup_region` AS ORG
      ON DMSCL.appsflyerInfo.country_code = ORG.country_code
      AND DMSCL.timestamp_start_utc >= ORG.groupStartTime
      AND DMSCL.timestamp_start_utc < ORG.groupEndTime
    WHERE DATE(timestamp_start_utc, IFNULL(ORG.timezone, 'Asia/Taipei')) BETWEEN startDate AND endDate
      AND DMSCL.platform IN UNNEST(platform_par)
      AND IFNULL(ORG.operationRegionGroup, 'RoW') = operationRegionGroup_par
      AND IFNULL(DMSCL.appsflyerInfo.media_source, DMSCL.appsflyerInfo.agency) = media_source_par
    GROUP BY 
      timeZoneDate,
      platform,
      media_source,
      campaign
  )
  ,Register AS (
    SELECT 
      UMSC.timeZoneDate,
      platform,
      IFNULL(UMSC.appsflyerInfo.media_source, UMSC.appsflyerInfo.agency) AS media_source,
      UMSC.appsflyerInfo.campaign,
      COUNT(DISTINCT userID) AS RegisterCnt
    FROM `MatomoDataMart.UserMediaSourceChangeLog_S2S` AS UMSC
    LEFT JOIN `media17-1119.MatomoCore.dim_userdimension` UD
      USING(userID)
    LEFT JOIN `media17-1119.MatomoCore.lookup_region` AS ORG
      ON UD.region.registerCountry = ORG.country
      AND UMSC.timeZoneDate >= DATE(ORG.groupStartTime, ORG.timeZone)
      AND UMSC.timeZoneDate < DATE(ORG.groupEndTime, ORG.timeZone)
    WHERE UMSC.timeZoneDate BETWEEN startDate AND endDate
      AND UMSC.userType = 'New'
      AND UMSC.platform IN UNNEST(platform_par)
      AND IF(UD.region.registerCountry IS NOT NULL AND UD.region.registerCountry != 'Unknown', IFNULL(ORG.operationRegionGroup, 'RoW'), 'Unknown') = operationRegionGroup_par
      AND IFNULL(UMSC.appsflyerInfo.media_source, UMSC.appsflyerInfo.agency) = media_source_par
    GROUP BY 
      timeZoneDate,
      platform,
      media_source,
      campaign
  )
  ,GeoCost AS (
    SELECT
      DATE(`date`) AS timeZoneDate,
      CASE 
        WHEN app_id = 'id988259048' THEN 'IOS'
        WHEN app_id = 'com.machipopo.media17' THEN 'ANDROID'
      END AS platform,
      media_source,
      campaign,
      SUM(cost) AS cost
    FROM `media17-1119.AF_cost.geo_s3_v2`
    WHERE DATE(`date`) BETWEEN startDate AND endDate
      AND app_id IN UNNEST(app_id_par)
      AND geo = geo_par
      AND media_source = media_source_par
    GROUP BY 
      timeZoneDate,
      platform,
      media_source,
      campaign
  )
SELECT
  COALESCE(A.timeZoneDate, I.timeZoneDate, R.timeZoneDate, C.timeZoneDate) AS timeZoneDate,
  COALESCE(A.platform, I.platform, R.platform, C.platform) AS platform,
  COALESCE(A.media_source, I.media_source, R.media_source, C.media_source) AS media_source,
  COALESCE(A.campaign, I.campaign, R.campaign, C.campaign) AS campaign,
  A.InstallCnt AS InstallCnt_after,
  I.InstallCnt AS InstallCnt_before,
  ABS(IFNULL(A.InstallCnt, 0) - IFNULL(I.InstallCnt, 0)) AS InstallCnt_diff,
  A.RegisterCnt AS RegisterCnt_after,
  R.RegisterCnt AS RegisterCnt_before,
  ABS(IFNULL(A.RegisterCnt, 0) - IFNULL(R.RegisterCnt, 0)) AS RegisterCnt_diff,
  A.cost AS cost_after,
  C.cost AS cost_geo,
  ABS(ROUND(IFNULL(A.cost, 0) - IFNULL(C.cost, 0), 3)) AS cost_diff,
FROM After AS A
FULL JOIN Install AS I
  ON A.timeZoneDate = I.timeZoneDate
  AND A.platform = I.platform
  AND A.media_source = I.media_source
  AND IFNULL(A.campaign, '') = IFNULL(I.campaign, '')
FULL JOIN Register AS R
  ON A.timeZoneDate = R.timeZoneDate
  AND A.platform = R.platform
  AND A.media_source = R.media_source
  AND IFNULL(A.campaign, '') = IFNULL(R.campaign, '') 
FULL JOIN GeoCost AS C
  ON A.timeZoneDate = C.timeZoneDate
  AND A.platform = C.platform
  AND A.media_source = C.media_source
  AND IFNULL(A.campaign, '') = IFNULL(C.campaign, '') 
ORDER BY 
  InstallCnt_diff DESC, 
  RegisterCnt_diff DESC,
  cost_diff DESC