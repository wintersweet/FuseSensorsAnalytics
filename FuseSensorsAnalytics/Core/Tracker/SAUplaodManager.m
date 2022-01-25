//
//  SAUplaodManager.m
//  FuAutoSensors
//
//  Created by Leo on 2021/12/8.
//

#import "SAUplaodManager.h"
#import "SAArchived.h"
#import "AFNetworking.h"


#if ENV_PRODUCTION
//https://app.fuseinsurtech.com/fuse-log/operlog/log
#define  baseUrl               @"https://fuseinsurtech.com/f4/api/oss"
#define  fileUploadConfigUrl   @"https://fuseinsurtech.com/f4/api/log/track/config"

#elif ENV_PRERELEASE

#define  baseUrl              @"https://app.uat.fuseinsurtech.com/f4/api/oss"
#define  fileUploadConfigUrl  @"https://app.uat.fuseinsurtech.com/f4/api/log/track/config"

#elif ENV_STAGING

#define  baseUrl               @"https://open.sit.fuseinsurtech.com/f4/api/oss"
#define  fileUploadConfigUrl   @"https://open.sit.fuseinsurtech.com/f4/api/log/track/config"

#else

#define  baseUrl               @"https://app.uat.fuseinsurtech.com/f4/api/oss"
#define  fileUploadConfigUrl   @"https://dev.fusenano.com/f4/api/log/track/config"

#endif


#define  getUploadUrlPath     @"/store/upload/getUrl"
#define  TrackLogConfig       @"track_log_config"
@implementation SAUplaodManager
// 获得oss
+(void)getUploadUrl:(BOOL)uploadDirect{
    NSString *urlString = [NSString stringWithFormat:@"%@%@",baseUrl,getUploadUrlPath];
    NSArray  *arr =   @[@"fuse.zip"];
    NSDictionary *parameters = @{@"bizType": @"tracklog", @"fileNames":arr};
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.url = urlString;
        request.parameters = parameters;
        request.httpMethod = kXMHTTPMethodPOST;
        request.headers = @{@"Content-Type":@"application/json"};
        request.requestSerializerType = kXMRequestSerializerJSON;
        request.responseSerializerType = kXMResponseSerializerJSON;

    } onSuccess:^(id  _Nullable responseObject) {
        NSDictionary *jsonDic  = responseObject;
        NSArray * arr  = jsonDic[@"data"];
        if(arr){
            NSDictionary* dic = arr[0];
            NSString * url = dic[@"uploadUrl"];
            [SAUplaodManager uplaodZipData:url uploadDirect:uploadDirect];
        }

    } onFailure:^(NSError * _Nullable error) {
    }];
}
//上传数据
+(void)uplaodZipData:(NSString*)url uploadDirect:(BOOL)uploadDirect{
    // 是否直接上传，不判断大小
    if (!uploadDirect) {
        BOOL shouldUplaod =  [[SAArchived shareInstance] showUploadZipData];
        if (!shouldUplaod) {
            return;
        }
    }
    NSString * zipPath = [[SAArchived shareInstance] getZipFileData];
    if (zipPath.length < 1) {
        //解压失败，本次不上传数据了
        return;
    }
    NSData *data = [NSData dataWithContentsOfFile:zipPath];
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"PUT" URLString:url parameters:nil
       constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        if (data) {
            [formData appendPartWithFileData:data name:@"file" fileName:@"fuse.zip" mimeType:@"application/zip"];
        }
        
       } error:nil];
    request.timeoutInterval = 15.f;
    [request setValue:@"application/zip" forHTTPHeaderField:@"content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    manager.requestSerializer.timeoutInterval = 15.f;
    NSURLSessionUploadTask *uploadTask  =  [manager uploadTaskWithRequest:request fromData:data progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"上传中...");

    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (!error){
            NSLog(@"上传成功...");
            [[SAArchived shareInstance] deleteSourceData];
        }
    }];
    [uploadTask resume];
}
+(void)getFileUploadConfig{
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSDictionary * params = @{@"reqTimestamp":[NSString stringWithFormat:@"%d",(int)timeStamp]};
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.url = fileUploadConfigUrl;
        request.parameters = params;
        request.httpMethod = kXMHTTPMethodPOST;
        request.headers = @{@"Content-Type":@"application/json"};
        request.requestSerializerType = kXMRequestSerializerJSON;
        request.responseSerializerType = kXMResponseSerializerJSON;

    } onSuccess:^(id  _Nullable responseObject) {
        NSDictionary * dic = (NSDictionary*)responseObject;
        NSDictionary *saveDic = @{@"allowFileSize":dic[@"allowFileSize"],
                                  @"period":dic[@"period"]};
        if (saveDic) {
            [[NSUserDefaults standardUserDefaults] setValue:saveDic forKey:TrackLogConfig];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    } onFailure:^(NSError * _Nullable error) {
    }];

}

@end
