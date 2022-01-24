//
//  SAJson.h
//  FuAutoSensors
//
//  Created by Leo on 2021/12/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SAArchived : NSObject

+(instancetype)shareInstance;

-(void)writeDataToFile:(NSDictionary*)dic;
-(NSArray*)getFileArray;

-(NSString*)getZipFilePath;

-(NSString*)getZipFileData;

- (long long)fileSizeAtPath:(NSString*) filePath;
- (BOOL)showUploadZipData;
- (void)deleteSourceData;
@end

NS_ASSUME_NONNULL_END
