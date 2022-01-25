//
//  SAObjectWrapper.h
//  FUSEPRO
//
//  Created by 胡冬冬 on 2021/12/22.
//  Copyright © 2021 FUSENANO. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface SAObjectWrapper : NSObject
+(NSMutableDictionary*)createEventId:(NSDictionary*)eventDic;


+(NSMutableDictionary*)resetWhereProperty:(NSMutableDictionary*)whereDic;
+(NSMutableDictionary*)getNewWhereDic:(NSMutableDictionary*)whereDic;

+(NSMutableDictionary*)appStartEndTraceEvent:(NSDictionary*)eventDic;
+(NSString*)getEventTypeId:(NSDictionary*)eventDic;

+(void)wrapperFlutterData:(NSDictionary*)parmas;

+(void)savePopUpShowData:(NSDictionary*)parmas;

@end

NS_ASSUME_NONNULL_END
