//
// SAReferrerManager.m
// SensorsAnalyticsSDK
//
// Created by 彭远洋 on 2020/12/9.
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

#import "SAReferrerManager.h"
#import "SAConstants+Private.h"

@interface SAReferrerManager ()

@property (atomic, copy, readwrite) NSMutableDictionary *referrerProperties;
@property (atomic, copy, readwrite) NSString *referrerURL;
@property (atomic, copy, readwrite) NSString *referrerTitle;
@property (atomic, copy) NSString *currentTitle;
@property (atomic, copy) NSString *eventId;

@property (atomic, copy) NSString *referrerEventId;
@property (atomic, copy) NSString *referrerPageId;

@property (atomic, copy) NSString *currentPageId;
@property (atomic, copy) NSString *currentPageName;


@end

@implementation SAReferrerManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static SAReferrerManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[SAReferrerManager alloc] init];
    });
    return manager;
}

- (NSDictionary *)propertiesWithURL:(NSString *)currentURL eventProperties:(NSDictionary *)eventProperties {
    NSString *referrerURL = self.referrerURL;

    NSMutableDictionary *newProperties = [NSMutableDictionary dictionaryWithDictionary:eventProperties];
    
    // 生成的手动eventId
    newProperties[kSAEeventPropertyReferrerEventId] = self.referrerEventId;
    newProperties[kSAEeventPropertyReferrerPageId] = self.referrerPageId;
    newProperties[kSAEventPropertyScreenUrl] = self.referrerURL;
    newProperties[kSAEeventPropertyCurrentPageId] = self.currentPageId;
    newProperties[kSAEeventPropertyCurrentPageName] = self.currentPageName;

    // 客户自定义属性中包含 $url 时，以客户自定义内容为准
    if (!newProperties[kSAEventPropertyScreenUrl]) {
//        newProperties[kSAEventPropertyScreenUrl] = currentURL;
    }

    // 客户自定义属性中包含 $referrer 时，以客户自定义内容为准
    if (referrerURL && !newProperties[kSAEventPropertyScreenReferrerUrl]) {
//        newProperties[kSAEventPropertyScreenReferrerUrl] = referrerURL;
    }
    //这里把 title 赋值给referrerPageName
    
    // $referrer 内容以最终页面浏览事件中的 $url 为准
//    self.referrerURL = newProperties[kSAEventPropertyScreenUrl];
    self.referrerProperties = newProperties;
    
    
    dispatch_async(self.serialQueue, ^{
        [self cacheReferrerTitle:newProperties];
    });
    return newProperties;
}
-(void)cacheReferrerEventId:(NSString*)eventId pageId:(NSString*)pageId referrerName:(NSString*)name{
    dispatch_async(self.serialQueue, ^{
        self.referrerEventId = eventId;
        self.referrerPageId = pageId;
        self.referrerURL = name;
        NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:self.referrerProperties];
        if (eventId !=nil ) {
            [dic setValue:eventId forKey:kSAEeventPropertyReferrerEventId];
        }
        if (pageId != nil) {
            [dic setValue:pageId forKey:kSAEeventPropertyReferrerPageId];
        }
        if (name !=nil){
            [dic setValue:name forKey:kSAEventPropertyScreenUrl];
        }
        self.referrerProperties = dic;
    });
}
-(void)cacheReferrerEventId:(NSString*)eventId pageId:(NSString*)pageId{
    dispatch_async(self.serialQueue, ^{
        self.referrerEventId = eventId;
        self.referrerPageId = pageId;
        NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:self.referrerProperties];
        if (eventId !=nil ) {
            [dic setValue:eventId forKey:kSAEeventPropertyReferrerEventId];
        }
        if (pageId != nil) {
            [dic setValue:pageId forKey:kSAEeventPropertyReferrerPageId];
        }
        self.referrerProperties = dic;
    });
}
-(void)cacheReferrerEventId:(NSString*)eventId{
    dispatch_async(self.serialQueue, ^{
        self.referrerEventId = eventId;
        NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:self.referrerProperties];
        if (eventId !=nil ) {
            [dic setValue:eventId forKey:kSAEeventPropertyReferrerEventId];
        }
       
        self.referrerProperties = dic;
    });
}
-(void)cacheCurrentPageId:(NSString*)pageId currentPageName:(NSString*)pageName{
    dispatch_async(self.serialQueue, ^{
        self.currentPageId = pageId;
        self.currentPageName = pageName;
        NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:self.referrerProperties];
        if (pageId !=nil ) {
            [dic setValue:pageId forKey:kSAEeventPropertyCurrentPageId];
        }
        if (pageId != nil) {
            [dic setValue:pageName forKey:kSAEeventPropertyCurrentPageName];
        }
        self.referrerProperties = dic;
    });
}
-(void)cacheReferrerName:(NSString*)name{
    dispatch_async(self.serialQueue, ^{
        self.referrerURL = name;
        NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:self.referrerProperties];
        if (name !=nil){
            [dic setValue:name forKey:kSAEventPropertyScreenUrl];
        }
        self.referrerProperties = dic;
    });
}
- (void)cacheReferrerTitle:(NSDictionary *)properties {
    self.referrerTitle = self.currentTitle;
    self.currentTitle = properties[kSAEventPropertyTitle];
    self.referrerEventId = properties[kSAEeventPropertyReferrerEventId];
    self.referrerPageId = properties[kSAEeventPropertyReferrerPageId];
    self.referrerURL = properties[kSAEventPropertyScreenUrl];
    self.currentPageId = properties[kSAEeventPropertyCurrentPageId];
    self.currentPageName = properties[kSAEeventPropertyCurrentPageName];
}

- (void)clearReferrer {
    if (self.isClearReferrer) {
        // 需求层面只需要清除 $referrer，不需要清除 $referrer_title
        self.referrerURL = nil;
        self.referrerEventId = nil;
        self.referrerPageId = nil;
        self.referrerURL = nil;
    }
}

@end
