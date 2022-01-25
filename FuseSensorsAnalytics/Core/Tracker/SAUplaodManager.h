//
//  SAUplaodManager.h
//  FuAutoSensors
//
//  Created by Leo on 2021/12/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAUplaodManager : NSObject

+(void)getUploadUrl:(BOOL)uploadDirect;
+(void)getFileUploadConfig;
@end

NS_ASSUME_NONNULL_END
