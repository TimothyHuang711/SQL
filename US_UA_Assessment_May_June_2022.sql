-- Comparison of UA performance at AU, CA and US for May to June 2022.
-- Overall
WITH
  -- Correct cost values from Felix
  Cost AS (
    SELECT 'Australia' AS operationRegionGroup, 10830 AS cost
    UNION ALL
    SELECT 'Canada' AS operationRegionGroup, 15831 AS cost
    UNION ALL
    SELECT 'United States' AS operationRegionGroup, 205213 AS cost
    UNION ALL
    SELECT 'Mexico' AS operationRegionGroup, 34531 AS cost
    UNION ALL
    SELECT 'Colombia' AS operationRegionGroup, 6157 AS cost
    UNION ALL
    SELECT 'Taiwan' AS operationRegionGroup, 61463 AS cost
  )
  ,UA AS (
    SELECT 
      -- Base
      operationRegionGroup
      -- Cost
      ,AVG(C.cost) AS cost
      ,SUM(InstallCnt) AS installCnt
      ,AVG(C.cost)/SUM(InstallCnt) AS CPI
      ,SUM(RegisterCnt) AS registerCnt
      ,SUM(RegisterCnt)/SUM(InstallCnt) AS registerRate
      ,AVG(C.cost)/SUM(RegisterCnt) AS CPR
      -- Retention
      ,SUM(RetentionD1) AS retentionD1
      ,SUM(RetentionD1)/SUM(RegisterCnt) AS retentionRateD1
      ,AVG(C.cost)/SUM(RetentionD1) AS CPRetainedD1
      ,SUM(RetentionD7) AS retentionD7
      ,SUM(RetentionD7)/SUM(RegisterCnt) AS retentionRateD7
      ,AVG(C.cost)/SUM(RetentionD7) AS CPRetainedD7
      ,SUM(RetentionD14) AS retentionD14
      ,SUM(RetentionD14)/SUM(RegisterCnt) AS retentionRateD14
      ,AVG(C.cost)/SUM(RetentionD14) AS CPRetainedD14
      ,SUM(RetentionD30) AS retentionD30
      ,SUM(RetentionD30)/SUM(RegisterCnt) AS retentionRateD30
      ,AVG(C.cost)/SUM(RetentionD30) AS CPRetainedD30
      -- Payer
      ,SUM(numPayerD0) AS numPayerD0
      ,SUM(numPayerD0)/SUM(RegisterCnt) AS payRateD0
      ,AVG(C.cost)/SUM(numPayerD0) AS CPPayerD0
      ,SUM(numPayer1D) AS numPayer1D
      ,SUM(numPayer1D)/SUM(RegisterCnt) AS payRate1D
      ,AVG(C.cost)/SUM(numPayer1D) AS CPPayer1D
      ,SUM(numPayer7D) AS numPayer7D
      ,SUM(numPayer7D)/SUM(RegisterCnt) AS payRate7D
      ,AVG(C.cost)/SUM(numPayer7D) AS CPPayer7D
      ,SUM(numPayer14D) AS numPayer14D
      ,SUM(numPayer14D)/SUM(RegisterCnt) AS payRate14D
      ,AVG(C.cost)/SUM(numPayer14D) AS CPPayer14D
      ,SUM(numPayer30D) AS numPayer30D
      ,SUM(numPayer30D)/SUM(RegisterCnt) AS payRate30D
      ,AVG(C.cost)/SUM(numPayer30D) AS CPPayer30D
      -- Spender
      ,SUM(numSpenderD0) AS numSpenderD0
      ,SUM(numSpenderD0)/SUM(RegisterCnt) AS spendRateD0
      ,AVG(C.cost)/SUM(numSpenderD0) AS CPSpenderD0
      ,SUM(numSpender1D) AS numSpender1D
      ,SUM(numSpender1D)/SUM(RegisterCnt) AS spendRate1D
      ,AVG(C.cost)/SUM(numSpender1D) AS CPSpender1D
      ,SUM(numSpender7D) AS numSpender7D
      ,SUM(numSpender7D)/SUM(RegisterCnt) AS spendRate7D
      ,AVG(C.cost)/SUM(numSpender7D) AS CPSpender7D
      ,SUM(numSpender14D) AS numSpender14D
      ,SUM(numSpender14D)/SUM(RegisterCnt) AS spendRate14D
      ,AVG(C.cost)/SUM(numSpender14D) AS CPSpender14D
      ,SUM(numSpender30D) AS numSpender30D
      ,SUM(numSpender30D)/SUM(RegisterCnt) AS spendRate30D
      ,AVG(C.cost)/SUM(numSpender30D) AS CPSpender30D
      -- User Value
      ,SUM(accuAmountD0) AS accuAmountD0
      ,SUM(accuAmountD0)/AVG(C.cost) AS ROASD0
      ,SUM(accuAmountD0)/SUM(RegisterCnt) AS ARPUD0
      ,SUM(accuAmount1D) AS accuAmount1D
      ,SUM(accuAmount1D)/AVG(C.cost) AS ROAS1D
      ,SUM(accuAmount1D)/SUM(RegisterCnt) AS ARPU1D
      ,SUM(accuAmount7D) AS accuAmount7D
      ,SUM(accuAmount7D)/AVG(C.cost) AS ROAS7D
      ,SUM(accuAmount7D)/SUM(RegisterCnt) AS ARPU7D
      ,SUM(accuAmount14D) AS accuAmount14D
      ,SUM(accuAmount14D)/AVG(C.cost) AS ROAS14D
      ,SUM(accuAmount14D)/SUM(RegisterCnt) AS ARPU14D
      ,SUM(accuAmount30D) AS accuAmount30D
      ,SUM(accuAmount30D)/AVG(C.cost) AS ROAS30D
      ,SUM(accuAmount30D)/SUM(RegisterCnt) AS ARPU30D
    FROM `media17-1119.MatomoDataSource.UAAggrTable` 
    INNER JOIN Cost AS C
      USING(operationRegionGroup)
    WHERE timeZoneDate BETWEEN '2022-05-01' AND '2022-06-30'
      AND operationRegionGroup IN ('Australia', 'Canada', 'United States', 'Colombia', 'Mexico', 'Taiwan')
      AND (
        (platform = 'ANDROID' AND attributionType = 'Regular')
        OR (platform = 'IOS' AND attributionType IN ('Organic', 'Regular'))
      )
    GROUP BY operationRegionGroup
  )
  -- User platform
  ,UserPlatform AS (
    SELECT DISTINCT
      userID,
      platform
    FROM `media17-1119.MatomoDataMart.UserMediaSourceChangeLog_S2S` AS UMSC
    LEFT JOIN `media17-1119.MatomoCore.dim_userdimension` UD
    USING(userID)
    LEFT JOIN`media17-1119.MatomoCore.lookup_region` AS ORG
    ON region.registerCountry = ORG.country
      AND UMSC.timeZoneDate >= DATE(ORG.groupStartTime, ORG.timeZone)
      AND UMSC.timeZoneDate < DATE(ORG.groupEndTime, ORG.timeZone)
    WHERE userType = 'New'
      AND DATE(UD.profile.registerTime, UMSC.timeZone) BETWEEN '2022-05-01' AND '2022-06-30'
      AND UD.region.registerCountry IN (
        'Australia'
        ,'Canada'
        ,'United States'
        ,'Colombia'
        ,'Mexico'
        ,'Taiwan'
      )
      AND (
        (platform = 'ANDROID' AND appsflyerInfo.attributionType = 'Regular')
        OR (platform = 'IOS' AND appsflyerInfo.attributionType IN ('Organic', 'Regular'))
      )
  )
  -- US streamer region
  ,DUB AS (
    SELECT
      registerCountry AS operationRegionGroup,
      COUNT(DISTINCT IF(follow IS NOT NULL, userID, NULL)) AS newFollower,
      SUM(follow.streamerCnt) AS newFollowCount,
      COUNT(DISTINCT IF(snack IS NOT NULL, userID, NULL)) AS snacker,
      SUM(snack.totalCount) AS totalSnackCount,
      SUM(ARRAY_LENGTH(snack.receivers)) AS totalSnackStreamer,
      COUNT(DISTINCT IF(gift IS NOT NULL, userID, NULL)) AS gifter,
      SUM(gift.totalCount) AS totalGiftCount,
      SUM(gift.totalPoint) AS totalGiftPoint,
      SUM(gift.totalListPrice) AS totalGiftPrice,
      SUM(ARRAY_LENGTH(gift.receivers)) AS totalGiftStreamer,
      COUNT(DISTINCT IF( `view` IS NOT NULL, userID, NULL)) AS viewer,
      SUM(`view`.duration)/60 AS totalViewDuration_mins,
      SUM(`view`.streamerCnt) AS numViewStreamer,
      COUNT(DISTINCT IF(comment IS NOT NULL, userID, NULL)) AS commenter,
      SUM(comment.streamerCnt) AS totalCommentStreamer
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion` AS DUB
    INNER JOIN UserPlatform AS UP
      USING(userID)
    WHERE
      registerDate BETWEEN '2022-05-01' AND '2022-06-30'
      AND registerCountry IN ('Australia', 'Canada', 'United States', 'Colombia', 'Mexico')
      AND operationRegionGroup = 'United States'
    GROUP BY operationRegionGroup
    UNION ALL
    SELECT
      registerCountry AS operationRegionGroup,
      COUNT(DISTINCT IF(follow IS NOT NULL, userID, NULL)) AS newFollower,
      SUM(follow.streamerCnt) AS newFollowCount,
      COUNT(DISTINCT IF(snack IS NOT NULL, userID, NULL)) AS snacker,
      SUM(snack.totalCount) AS totalSnackCount,
      SUM(ARRAY_LENGTH(snack.receivers)) AS totalSnackStreamer,
      COUNT(DISTINCT IF(gift IS NOT NULL, userID, NULL)) AS gifter,
      SUM(gift.totalCount) AS totalGiftCount,
      SUM(gift.totalPoint) AS totalGiftPoint,
      SUM(gift.totalListPrice) AS totalGiftPrice,
      SUM(ARRAY_LENGTH(gift.receivers)) AS totalGiftStreamer,
      COUNT(DISTINCT IF( `view` IS NOT NULL, userID, NULL)) AS viewer,
      SUM(`view`.duration)/60 AS totalViewDuration_mins,
      SUM(`view`.streamerCnt) AS numViewStreamer,
      COUNT(DISTINCT IF(comment IS NOT NULL, userID, NULL)) AS commenter,
      SUM(comment.streamerCnt) AS totalCommentStreamer
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion` AS DUB
    INNER JOIN UserPlatform AS UP
      USING(userID)
    WHERE
      registerDate BETWEEN '2022-05-01' AND '2022-06-30'
      AND registerCountry IN ('Taiwan')
      AND operationRegionGroup = 'Taiwan'
    GROUP BY operationRegionGroup
  )
SELECT
  UA.*,
  newFollower AS uniquerNewFollower,
  newFollower/RegisterCnt AS newFollowRate,
  cost/newFollower AS CPNewFollower,
  newFollowCount/newFollower AS avgNewFollowCount,
  snacker AS uniqueSnacker,
  snacker/RegisterCnt AS snackRate,
  cost/snacker AS CPSnacker,
  totalSnackCount/snacker AS avgSnackCount,
  totalSnackStreamer/snacker AS avgSnackStreamer,
  gifter AS uniqueGifter,
  gifter/RegisterCnt AS giftRate,
  cost/gifter AS CPGifter,
  totalGiftCount/gifter AS avgGiftCount,
  totalGiftPoint/gifter AS avgGiftPoint,
  totalGiftPrice/gifter AS avgGiftPrice,
  totalGiftPrice,
  totalGiftPrice/cost AS ROASGift,
  totalGiftStreamer/gifter AS avgGiftStreamer,
  viewer AS uniqueViwer,
  viewer/RegisterCnt AS viewRate,
  cost/viewer AS CPViwer,
  totalViewDuration_mins/viewer AS avgViewDuration_mins,
  numViewStreamer/viewer AS avgViewStreamer,
  commenter AS uniquerCommenter,
  commenter/RegisterCnt AS commentRate,
  cost/commenter AS CPCommenter,
  totalCommentStreamer/commenter AS avgCommentStreamer
FROM UA
INNER JOIN DUB
  USING(operationRegionGroup)

-- Split by platform
WITH
  -- Correct cost values from Felix
  Cost AS (
    SELECT 'Australia' AS operationRegionGroup, 8140 AS cost, 'IOS' AS platform
    UNION ALL
    SELECT 'Australia' AS operationRegionGroup, 2690 AS cost, 'ANDROID' AS platform
    UNION ALL
    SELECT 'Canada' AS operationRegionGroup, 11827 AS cost, 'IOS' AS platform
    UNION ALL
    SELECT 'Canada' AS operationRegionGroup, 4004 AS cost, 'ANDROID' AS platform
    UNION ALL
    SELECT 'United States' AS operationRegionGroup, 98915 AS cost, 'IOS' AS platform
    UNION ALL
    SELECT 'United States' AS operationRegionGroup, 106298 AS cost, 'ANDROID' AS platform
    -- UNION ALL
    -- SELECT 'Mexico' AS operationRegionGroup, 34531 AS cost, 'IOS' AS platform
    -- UNION ALL
    -- SELECT 'Mexico' AS operationRegionGroup, 34531 AS cost, 'ANDROID' AS platform
    -- UNION ALL
    -- SELECT 'Colombia' AS operationRegionGroup, 6157 AS cost, 'IOS' AS platform
    -- UNION ALL
    -- SELECT 'Colombia' AS operationRegionGroup, 6157 AS cost, 'ANDROID' AS platform
    UNION ALL
    SELECT 'Taiwan' AS operationRegionGroup, 61463 AS cost, 'IOS' AS platform
    UNION ALL
    SELECT 'Taiwan' AS operationRegionGroup, 61463 AS cost, 'ANDROID' AS platform
  )
  ,UA AS (
    SELECT 
      -- Base
      operationRegionGroup
      ,platform
      -- Cost
      ,AVG(C.cost) AS cost
      ,SUM(InstallCnt) AS installCnt
      ,AVG(C.cost)/SUM(InstallCnt) AS CPI
      ,SUM(RegisterCnt) AS registerCnt
      ,SUM(RegisterCnt)/SUM(InstallCnt) AS registerRate
      ,AVG(C.cost)/SUM(RegisterCnt) AS CPR
      -- Retention
      ,SUM(RetentionD1) AS retentionD1
      ,SUM(RetentionD1)/SUM(RegisterCnt) AS retentionRateD1
      ,AVG(C.cost)/SUM(RetentionD1) AS CPRetainedD1
      ,SUM(RetentionD7) AS retentionD7
      ,SUM(RetentionD7)/SUM(RegisterCnt) AS retentionRateD7
      ,AVG(C.cost)/SUM(RetentionD7) AS CPRetainedD7
      ,SUM(RetentionD14) AS retentionD14
      ,SUM(RetentionD14)/SUM(RegisterCnt) AS retentionRateD14
      ,AVG(C.cost)/SUM(RetentionD14) AS CPRetainedD14
      ,SUM(RetentionD30) AS retentionD30
      ,SUM(RetentionD30)/SUM(RegisterCnt) AS retentionRateD30
      -- ,AVG(C.cost)/SUM(RetentionD30) AS CPRetainedD30
      -- Payer
      ,SUM(numPayerD0) AS numPayerD0
      ,SUM(numPayerD0)/SUM(RegisterCnt) AS payRateD0
      ,AVG(C.cost)/SUM(numPayerD0) AS CPPayerD0
      ,SUM(numPayer1D) AS numPayer1D
      ,SUM(numPayer1D)/SUM(RegisterCnt) AS payRate1D
      ,AVG(C.cost)/SUM(numPayer1D) AS CPPayer1D
      ,SUM(numPayer7D) AS numPayer7D
      ,SUM(numPayer7D)/SUM(RegisterCnt) AS payRate7D
      ,AVG(C.cost)/SUM(numPayer7D) AS CPPayer7D
      ,SUM(numPayer14D) AS numPayer14D
      ,SUM(numPayer14D)/SUM(RegisterCnt) AS payRate14D
      ,AVG(C.cost)/SUM(numPayer14D) AS CPPayer14D
      ,SUM(numPayer30D) AS numPayer30D
      ,SUM(numPayer30D)/SUM(RegisterCnt) AS payRate30D
      ,AVG(C.cost)/SUM(numPayer30D) AS CPPayer30D
      -- Spender
      ,SUM(numSpenderD0) AS numSpenderD0
      ,SUM(numSpenderD0)/SUM(RegisterCnt) AS spendRateD0
      ,AVG(C.cost)/SUM(numSpenderD0) AS CPSpenderD0
      ,SUM(numSpender1D) AS numSpender1D
      ,SUM(numSpender1D)/SUM(RegisterCnt) AS spendRate1D
      ,AVG(C.cost)/SUM(numSpender1D) AS CPSpender1D
      ,SUM(numSpender7D) AS numSpender7D
      ,SUM(numSpender7D)/SUM(RegisterCnt) AS spendRate7D
      ,AVG(C.cost)/SUM(numSpender7D) AS CPSpender7D
      ,SUM(numSpender14D) AS numSpender14D
      ,SUM(numSpender14D)/SUM(RegisterCnt) AS spendRate14D
      ,AVG(C.cost)/SUM(numSpender14D) AS CPSpender14D
      ,SUM(numSpender30D) AS numSpender30D
      ,SUM(numSpender30D)/SUM(RegisterCnt) AS spendRate30D
      ,AVG(C.cost)/SUM(numSpender30D) AS CPSpender30D
      -- User Value
      ,SUM(accuAmountD0) AS accuAmountD0
      ,SUM(accuAmountD0)/AVG(C.cost) AS ROASD0
      ,SUM(accuAmountD0)/SUM(RegisterCnt) AS ARPUD0
      ,SUM(accuAmount1D) AS accuAmount1D
      ,SUM(accuAmount1D)/AVG(C.cost) AS ROAS1D
      ,SUM(accuAmount1D)/SUM(RegisterCnt) AS ARPU1D
      ,SUM(accuAmount7D) AS accuAmount7D
      ,SUM(accuAmount7D)/AVG(C.cost) AS ROAS7D
      ,SUM(accuAmount7D)/SUM(RegisterCnt) AS ARPU7D
      ,SUM(accuAmount14D) AS accuAmount14D
      ,SUM(accuAmount14D)/AVG(C.cost) AS ROAS14D
      ,SUM(accuAmount14D)/SUM(RegisterCnt) AS ARPU14D
      ,SUM(accuAmount30D) AS accuAmount30D
      ,SUM(accuAmount30D)/AVG(C.cost) AS ROAS30D
      ,SUM(accuAmount30D)/SUM(RegisterCnt) AS ARPU30D
    FROM `media17-1119.MatomoDataSource.UAAggrTable` 
    INNER JOIN Cost AS C
      USING(operationRegionGroup, platform)
    WHERE timeZoneDate BETWEEN '2022-05-01' AND '2022-06-30' --timeZoneDate is register date
      AND operationRegionGroup IN (
        'Australia'
        ,'Canada'
        ,'United States'
        -- ,'Colombia'
        -- ,'Mexico'
        ,'Taiwan'
      )
      AND (
        (platform = 'ANDROID' AND attributionType = 'Regular')
        OR (platform = 'IOS' AND attributionType IN ('Regular', 'Organic'))
      )
    GROUP BY operationRegionGroup, platform
  )
  -- Platform information
  ,UserPlatform AS (
    SELECT DISTINCT
      userID,
      platform
    FROM `media17-1119.MatomoDataMart.UserMediaSourceChangeLog_S2S` AS UMSC
    LEFT JOIN `media17-1119.MatomoCore.dim_userdimension` UD
    USING(userID)
    LEFT JOIN`media17-1119.MatomoCore.lookup_region` AS ORG
    ON region.registerCountry = ORG.country
      AND UMSC.timeZoneDate >= DATE(ORG.groupStartTime, ORG.timeZone)
      AND UMSC.timeZoneDate < DATE(ORG.groupEndTime, ORG.timeZone)
    WHERE userType = 'New'
      AND DATE(UD.profile.registerTime, UMSC.timeZone) BETWEEN '2022-05-01' AND '2022-06-30'
      AND UD.region.registerCountry IN (
        'Australia'
        ,'Canada'
        ,'United States'
        -- ,'Colombia'
        -- ,'Mexico'
        ,'Taiwan'
      )
      AND (
        (platform = 'ANDROID' AND appsflyerInfo.attributionType = 'Regular')
        OR (platform = 'IOS' AND appsflyerInfo.attributionType IN ('Regular', 'Organic'))
      )
  )
  -- US streamer region
  ,DUB AS (
    SELECT
      registerCountry AS operationRegionGroup,
      platform,
      COUNT(DISTINCT IF(follow IS NOT NULL, userID, NULL)) AS newFollower,
      SUM(follow.streamerCnt) AS newFollowCount,
      COUNT(DISTINCT IF(snack IS NOT NULL, userID, NULL)) AS snacker,
      SUM(snack.totalCount) AS totalSnackCount,
      SUM(ARRAY_LENGTH(snack.receivers)) AS totalSnackStreamer,
      COUNT(DISTINCT IF(gift IS NOT NULL, userID, NULL)) AS gifter,
      SUM(gift.totalCount) AS totalGiftCount,
      SUM(gift.totalPoint) AS totalGiftPoint,
      SUM(gift.totalListPrice) AS totalGiftPrice,
      SUM(ARRAY_LENGTH(gift.receivers)) AS totalGiftStreamer,
      COUNT(DISTINCT IF( `view` IS NOT NULL, userID, NULL)) AS viewer,
      SUM(`view`.duration)/60 AS totalViewDuration_mins,
      SUM(`view`.streamerCnt) AS numViewStreamer,
      COUNT(DISTINCT IF(comment IS NOT NULL, userID, NULL)) AS commenter,
      SUM(comment.streamerCnt) AS totalCommentStreamer
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion` AS DUB
    INNER JOIN UserPlatform AS UP
      USING(userID)
    WHERE
      registerDate BETWEEN '2022-05-01' AND '2022-06-30'
      AND registerCountry IN ('Australia', 'Canada', 'United States', 'Colombia', 'Mexico')
      AND operationRegionGroup = 'United States'
    GROUP BY operationRegionGroup, platform
    UNION ALL
    SELECT
      registerCountry AS operationRegionGroup,
      platform,
      COUNT(DISTINCT IF(follow IS NOT NULL, userID, NULL)) AS newFollower,
      SUM(follow.streamerCnt) AS newFollowCount,
      COUNT(DISTINCT IF(snack IS NOT NULL, userID, NULL)) AS snacker,
      SUM(snack.totalCount) AS totalSnackCount,
      SUM(ARRAY_LENGTH(snack.receivers)) AS totalSnackStreamer,
      COUNT(DISTINCT IF(gift IS NOT NULL, userID, NULL)) AS gifter,
      SUM(gift.totalCount) AS totalGiftCount,
      SUM(gift.totalPoint) AS totalGiftPoint,
      SUM(gift.totalListPrice) AS totalGiftPrice,
      SUM(ARRAY_LENGTH(gift.receivers)) AS totalGiftStreamer,
      COUNT(DISTINCT IF( `view` IS NOT NULL, userID, NULL)) AS viewer,
      SUM(`view`.duration)/60 AS totalViewDuration_mins,
      SUM(`view`.streamerCnt) AS numViewStreamer,
      COUNT(DISTINCT IF(comment IS NOT NULL, userID, NULL)) AS commenter,
      SUM(comment.streamerCnt) AS totalCommentStreamer
    FROM `media17-1119.MatomoDataMart.DailyUserBehavior_ViewRegion` AS DUB
    INNER JOIN UserPlatform AS UP
      USING(userID)
    WHERE
      registerDate BETWEEN '2022-05-01' AND '2022-06-30'
      AND registerCountry IN ('Taiwan')
      AND operationRegionGroup = 'Taiwan'
    GROUP BY operationRegionGroup, platform
  )
SELECT
  UA.*,
  newFollower AS uniquerNewFollower,
  newFollower/RegisterCnt AS newFollowRate,
  cost/newFollower AS CPNewFollower,
  newFollowCount/newFollower AS avgNewFollowCount,
  snacker AS uniqueSnacker,
  snacker/RegisterCnt AS snackRate,
  cost/snacker AS CPSnacker,
  totalSnackCount/snacker AS avgSnackCount,
  totalSnackStreamer/snacker AS avgSnackStreamer,
  gifter AS uniqueGifter,
  gifter/RegisterCnt AS giftRate,
  cost/gifter AS CPGifter,
  totalGiftCount/gifter AS avgGiftCount,
  totalGiftPoint/gifter AS avgGiftPoint,
  totalGiftPrice/gifter AS avgGiftPrice,
  totalGiftPrice,
  totalGiftPrice/cost AS ROASGift,
  totalGiftStreamer/gifter AS avgGiftStreamer,
  viewer AS uniqueViwer,
  viewer/RegisterCnt AS viewRate,
  cost/viewer AS CPViwer,
  totalViewDuration_mins/viewer AS avgViewDuration_mins,
  numViewStreamer/viewer AS avgViewStreamer,
  commenter AS uniquerCommenter,
  commenter/RegisterCnt AS commentRate,
  cost/commenter AS CPCommenter,
  totalCommentStreamer/commenter AS avgCommentStreamer
FROM UA
INNER JOIN DUB
  USING(operationRegionGroup, platform)