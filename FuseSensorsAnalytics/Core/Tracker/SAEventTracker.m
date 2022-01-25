//
// SAEventTracker.m
// SensorsAnalyticsSDK
//
// Created by 张敏超🍎 on 2020/6/18.
// Copyright © 2020 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "SAEventTracker.h"
#import "SAEventFlush.h"
#import "SAEventStore.h"
#import "SADatabase.h"
#import "SANetwork.h"
#import "SAFileStore.h"
#import "SAJSONUtil.h"
#import "SALog.h"
#import "SAObject+SAConfigOptions.h"
#import "SAReachability.h"
#import "SAConstants+Private.h"
#import "SAModuleManager.h"
#import "SAArchived.h"
#import "SAReferrerManager.h"
#import "SAObjectWrapper.h"
static NSInteger kSAFlushMaxRepeatCount = 100;

@interface SAEventTracker ()

@property (nonatomic, strong) SAEventStore *eventStore;

@property (nonatomic, strong) SAEventFlush *eventFlush;

@property (nonatomic, strong) dispatch_queue_t queue;

@property(nonatomic, strong) NSString *elementContent;
@property(nonatomic, strong) NSString *elementPosition;
@property(nonatomic, strong) NSString *elementType;

@end

@implementation SAEventTracker

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _queue = queue;

        dispatch_async(self.queue, ^{
            self.eventStore = [[SAEventStore alloc] initWithFilePath:[SAFileStore filePath:@"message-v2"]];
            self.eventFlush = [[SAEventFlush alloc] init];
        });
    }
    return self;
}

- (void)trackEvent:(NSDictionary *)event {
    [self trackEvent:event isSignUp:NO];
}

/// 事件入库
/// ⚠️ 注意: SF 和 A/B Testing 会 Hook 该方法修改 distinct_id, 因此该方法不能被修改
/// @param event 事件信息
/// @param isSignUp 是否是用户关联事件, 用户关联事件会触发 flush
- (void)trackEvent:(NSDictionary *)event isSignUp:(BOOL)isSignUp {
    SAEventRecord *record = [[SAEventRecord alloc] initWithEvent:event type:@"POST"];
    //  尝试加密 
    //  NSDictionary *obj = [SAModuleManager.sharedInstance encryptJSONObject:record.event];
    //  [record setSecretObject:obj];
    //  [self.eventStore insertRecord:record];
    NSLog(@"==这里拦截数据===%@",record);
    if(!event){
        return;
    }
    //构造一些参数,再上报数据
    NSMutableDictionary *eventDic = [SAObjectWrapper  createEventId:event];
    if ([event[@"eventName"] isEqualToString:@"PopUpShow"]) {
        [SAObjectWrapper savePopUpShowData:event];
        return;
    }
    if (eventDic){
        // 如果是自定义的AppClick  AppPushClick  AppDeepLinkLaunch事件，添加全埋点的  三个额外属性
        NSMutableDictionary * whatDic = [NSMutableDictionary dictionaryWithDictionary:eventDic[@"what"]];
        if ([eventDic[@"eventName"] isEqualToString:@"AppClick"]) {
            //如果有手动为这三个字段赋值，就不用自动获取的内容了
            if(whatDic[@"elementContent"] == nil){
                if (self.elementContent ) {
                    [whatDic setValue:self.elementContent forKey:@"elementContent"];

                }else{
                    [whatDic setValue:@"" forKey:@"elementContent"];
                }
            }
            if(whatDic[@"elementPosition"] == nil){
                if (self.elementPosition ) {
                    [whatDic setValue:self.elementPosition forKey:@"elementPosition"];

                }else{
                    [whatDic setValue:@"0" forKey:@"elementPosition"];
                }
            }
            if (whatDic[@"elementType"] == nil) {
                if (self.elementType ) {
                    [whatDic setValue:self.elementType forKey:@"elementType"];

                }else{
                    [whatDic setValue:@"" forKey:@"elementType"];
                }
            }
            [eventDic setValue:whatDic forKey:@"what"];
        }
       
        SALogDebug(@"\n【track eventDic】:\n%@", eventDic);
        
    }else{
        if ([event[@"eventName"] isEqualToString:@"AppClick"] && event[@"elementId"] == nil ) {
            self.elementContent  =  event[@"where"][@"elementContent"];
            self.elementPosition  = event[@"where"][@"elementPosition"];
            self.elementType  = event[@"where"][@"elementType"];
        }
    }
    dispatch_async(self.queue,^{
        if (eventDic ) {
            //符合条件的 才上报；
            [self writeData:eventDic];
        }else{
            //不属于埋点范围的，先不入库
            if ([event[@"eventName"] isEqualToString:@"AppStart"] ||
                [event[@"eventName"] isEqualToString:@"AppEnd"]) {
                [self appStartkAndEndEvent:event];
            }
            if ([event[@"eventName"] isEqualToString:@"AppPushClick"]||
                ([event[@"eventName"] isEqualToString:@"AppDeepLinkLaunch"])) {
                [self appPushClickAndDeepLinkLaunchEvent:event];
            }
           
        }
    });
    //数据库入库,用不到
    // $SignUp 事件或者本地缓存的数据是超过 flushBulkSize
    /*
    if (isSignUp || self.eventStore.count > self.flushBulkSize || self.isDebugMode) {
        // 添加异步队列任务，保证数据继续入库
        dispatch_async(self.queue, ^{
            [self flushAllEventRecords];
        });
    }
     */
}
-(void)appStartkAndEndEvent:(NSDictionary*)event{
    NSMutableDictionary * dic = [SAObjectWrapper appStartEndTraceEvent:event];

    if (dic[@"where"][@"userId"] ) {
        [dic setValue:dic[@"where"][@"userId"] forKey:@"userId"];
    }
    if (dic[@"where"][@"userName"] ) {
        [dic setValue:dic[@"where"][@"userName"] forKey:@"userName"];
    }
    NSString* referrerEventId = [SAReferrerManager sharedInstance].referrerEventId;
    if (!referrerEventId) {
        [[SAReferrerManager sharedInstance] cacheReferrerEventId:@"00000001"];
    }
    //区分what和where的内容
    NSMutableDictionary * whereDic = [NSMutableDictionary dictionaryWithDictionary:dic[@"where"]];
    [whereDic removeObjectForKey:@"userId"];
    [whereDic removeObjectForKey:@"userName"];
    
    // 更新语言
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString *language = [def valueForKey:@"userLanguage"];
    if (language) {
        [whereDic setValue:language forKey:@"appLanguage"];
    }
    
    NSMutableDictionary *newWhereDic = [SAObjectWrapper getNewWhereDic:whereDic];
    whereDic  = [SAObjectWrapper resetWhereProperty:whereDic];
    NSString* pageId = [SAReferrerManager sharedInstance].currentPageId;
    NSString* pageName = [SAReferrerManager sharedInstance].currentPageName;
    if (pageId) {
        [whereDic setValue:pageId forKey:@"pageId"];
    }
    if (pageName) {
        [whereDic setValue:pageName forKey:@"pageName"];
    }
    [dic setValue:whereDic forKey:@"what"];
    [dic setValue:newWhereDic forKey:@"where"];
    [self writeData:dic];
}

-(void)appPushClickAndDeepLinkLaunchEvent:(NSDictionary*)event{
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:event];
    if (dic[@"where"][@"userId"] ) {
        [dic setValue:dic[@"where"][@"userId"] forKey:@"userId"];
    }
    if (dic[@"where"][@"userName"] ) {
        [dic setValue:dic[@"where"][@"userName"] forKey:@"userName"];
    }
    if ([event[@"eventName"] isEqualToString:@"AppPushClick"]) {
        [dic setValue:@"0000006" forKey:@"eventId"];

    }
    NSString * traceId = [NSString stringWithFormat:@"%@%@",@"0000006",
                          [NSString stringWithFormat:@"%@",event[@"time"]]];
    [dic setValue:traceId forKey:@"traceId"];
    //区分what和where的内容
    NSMutableDictionary * whereDic = [NSMutableDictionary dictionaryWithDictionary:dic[@"where"]];
    [whereDic removeObjectForKey:@"userId"];
    [whereDic removeObjectForKey:@"userName"];
    
    // 更新语言
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString *language = [def valueForKey:@"userLanguage"];
    if (language) {
        [whereDic setValue:language forKey:@"appLanguage"];
    }
    
    NSMutableDictionary *newWhereDic = [SAObjectWrapper getNewWhereDic:whereDic];
    //属于组装referrerEventId
    NSString* referrerEventId = [SAReferrerManager sharedInstance].referrerEventId;
    NSString* referrerPageId = [SAReferrerManager sharedInstance].referrerPageId;
    NSString* referrerURL = [SAReferrerManager sharedInstance].referrerURL;
    
    if (referrerEventId) {
        [dic setValue:referrerEventId forKey:@"referrerEventId"];
    }
    if (referrerPageId) {
        [whereDic setValue:referrerPageId forKey:@"referrerPageId"];
    }
    if (referrerURL) {
        [whereDic setValue:referrerURL forKey:@"referrerPageName"];
    }
    whereDic  = [SAObjectWrapper resetWhereProperty:whereDic];
    [whereDic setValue:@"MyFusePro" forKey:@"pushMsgId"];
    [dic setValue:whereDic forKey:@"what"];
    [dic setValue:newWhereDic forKey:@"where"];
    [self writeData:dic];
    
    
}
-(void)writeData:(NSDictionary*)dic{
    [[SAArchived shareInstance] writeDataToFile:dic];
}
- (BOOL)canFlush {
    // serverURL 是否有效
    if (self.eventFlush.serverURL.absoluteString.length == 0) {
        return NO;
    }
    // 判断当前网络类型是否符合同步数据的网络策略
    if (!([SANetwork networkTypeOptions] & self.networkTypePolicy)) {
        return NO;
    }
    return YES;
}

/// 筛选加密数据，并对未加密的数据尝试加密
/// 即使未开启加密，也可以进行筛选，可能存在加密开关的情况
/// @param records 数据
- (NSArray<SAEventRecord *> *)encryptEventRecords:(NSArray<SAEventRecord *> *)records {
    NSMutableArray *encryptRecords = [NSMutableArray arrayWithCapacity:records.count];
    for (SAEventRecord *record in records) {
        if (record.isEncrypted) {
            [encryptRecords addObject:record];
        } else {
            // 缓存数据未加密，再加密
            NSDictionary *obj = [SAModuleManager.sharedInstance encryptJSONObject:record.event];
            if (obj) {
                [record setSecretObject:obj];
                [encryptRecords addObject:record];
            }
        }
    }
    return encryptRecords.count == 0 ? records : encryptRecords;
}

- (void)flushAllEventRecords {
    [self flushAllEventRecordsWithCompletion:nil];
}

- (void)flushAllEventRecordsWithCompletion:(void(^)(void))completion {
    if (![self canFlush]) {
        if (completion) {
            completion();
        }
        return;
    }
    [self flushRecordsWithSize:self.isDebugMode ? 1 : 50 repeatCount:kSAFlushMaxRepeatCount completion:completion];
}

- (void)flushRecordsWithSize:(NSUInteger)size repeatCount:(NSInteger)repeatCount completion:(void(^)(void))completion {
    // 防止在数据量过大时, 递归 flush, 导致堆栈溢出崩溃; 因此需要限制递归次数
    if (repeatCount <= 0) {
        if (completion) {
            completion();
        }
        return;
    }
    // 从数据库中查询数据
    NSArray<SAEventRecord *> *records = [self.eventStore selectRecords:size];
    if (records.count == 0) {
        if (completion) {
            completion();
        }
        return;
    }

    // 尝试加密，筛选加密数据
    NSArray<SAEventRecord *> *encryptRecords = [self encryptEventRecords:records];

    // 获取查询到的数据的 id
    NSMutableArray *recordIDs = [NSMutableArray arrayWithCapacity:encryptRecords.count];
    for (SAEventRecord *record in encryptRecords) {
        [recordIDs addObject:record.recordID];
    }

    // 更新数据状态
    [self.eventStore updateRecords:recordIDs status:SAEventRecordStatusFlush];

    // flush
    __weak typeof(self) weakSelf = self;
    [self.eventFlush flushEventRecords:encryptRecords completion:^(BOOL success) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        void(^block)(void) = ^ {
            if (!success) {
                [strongSelf.eventStore updateRecords:recordIDs status:SAEventRecordStatusNone];
                if (completion) {
                    completion();
                }
                return;
            }
            // 5. 删除数据
            if ([strongSelf.eventStore deleteRecords:recordIDs]) {
                [strongSelf flushRecordsWithSize:size repeatCount:repeatCount - 1 completion:completion];
            }
        };
        if (sensorsdata_is_same_queue(strongSelf.queue)) {
            block();
        } else {
            dispatch_sync(strongSelf.queue, block);
        }
    }];
}

@end
