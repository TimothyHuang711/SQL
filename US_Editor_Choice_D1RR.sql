-- New user D1RR by if watch EC or not 
WITH
  NewUser AS (
    SELECT userID, DATE(profile.registerTime, "America/Los_Angeles") AS timezoneDateLA
    FROM `media17-1119.MatomoCore.dim_userdimension`
    WHERE region.registerCountry IN ("Australia", "Canada", "Colombia", "Mexico", "United States")
      AND DATE(profile.registerTime, "America/Los_Angeles") 
        BETWEEN "2022-05-01" AND "2022-06-30"
      AND EXTRACT(HOUR FROM DATETIME(profile.registerTime, "America/Los_Angeles"))
        BETWEEN 11 AND 17
  )
  ,ECViewer AS (
    SELECT DISTINCT 
      viewer.userID
      ,streamer.openID
      ,DATE(viewer.registerTime, "America/Los_Angeles") AS timezoneDateLA
    FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo`
    WHERE DATE(beginTime, "America/Los_Angeles") = DATE(viewer.registerTime, "America/Los_Angeles")
    AND viewer.registerCountry IN ("Australia", "Canada", "Colombia", "Mexico", "United States")
    AND (
      (
        streamer.openID = 'YUKAMUSIC' 
        AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) >= 12
        AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) <= 14 
        AND DATE(beginTime, "America/Los_Angeles") IN 
          ('2022-06-06', '2022-06-13', '2022-06-20','2022-06-27')
      ) OR (
        streamer.openID = 'NikkaPaloma' 
        AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) >= 13
        AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) <= 15
        AND DATE(beginTime, "America/Los_Angeles") IN 
          ('2022-06-06', '2022-06-13', '2022-06-20','2022-06-27')
      ) OR (
        streamer.openID = 'm.e.godempress' 
        AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) >= 14
        AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) <= 16 
        AND DATE(beginTime, "America/Los_Angeles") IN 
          ('2022-06-06', '2022-06-13', '2022-06-20','2022-06-27')
      ) OR (
        streamer.openID = 'michael_cocain' 
        AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) >= 15
        AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) <= 17 
        AND DATE(beginTime, "America/Los_Angeles") IN 
          ('2022-06-06', '2022-06-13', '2022-06-20','2022-06-27')
      ) OR (
        streamer.openID = 'raeyanb' 
        AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) >= 16
        AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) <= 18
        AND DATE(beginTime, "America/Los_Angeles") IN 
          ('2022-06-06', '2022-06-13', '2022-06-20','2022-06-27')
      ) OR (
        streamer.openID = 'ShayneReigns' 
        AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) >= 12
        AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) <= 14
        AND DATE(beginTime, "America/Los_Angeles") IN 
          ('2022-06-08', '2022-06-15', '2022-06-22','2022-06-29')
      ) OR (
        streamer.openID = 'keshajanaan' 
        AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) >= 13
        AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) <= 15
        AND DATE(beginTime, "America/Los_Angeles") IN 
          ('2022-06-08', '2022-06-15', '2022-06-22','2022-06-29')
      ) OR (
        streamer.openID = 'iamSantty' 
        AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) >= 14
        AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) <= 16
        AND DATE(beginTime, "America/Los_Angeles") IN 
          ('2022-06-08', '2022-06-15', '2022-06-22','2022-06-29')
      ) OR (
        streamer.openID = 'laurentorresmusic' 
        AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) >= 15
        AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) <= 17 
        AND DATE(beginTime, "America/Los_Angeles") IN 
          ('2022-06-08', '2022-06-15', '2022-06-22','2022-06-29')
      ) OR (
        streamer.openID = 'mrincredible197' 
        AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) >= 16
        AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) <= 18 
        AND DATE(beginTime, "America/Los_Angeles") IN 
          ('2022-06-08', '2022-06-15', '2022-06-22','2022-06-29')
      -- ) OR (
      --   streamer.openID = 'mrincredible197' 
      --   AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) > 12
      --   AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) < 14
      --   AND DATE(beginTime, "America/Los_Angeles") IN 
      --     ('2022-07-03', '2022-07-10', '2022-07-17','2022-07-24', '2022-07-31')
      -- ) OR (
      --   streamer.openID = 'catchamuse' 
      --   AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) > 13
      --   AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) < 15
      --   AND DATE(beginTime, "America/Los_Angeles") IN 
      --     ('2022-07-03', '2022-07-10', '2022-07-17','2022-07-24', '2022-07-31')
      -- ) OR (
      --   streamer.openID = 'iamSantty' 
      --   AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) > 14
      --   AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) < 16
      --   AND DATE(beginTime, "America/Los_Angeles") IN 
      --     ('2022-07-03', '2022-07-10', '2022-07-17','2022-07-24', '2022-07-31')
      -- ) OR (
      --   streamer.openID = 'HellYeahMel' 
      --   AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) > 15
      --   AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) < 17
      --   AND DATE(beginTime, "America/Los_Angeles") IN 
      --     ('2022-07-03', '2022-07-10', '2022-07-17','2022-07-24', '2022-07-31')
      -- ) OR (
      --   streamer.openID = 'baxs_20' 
      --   AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) > 16
      --   AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) < 18
      --   AND DATE(beginTime, "America/Los_Angeles") IN 
      --     ('2022-07-03', '2022-07-10', '2022-07-17','2022-07-24', '2022-07-31')
      -- ) OR (
      --   streamer.openID = 'mrincredible197' 
      --   AND EXTRACT(HOUR FROM DATETIME(endTime, "America/Los_Angeles")) > 17
      --   AND EXTRACT(HOUR FROM DATETIME(beginTime, "America/Los_Angeles")) < 19
      --   AND DATE(beginTime, "America/Los_Angeles") IN 
      --     ('2022-07-03', '2022-07-10', '2022-07-17','2022-07-24', '2022-07-31')
      )
    )
  )
  ,NonECViewer AS (
    SELECT DISTINCT viewer.userID
    FROM `media17-1119.MatomoDataMart.LiveStreamWithViewerInfo`
    WHERE DATE(beginTime, "America/Los_Angeles") BETWEEN "2022-05-01" AND "2022-06-30"
      AND DATE(beginTime, "America/Los_Angeles") = DATE(viewer.registerTime, "America/Los_Angeles")
    AND viewer.registerCountry IN ("Australia", "Canada", "Colombia", "Mexico", "United States")
      AND viewer.userID NOT IN (SELECT DISTINCT userID FROM ECViewer)
  )
  ,NewUserbyType AS (
    SELECT timezoneDateLA
      ,userID
      ,CASE
        WHEN userID IN (SELECT DISTINCT userID FROM ECViewer) THEN 'ECViwer'
        WHEN userID IN (SELECT DISTINCT userID FROM NonECViewer) THEN "Viewer"
        ELSE "Others"
      END AS userType
    FROM NewUser
  )
  ,NewUserD1Retention AS (
    SELECT timezoneDateLA
      ,userID
      ,userType
      ,RB.*
    FROM `media17-1119.MatomoDataMart.DailyUserRetention` AS DUR
    LEFT JOIN UNNEST(retainingBehaviors) AS RB
    INNER JOIN NewUserbyType AS NUT
      USING(userID)
    WHERE DUR.timezoneDate = DUR.registerDate
  )
  ,ECRetention AS (
    SELECT EC.timezoneDateLA
      ,EC.userID
      ,EC.openID
      ,RB.*
    FROM ECViewer AS EC
    LEFT JOIN `media17-1119.MatomoDataMart.DailyUserRetention` AS DUR
      ON EC.userID = DUR.userID
      AND EC.timezoneDateLA = DUR.timezoneDate
    LEFT JOIN UNNEST(retainingBehaviors) AS RB
    WHERE DUR.timezoneDate = DUR.registerDate
  )
-- D1RR by userType
-- SELECT timezoneDateLA
--   ,userType
--   ,COUNT(DISTINCT userID) AS DAU_new
--   ,COUNT(DISTINCT IF(dayDiff = 1, userID, NULL)) AS D1R
--   ,COUNT(DISTINCT IF(dayDiff = 1, userID, NULL))/COUNT(DISTINCT userID) AS D1RR
-- FROM NewUserD1Retention
-- GROUP BY timezoneDateLA, userType
-- ORDER BY timezoneDateLA, userType

-- D1RR for ECView
SELECT timezoneDateLA
  ,openID
  ,COUNT(DISTINCT userID) AS DAU_new
  ,COUNT(DISTINCT IF(dayDiff = 1, userID, NULL)) AS D1R
  ,COUNT(DISTINCT IF(dayDiff = 1, userID, NULL))/COUNT(DISTINCT userID) AS D1RR
FROM ECRetention
GROUP BY timezoneDateLA, openID
ORDER BY timezoneDateLA, openID

-- New user retention 11am ~ 18pm ever yday from May to June
WITH
  NewUser AS (
    SELECT userID
      ,DATE(profile.registerTime, "America/Los_Angeles") AS timezoneDateLA
    FROM `media17-1119.MatomoCore.dim_userdimension`
    WHERE region.registerCountry IN ("Australia", "Canada", "Colombia", "Mexico", "United States")
      AND DATE(profile.registerTime, "America/Los_Angeles") 
        BETWEEN "2022-05-01" AND "2022-06-30"
      AND EXTRACT(HOUR FROM DATETIME(profile.registerTime, "America/Los_Angeles"))
        BETWEEN 11 AND 18
  )
  ,NewUserRetention AS (
    SELECT
      *
    FROM `media17-1119.MatomoDataMart.DailyUserRetention` AS DUR
    LEFT JOIN UNNEST(DUR.retainingBehaviors) AS RB
    INNER JOIN NewUser
      USING(userID)
    WHERE DUR.timezoneDate = DUR.registerDate
  )
  ,D0View AS (
    SELECT DISTINCT userID
    FROM NewUserRetention
    WHERE dayDiff = 0 AND view.duration IS NOT NULL
  )

-- D1RR overall and by D0View
SELECT
  timezoneDateLA
  ,COUNT(DISTINCT IF(dayDiff = 0, userID, NULL)) AS DAU
  ,COUNT(DISTINCT IF(dayDiff = 1, userID, NULL)) AS D1R
  ,SAFE_DIVIDE(
    COUNT(DISTINCT IF(dayDiff = 1, userID, NULL)),
    COUNT(DISTINCT IF(dayDiff = 0, userID, NULL))
  ) AS D1RR
  ,COUNT(DISTINCT IF(dayDiff = 0 AND userID IN (SELECT userID FROM D0View), userID, NULL)) AS DAU_view
  ,COUNT(DISTINCT IF(dayDiff = 0 AND userID NOT IN (SELECT userID FROM D0View), userID, NULL)) AS DAU_notview
  ,SAFE_DIVIDE(
    COUNT(DISTINCT IF(dayDiff = 1 AND userID IN (SELECT userID FROM D0View), userID, NULL)),
    COUNT(DISTINCT IF(dayDiff = 0 AND userID IN (SELECT userID FROM D0View), userID, NULL))
  ) AS D1RR_view
  ,SAFE_DIVIDE(
    COUNT(DISTINCT IF(dayDiff = 1 AND userID NOT IN (SELECT userID FROM D0View), userID, NULL)),
    COUNT(DISTINCT IF(dayDiff = 0 AND userID NOT IN (SELECT userID FROM D0View), userID, NULL))
  ) AS D1RR_notview
FROM NewUserRetention AS NUR
GROUP BY timezoneDateLA
ORDER BY timezoneDateLA