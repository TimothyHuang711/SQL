-- Daily view duration in April and May
SELECT 
  EXTRACT(MONTH FROM DATE(tzDate)) AS month
  ,EXTRACT(DAY FROM DATE(tzDate)) AS day
  ,SUM(viewDuration) / 3600 AS dailyViewDuration
FROM `media17-1119.MatomoDataMart.LivestreamPerformance` AS P
WHERE P.streamerOperationRegionGroup = 'United States'
  AND P.isContracted IS TRUE
  AND DATE(tzDate) BETWEEN '2022-04-01' AND '2022-05-31'
GROUP BY month, day

-- Average and total daily view duration in April and May
-- April: 1923.86 | 59139.56
-- May:   1722.36 | 55080.32
SELECT 
  DATE_TRUNC(DATE(tzDate), MONTH) AS month
  ,SUM(viewDuration) / 3600 / COUNT(DISTINCT tzDate) AS avgDailyViewDuration
  ,SUM(viewDuration) / 3600 AS totalDailyViewDuration
FROM `media17-1119.MatomoDataMart.LivestreamPerformance` AS P
WHERE P.streamerOperationRegionGroup = 'United States'
  AND P.isContracted IS TRUE
  AND DATE(tzDate) BETWEEN '2022-04-01' AND '2022-05-31'
GROUP BY month

-- Daily live stream duration in April and May
SELECT 
  EXTRACT(MONTH FROM DATE(tzDate)) AS month
  ,EXTRACT(DAY FROM DATE(tzDate)) AS day
  ,SUM(livestreamDuration) / 3600 AS dailyLivestreamDuration
FROM `media17-1119.MatomoDataMart.LivestreamPerformance` AS P
WHERE P.streamerOperationRegionGroup = 'United States'
  AND P.isContracted IS TRUE
  AND DATE(tzDate) BETWEEN '2022-04-01' AND '2022-05-31'
GROUP BY month, day

-- Average and total daily live stream duration in April and May
SELECT 
  DATE_TRUNC(DATE(tzDate), MONTH) AS month
  ,SUM(livestreamDuration) / 3600 / COUNT(DISTINCT tzDate) AS avgDailyLivestreamDuration
  ,SUM(livestreamDuration) / 3600 AS totalDailyLivestreamDuration
FROM `media17-1119.MatomoDataMart.LivestreamPerformance` AS P
WHERE P.streamerOperationRegionGroup = 'United States'
  AND P.isContracted IS TRUE
  AND DATE(tzDate) BETWEEN '2022-04-01' AND '2022-05-31'
GROUP BY month

-- Total viewer by viewer country in April and May
(SELECT 
  DATE_TRUNC(DATE(LSVI.beginTime, LSVI.streamer.timezone), MONTH) AS month
  ,LSVI.viewer.operationRegionGroup AS viewerOperationRegionGroup
  ,'Viewer Counts' AS metric
  ,COUNT(DISTINCT IF(LSVI.viewer.viewDuration IS NOT NULL, LSVI.viewer.userID, NULL)) AS value
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LSVI
WHERE LSVI.streamer.OperationRegionGroup = 'United States'
  AND LSVI.streamer.isContracted IS TRUE
  AND DATE(LSVI.beginTime, LSVI.streamer.timezone) BETWEEN '2022-04-01' AND '2022-05-31'
GROUP BY month, viewerOperationRegionGroup
ORDER BY viewerOperationRegionGroup, month, metric)
UNION ALL

-- Total view duration by viewer region in April and May
(SELECT 
  DATE_TRUNC(DATE(LSVI.beginTime, LSVI.streamer.timezone), MONTH) AS month
  ,LSVI.viewer.operationRegionGroup AS viewerOperationRegionGroup
  ,'Total View Duration(Hrs)' AS metric
  ,SUM(LSVI.viewer.viewDuration) / 3600 AS value
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LSVI
WHERE LSVI.streamer.OperationRegionGroup = 'United States'
  AND LSVI.streamer.isContracted IS TRUE
  AND DATE(LSVI.beginTime, LSVI.streamer.timezone) BETWEEN '2022-04-01' AND '2022-05-31'
GROUP BY month, viewerOperationRegionGroup
ORDER BY viewerOperationRegionGroup, month, metric)
UNION ALL

-- Avg. view duration by viewr country in April and May
(SELECT 
  DATE_TRUNC(DATE(LSVI.beginTime, LSVI.streamer.timezone), MONTH) AS month
  ,LSVI.viewer.operationRegionGroup AS viewerOperationRegionGroup
  ,'Average View Duration(Mins)' AS metric
  ,SUM(LSVI.viewer.viewDuration) / 60 / COUNT(DISTINCT IF(LSVI.viewer.viewDuration IS NOT NULL, LSVI.viewer.userID, NULL)) AS value
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LSVI
WHERE LSVI.streamer.OperationRegionGroup = 'United States'
  AND LSVI.streamer.isContracted IS TRUE
  AND DATE(LSVI.beginTime, LSVI.streamer.timezone) BETWEEN '2022-04-01' AND '2022-05-31'
GROUP BY month, viewerOperationRegionGroup
ORDER BY viewerOperationRegionGroup, month, metric)

-- Whom did users in AU, CA, CO, MX, US watch in May segmented by user type (new or existing)?
SELECT 
  LSVI.viewer.operationRegionGroup AS viewerOperationRegionGroup
  ,LSVI.streamer.OperationRegionGroup AS streamerOperationRegionGroup
  ,IF(DATE(LSVI.viewer.registerTime, 'America/Los_Angeles') >= '2022-05-01', 'New', 'Existing') AS viewerType
  ,SUM(LSVI.viewer.viewDuration) / 3600 AS totalViewDuration
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LSVI
WHERE DATE(LSVI.beginTime, LSVI.streamer.timezone) BETWEEN '2022-05-01' AND '2022-05-31'
  AND LSVI.viewer.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
GROUP BY viewerOperationRegionGroup, streamerOperationRegionGroup, viewerType
ORDER BY viewerOperationRegionGroup, totalViewDuration DESC

-- Avg view duration of US users for diffrent streamer countries in April and May?
SELECT 
  DATE_TRUNC(DATE(LSVI.beginTime, LSVI.streamer.timezone), MONTH) AS month
  ,LSVI.viewer.operationRegionGroup AS viewerOperationRegionGroup
  ,LSVI.streamer.OperationRegionGroup AS streamerOperationRegionGroup
  ,SUM(LSVI.viewer.viewDuration)/60/COUNT(DISTINCT IF(LSVI.viewer.viewDuration IS NOT NULL, LSVI.viewer.userID, NULL)) AS avgViewDuration
FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo` AS LSVI
WHERE DATE(LSVI.beginTime, LSVI.streamer.timezone) BETWEEN '2022-04-01' AND '2022-05-31'
  AND LSVI.viewer.operationRegionGroup IN ('Australia', 'Canada', 'Colombia', 'Mexico', 'United States')
GROUP BY month, viewerOperationRegionGroup, streamerOperationRegionGroup
ORDER BY viewerOperationRegionGroup, avgViewDuration DESC