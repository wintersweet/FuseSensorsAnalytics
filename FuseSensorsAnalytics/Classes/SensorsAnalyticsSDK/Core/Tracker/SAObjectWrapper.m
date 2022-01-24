//
//  SAObjectWrapper.m
//  FUSEPRO
//
//  Created by 胡冬冬 on 2021/12/22.
//  Copyright © 2021 FUSENANO. All rights reserved.
//

#import "SAObjectWrapper.h"
#import "SAPresetProperty.h"
#import "SAReferrerManager.h"
#import "SensorsAnalyticsSDK.h"
@interface SAObjectWrapper ()

@property (nonatomic, strong) SAPresetProperty *presetProperty;

@end

@implementation SAObjectWrapper

+(NSMutableDictionary*)createEventId:(NSDictionary*)eventDic{
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:eventDic];
    if ([dic[@"eventName"] isEqualToString:@"AppClick"] && dic[@"where"][@"elementId"] == nil ) {
        return nil;
    }
    
    NSString * pageId = eventDic[@"where"][@"elementId"] != nil ? eventDic[@"where"][@"elementId"]:eventDic[@"where"][@"pageId"];
    if (pageId == nil) {
        return nil;
    }
    NSString *eventId = [NSString stringWithFormat:@"%@%@",pageId,[SAObjectWrapper getEventTypeId:eventDic]];
    [dic setValue:eventId forKey:@"eventId"];
    
    NSString * traceId = [NSString stringWithFormat:@"%@%@",eventId,
                          [NSString stringWithFormat:@"%@",eventDic[@"time"]]];
    [dic setValue:traceId forKey:@"traceId"];
    
    [SAObjectWrapper setHttpHeader:eventId traceId:traceId];
    
    //属于组装referrerEventId
    NSString* referrerEventId = [SAReferrerManager sharedInstance].referrerEventId;
    NSString* referrerPageId = [SAReferrerManager sharedInstance].referrerPageId;
    NSString* referrerURL = [SAReferrerManager sharedInstance].referrerURL;
    NSString* currentPageId = [SAReferrerManager sharedInstance].currentPageId;
    NSString* currentPageName = [SAReferrerManager sharedInstance].currentPageName;
    
    if (referrerEventId) {
        [dic setValue:referrerEventId forKey:@"referrerEventId"];
    }
    
    [dic setValue:dic[@"where"][@"userId"] forKey:@"userId"];
    [dic setValue:dic[@"where"][@"userName"] forKey:@"userName"];
    
    // 如果过是AppClick  AppPageLeave  设置上次缓存的referrerEventId ;
    NSString * eventType = eventDic[@"eventName"];
    NSMutableDictionary * whereDic = [NSMutableDictionary dictionaryWithDictionary:dic[@"where"]];
    // 现在的AppClick是业务埋点，为业务埋点也加一个pageName,和存储的上一个referrerURL 一样
    if([eventType isEqualToString:@"AppClick"]){
        if (currentPageId) {
            [whereDic setValue:currentPageId forKey:@"pageId"];
        }
        if (currentPageName) {
            [whereDic setValue:currentPageName forKey:@"pageName"];
        }
    }
    /*设置属性*/
    [whereDic setValue:referrerPageId forKey:@"referrerPageId"];
    [whereDic setValue:referrerURL forKey:@"referrerPageName"];
    // 更新语言
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString *language = [def valueForKey:@"userLanguage"];
    if (language) {
        [whereDic setValue:language forKey:@"appLanguage"];
    }

    [whereDic removeObjectForKey:@"userId"];
    [whereDic removeObjectForKey:@"userName"];
    
    [dic setValue:whereDic forKey:@"where"];
    
    /*设置属性*/
    //区分what和where的内容
    NSMutableDictionary *newWhereDic = [SAObjectWrapper getNewWhereDic:whereDic];
    whereDic  = [SAObjectWrapper resetWhereProperty:whereDic];
    [dic setValue:whereDic forKey:@"what"];
    [dic setValue:newWhereDic forKey:@"where"];
    //更新当前的eventId (AppClick不更新存储的页面)
    if([eventDic[@"eventName"] isEqualToString:@"AppPageLeave"]){
        NSString * pageName = eventDic[@"where"][@"pageName"];
        [[SAReferrerManager sharedInstance] cacheReferrerEventId:eventId pageId:pageId referrerName:pageName];
        
    }else if([eventDic[@"eventName"] isEqualToString:@"AppViewPage"]){
        NSString * pageName = eventDic[@"where"][@"pageName"];
        [[SAReferrerManager sharedInstance] cacheCurrentPageId:pageId currentPageName:pageName];
        [[SAReferrerManager sharedInstance] cacheReferrerEventId:eventId];
    }
    else if([eventDic[@"eventName"] isEqualToString:@"AppClick"]){
        [[SAReferrerManager sharedInstance] cacheReferrerEventId:eventId];
    }
    return dic;
}
//http的 header中传2个字段  x-eventId （埋点数据中的eventId） x-traceId （埋点数据字段中的traceId = eventId_time）
+(void)setHttpHeader:(NSString*)eventId traceId:(NSString*)traceId{
    [XMCenter setupConfig:^(XMConfig * _Nonnull config) {
        config.generalHeaders = @{@"x-eventId":eventId,@"x-traceId":traceId};
    }];
}
+(NSMutableDictionary*)resetWhereProperty:(NSMutableDictionary*)whereDic{
    [whereDic removeObjectForKey:@"appId"];
    [whereDic removeObjectForKey:@"appSource"];
    [whereDic removeObjectForKey:@"accessSystem"];
    [whereDic removeObjectForKey:@"appVersion"];
    [whereDic removeObjectForKey:@"appLanguage"];
    [whereDic removeObjectForKey:@"deviceBrand"];
    [whereDic removeObjectForKey:@"deviceModel"];
    [whereDic removeObjectForKey:@"operatingSystem"];
    [whereDic removeObjectForKey:@"osVersion"];
    [whereDic removeObjectForKey:@"netWorkType"];
    [whereDic removeObjectForKey:@"netWorkCarrier"];
    [whereDic removeObjectForKey:@"screenHeight"];
    [whereDic removeObjectForKey:@"screenWidth"];
    [whereDic removeObjectForKey:@"latitude"];
    [whereDic removeObjectForKey:@"longitude"];
    [whereDic removeObjectForKey:@"timeZone"];
    [whereDic removeObjectForKey:@"deviceId"];
    [whereDic removeObjectForKey:@"time"];
    [whereDic removeObjectForKey:@"currentPageId"];
    [whereDic removeObjectForKey:@"currentPageName"];
    [whereDic removeObjectForKey:@"referrerEventId"];

    return  whereDic;
}
+(NSMutableDictionary*)getNewWhereDic:(NSMutableDictionary*)whereDic{
    NSMutableDictionary *newWhereDic = [NSMutableDictionary dictionary];
    [newWhereDic setValue:whereDic[@"appId"] forKey:@"appId"];
    [newWhereDic setValue:whereDic[@"appSource"] forKey:@"appSource"];
    [newWhereDic setValue:whereDic[@"accessSystem"] forKey:@"accessSystem"];
    [newWhereDic setValue:whereDic[@"appVersion"] forKey:@"appVersion"];
    [newWhereDic setValue:whereDic[@"appLanguage"] forKey:@"appLanguage"];
    [newWhereDic setValue:whereDic[@"deviceBrand"] forKey:@"deviceBrand"];
    [newWhereDic setValue:whereDic[@"deviceModel"] forKey:@"deviceModel"];
    [newWhereDic setValue:whereDic[@"operatingSystem"] forKey:@"operatingSystem"];
    [newWhereDic setValue:whereDic[@"osVersion"] forKey:@"osVersion"];
    [newWhereDic setValue:whereDic[@"netWorkType"] forKey:@"netWorkType"];
    [newWhereDic setValue:whereDic[@"netWorkCarrier"] forKey:@"netWorkCarrier"];
    [newWhereDic setValue:whereDic[@"screenHeight"] forKey:@"screenHeight"];
    [newWhereDic setValue:whereDic[@"screenWidth"] forKey:@"screenWidth"];
    [newWhereDic setValue:whereDic[@"timeZone"] forKey:@"timeZone"];
    if(whereDic[@"latitude"]){
        [newWhereDic setValue:whereDic[@"latitude"]  forKey:@"latitude"];
    }
    if(whereDic[@"longitude"]){
        [newWhereDic setValue:whereDic[@"longitude"]  forKey:@"longitude"];
    }
    [newWhereDic setValue:whereDic[@"deviceId"] forKey:@"deviceId"];
    [newWhereDic setValue:whereDic[@"time"] forKey:@"time"];
    return newWhereDic;
}

+(NSMutableDictionary*)appStartEndTraceEvent:(NSDictionary*)eventDic{
   
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:eventDic];
    NSMutableDictionary * whereDic = [NSMutableDictionary dictionaryWithDictionary:dic[@"where"]];
    NSString * eventId;
    NSString * eventName = dic[@"eventName"];
    if ([eventName isEqualToString:@"AppStart"]) {
        eventId = @"00000001";
        [dic setValue:eventId forKey:@"eventId"];
    }
    if ([eventName isEqualToString:@"AppEnd"]) {
        eventId = @"11111002";
        [dic setValue:eventId forKey:@"eventId"];
    }
   
    //属于组装referrerEventId
    NSString* referrerEventId = [SAReferrerManager sharedInstance].referrerEventId;
    NSString* referrerPageId = [SAReferrerManager sharedInstance].referrerPageId;
    NSString* referrerURL = [SAReferrerManager sharedInstance].referrerURL;
    if (referrerEventId) {
        [dic setValue:referrerEventId forKey:@"referrerEventId"];
    }
    if (eventId) {
        NSString * traceId = [NSString stringWithFormat:@"%@%@",eventId,
                              [NSString stringWithFormat:@"%@",eventDic[@"time"]]];
        [dic setValue:traceId forKey:@"traceId"];
        [SAObjectWrapper setHttpHeader:eventId traceId:traceId];
    }
   
    if (referrerPageId) {
        [whereDic setValue:referrerPageId forKey:@"referrerPageId"];
    }
    if (referrerURL) {
        [whereDic setValue:referrerURL forKey:@"referrerPageName"];
    }
    
   
    [dic setValue:whereDic forKey:@"where"];
    return  dic;
   
}
#pragma 缓存EventId
+(NSString*)getEventTypeId:(NSDictionary*)eventDic{
    NSString * pageEventId = @"001";
    NSString * eventName = eventDic[@"eventName"];
    if ([eventName isEqualToString:@"AppStart"]){
        pageEventId = @"001";
    }else if ([eventName isEqualToString:@"AppEnd"]){
        pageEventId = @"002";

    }else if ([eventName isEqualToString:@"AppViewPage"]){
        pageEventId = @"003";

    }else if ([eventName isEqualToString:@"AppPageLeave"]){
        pageEventId = @"004";

    }else if ([eventName isEqualToString:@"AppClick"] ){
        pageEventId = @"005";

    }else if ([eventName isEqualToString:@"AppPushClick"] || [eventName isEqualToString:@"PopUpShow"]){
        pageEventId = @"006";

    }else if ([eventName isEqualToString:@"AppDeepLinkLaunch"]){
        pageEventId = @"007";

    }else{
        pageEventId = @"003";

    }
    return  pageEventId;
}
//重新组装 flutter传过来的数据，然后入库
+(void)wrapperFlutterData:(NSDictionary*)parmas{
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:parmas];
    //更新当前的eventId (AppClick不更新存储的页面)
    NSString * pageId =  parmas[@"pageId"];
    NSString * pageName = parmas[@"pageName"];
    NSString * eventId =  parmas[@"eventId"];
    if([parmas[@"eventName"] isEqualToString:@"AppPageLeave"]){
        [[SAReferrerManager sharedInstance] cacheReferrerEventId:eventId pageId:pageId referrerName:pageName];
        
    }else if([parmas[@"eventName"] isEqualToString:@"AppViewPage"]){
        [[SAReferrerManager sharedInstance] cacheCurrentPageId:pageId currentPageName:pageName];
        [[SAReferrerManager sharedInstance] cacheReferrerEventId:eventId];

    }
  
    NSMutableDictionary * newDic = [SAObjectWrapper getDic:dic];
    NSMutableDictionary * whatDic =  [SAObjectWrapper getWhatDic:dic];
    NSMutableDictionary * whereDic = [SAObjectWrapper getWhereDic:dic];
    NSDictionary* presentDic =  [[SensorsAnalyticsSDK sharedInstance] getPresetProperties];
    [whereDic addEntriesFromDictionary:presentDic];
    NSMutableDictionary * resutl  = [NSMutableDictionary dictionaryWithDictionary:newDic];
    [resutl setValue:whatDic forKey:@"what"];
    [resutl setValue:whereDic forKey:@"where"];

    if (resutl) {
        [[SAArchived shareInstance] writeDataToFile:resutl];
    }
    
 
}
+(NSMutableDictionary*)getDic:(NSDictionary*)dic{
    NSMutableDictionary *newDic = [NSMutableDictionary dictionary];
    [newDic setValue:dic[@"eventId"] forKey:@"eventId"];
    [newDic setValue:dic[@"eventName"] forKey:@"eventName"];
    [newDic setValue:dic[@"time"] forKey:@"time"];
    [newDic setValue:dic[@"traceId"] forKey:@"traceId"];
    [newDic setValue:dic[@"userId"] forKey:@"userId"];
    [newDic setValue:dic[@"userName"] forKey:@"userName"];
    [newDic setValue:dic[@"referrerEventId"] forKey:@"referrerEventId"];
    [newDic setValue:dic[@"referrerPageName"] forKey:@"referrerPageName"];
    return newDic;

}
+(NSMutableDictionary*)getWhereDic:(NSDictionary*)dic{
    NSMutableDictionary *newWhereDic = [NSMutableDictionary dictionary];
    [newWhereDic setValue:dic[@"pageId"] forKey:@"pageId"];
    [newWhereDic setValue:dic[@"eventName"] forKey:@"eventName"];
    [newWhereDic setValue:dic[@"pageId"] forKey:@"pageId"];
    [newWhereDic setValue:dic[@"pageName"] forKey:@"pageName"];
    [newWhereDic setValue:dic[@"appLanguage"] forKey:@"appLanguage"];
    [newWhereDic setValue:dic[@"deviceBrand"] forKey:@"deviceBrand"];
    [newWhereDic setValue:dic[@"deviceModel"] forKey:@"deviceModel"];
    [newWhereDic setValue:dic[@"operatingSystem"] forKey:@"operatingSystem"];
    [newWhereDic setValue:dic[@"osVersion"] forKey:@"osVersion"];
    [newWhereDic setValue:dic[@"netWorkType"] forKey:@"netWorkType"];
    [newWhereDic setValue:dic[@"netWorkCarrier"] forKey:@"netWorkCarrier"];
    [newWhereDic setValue:dic[@"screenHeight"] forKey:@"screenHeight"];
    [newWhereDic setValue:dic[@"screenWidth"] forKey:@"screenWidth"];
    [newWhereDic setValue:dic[@"timeZone"] forKey:@"timeZone"];
    if(dic[@"latitude"]){
        [newWhereDic setValue:dic[@"latitude"]  forKey:@"latitude"];
    }
    if(dic[@"longitude"]){
        [newWhereDic setValue:dic[@"longitude"]  forKey:@"longitude"];
    }
    [newWhereDic setValue:dic[@"deviceId"] forKey:@"deviceId"];
    [newWhereDic setValue:dic[@"time"] forKey:@"time"];
    return newWhereDic;
}
+(NSMutableDictionary*)getWhatDic:(NSDictionary*)dic{
    NSMutableDictionary *newWhatDic = [NSMutableDictionary dictionary];
    if(dic[@"referrerEventId"]){
        [newWhatDic setValue:dic[@"referrerEventId"]  forKey:@"referrerEventId"];
    }
    if(dic[@"eventName"]){
        [newWhatDic setValue:dic[@"eventName"]  forKey:@"eventName"];
    }
    if(dic[@"pageId"]){
        [newWhatDic setValue:dic[@"pageId"]  forKey:@"pageId"];
    }
    if(dic[@"pageName"]){
        [newWhatDic setValue:dic[@"pageName"]  forKey:@"pageName"];
    }
    if(dic[@"referrerPageName"]){
        [newWhatDic setValue:dic[@"referrerPageName"]  forKey:@"referrerPageName"];
    }
    if(dic[@"eventDuration"]){
        [newWhatDic setValue:dic[@"eventDuration"]  forKey:@"eventDuration"];
    }
    if(dic[@"deviceModel"]){
        [newWhatDic setValue:dic[@"deviceModel"]  forKey:@"deviceModel"];
    }
    if(dic[@"resumeFromBg"]){
        [newWhatDic setValue:dic[@"resumeFromBg"]  forKey:@"resumeFromBg"];
    }
    if(dic[@"osVersion"]){
        [newWhatDic setValue:dic[@"osVersion"]  forKey:@"osVersion"];
    }
    if(dic[@"elementPosition"]){
        [newWhatDic setValue:dic[@"elementPosition"]  forKey:@"elementPosition"];
    }
    if(dic[@"elementContent"]){
        [newWhatDic setValue:dic[@"elementContent"]  forKey:@"elementContent"];
    }
    if(dic[@"elementType"]){
        [newWhatDic setValue:dic[@"elementType"]  forKey:@"elementType"];
    }
    if(dic[@"deeplinkUrl"]){
        [newWhatDic setValue:dic[@"deeplinkUrl"]  forKey:@"deeplinkUrl"];
    }
    if(dic[@"deeplinkOptions"]){
        [newWhatDic setValue:dic[@"deeplinkOptions"]  forKey:@"deeplinkOptions"];
    }
    if(dic[@"pushMsgTitle"]){
        [newWhatDic setValue:dic[@"pushMsgTitle"]  forKey:@"pushMsgTitle"];
    }
    if(dic[@"pushMsgContent"]){
        [newWhatDic setValue:dic[@"pushMsgContent"]  forKey:@"pushMsgContent"];
    }
    if(dic[@"pushMsgServiceName"]){
        [newWhatDic setValue:dic[@"pushMsgServiceName"]  forKey:@"pushMsgServiceName"];
    }
    if(dic[@"pushMsgChannel"]){
        [newWhatDic setValue:dic[@"pushMsgChannel"]  forKey:@"pushMsgChannel"];
    }
    return newWhatDic;
}

+(void)savePopUpShowData:(NSDictionary*)eventDic{
    
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:eventDic];
    // PopUpShow的eventId固定
    NSString *eventId = @"10000006";
    
    NSString * traceId = [NSString stringWithFormat:@"%@%@",eventId,
                         [NSString stringWithFormat:@"%@",eventDic[@"time"]]];
    
    [SAObjectWrapper setHttpHeader:eventId traceId:traceId];
    
    [[SAReferrerManager sharedInstance] cacheReferrerEventId:eventId];

    //属于组装referrerEventId
    NSString* referrerEventId = [SAReferrerManager sharedInstance].referrerEventId;
    NSString* referrerPageId = [SAReferrerManager sharedInstance].referrerPageId;
    NSString* referrerURL = [SAReferrerManager sharedInstance].referrerURL;
    
    [dic setValue:eventId forKey:@"eventId"];
    [dic setValue:traceId forKey:@"traceId"];
    if (referrerEventId) {
        [dic setValue:referrerEventId forKey:@"referrerEventId"];
    }
    
    [dic setValue:dic[@"where"][@"userId"] forKey:@"userId"];
    [dic setValue:dic[@"where"][@"userName"] forKey:@"userName"];
    
    NSMutableDictionary * whereDic = [NSMutableDictionary dictionaryWithDictionary:dic[@"where"]];
    /*设置属性*/
    [whereDic setValue:referrerPageId forKey:@"referrerPageId"];
    [whereDic setValue:referrerURL forKey:@"referrerPageName"];
    [whereDic removeObjectForKey:@"userId"];
    [whereDic removeObjectForKey:@"userName"];
    [whereDic setValue:referrerURL forKey:@"eventName"];
   
    [dic setValue:whereDic forKey:@"where"];
    /*设置属性*/
    //区分what和where的内容
    NSMutableDictionary *newWhereDic = [SAObjectWrapper getNewWhereDic:whereDic];
    whereDic  = [SAObjectWrapper resetWhereProperty:whereDic];
    
    [dic setValue:whereDic forKey:@"what"];
    [dic setValue:newWhereDic forKey:@"where"];
    
    if (dic) {
        [[SAArchived shareInstance] writeDataToFile:dic];
    }
}
@end
