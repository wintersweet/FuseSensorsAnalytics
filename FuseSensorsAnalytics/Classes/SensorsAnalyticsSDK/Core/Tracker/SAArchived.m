//
//  SAJson.m
//  FuAutoSensors
//
//  Created by Leo on 2021/12/8.
//

#import "SAArchived.h"
#import <SSZipArchive/SSZipArchive.h>


@interface SAArchived ()

@property(nonatomic,strong)NSString* autoCacheDataPath;
@property(nonatomic,strong)NSString* renameCacheDataPath;

@end
@implementation SAArchived
//文件夹命
#define SensorsCachePath  @"SensorsCache/"
//压缩文件名
#define AutoCacheDataZipPath  @"fuseAnalyticeCache.zip"

#define  TrackLogConfig       @"track_log_config"



+(instancetype)shareInstance{
    static SAArchived * _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance =  [[self alloc]init];
        _instance.autoCacheDataPath = @"fuseAnalyticeCache.log";
    });
 
    return _instance;
}

-(void)writeDataToFile:(NSDictionary*)dic{
    NSArray *fileArr  = [self getFileArray];
    NSMutableArray * writeArr = [NSMutableArray arrayWithArray:fileArr];
    [writeArr addObject:dic];
    NSString * jsonStr = [self jsonStringFromArray:writeArr];
    if(jsonStr){
        BOOL result =  [jsonStr writeToFile:[self documentsPath:self.autoCacheDataPath]
                                 atomically:YES encoding:NSUTF8StringEncoding error:nil];
        NSLog(@"写入数据：%d",result);
    }
}
-(NSArray*)getFileArray{
    NSString *filePath = [self documentsPath:self.autoCacheDataPath];
    NSData   *data = [NSData dataWithContentsOfFile:filePath];
    NSArray * arr = [NSArray array];
    if (data) {
        arr =[NSJSONSerialization JSONObjectWithData:data
                                             options:NSJSONReadingAllowFragments error:nil];
    }
    return arr;
}

- (NSString *)jsonStringFromArray:(NSArray *)array {
    if (![array isKindOfClass:[NSArray class]] || ![NSJSONSerialization isValidJSONObject:array]) {
        return nil;
    }
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:0 error:nil];
    NSString *strJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return strJson;

}
#pragma --文件路径--
- (NSString*)documentsPath:(NSString*)fileName{
    return [[self documentPath] stringByAppendingPathComponent:fileName];
}
- (NSString*)documentPath{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *directory  = [paths objectAtIndex:0];
    NSString * filePath = [directory stringByAppendingPathComponent:SensorsCachePath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return filePath;
}
-(NSString*)getFilePath{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *directory  = [paths objectAtIndex:0];
    
    NSString * filePath = [directory stringByAppendingPathComponent:SensorsCachePath];
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:filePath]){
        [manager createFileAtPath:filePath contents:nil attributes:nil];
    }
    return filePath;
}
-(NSString*)getZipFilePath{
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *directory  = [paths objectAtIndex:0];
    return [directory stringByAppendingPathComponent:AutoCacheDataZipPath];
}
#pragma 每次上传的时候 再解压成zip格式上传
-(NSString*)getZipFileData{
    NSArray *fileArr  = [self getFileArray];
    if (fileArr.count <1) {
        return @"";
    }
    NSMutableArray * writeArr = [NSMutableArray arrayWithArray:fileArr];
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970]*1000;
    NSString *reportTime  = [NSString stringWithFormat:@"%.0f",timeStamp];
    
    NSMutableArray * newArr = [NSMutableArray array];
    [writeArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:obj];
        [dic setValue:reportTime forKey:@"reportTime"];
        [newArr addObject:dic];
    }];
    NSString * jsonStr = [self jsonStringFromArray:newArr];
    if(jsonStr){
        BOOL result =  [jsonStr writeToFile:[self documentsPath:self.autoCacheDataPath]
                                 atomically:YES encoding:NSUTF8StringEncoding error:nil];
        if (!result) {
            return @"";
        }
    }
    
    NSString * zipPath =  [self documentsPath:AutoCacheDataZipPath];
    NSString * sourcePath = [self documentsPath:self.autoCacheDataPath];
    if (![self setupFileRename:sourcePath]) {
        return @"";
    }
    NSString *reNameSourcePath = [self documentsPath:self.renameCacheDataPath];
    BOOL success =  [self archiveZipAtZipPath:zipPath forPath:reNameSourcePath];
    if (success) {
        return zipPath;
    }
    return @"";
}
- (BOOL)setupFileRename:(NSString *)filePath {
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSString *fileName  = [NSString stringWithFormat:@"%.0f",timeStamp];
    self.renameCacheDataPath = [NSString stringWithFormat:@"%@%@",fileName,@".log"];
    NSString *moveToPath =  [self documentsPath:self.renameCacheDataPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //通过移动该文件对文件重命名
    BOOL isSuccess = [fileManager moveItemAtPath:filePath toPath:moveToPath error:nil];
    if (isSuccess) {
        NSLog(@"rename success");
        return  YES;
    }else{
        NSLog(@"rename fail");
        return NO;
    }
}
#pragma 压缩文件
- (BOOL)archiveZipAtZipPath:(NSString *)zipPath forPath:(NSString *)sourcePath {
    BOOL success = [SSZipArchive createZipFileAtPath:zipPath withFilesAtPaths:@[sourcePath]];
    if (success) {
        NSLog(@"==压缩成功");
    }else{
        NSLog(@"==压缩失败");
    }
    return success;
}
#pragma 文件大小
-(BOOL)showUploadZipData{
    //判断源文件大小
    NSString* sourcePath =  [self documentsPath:self.autoCacheDataPath];
    long long size = [[SAArchived shareInstance] fileSizeAtPath:sourcePath];
    float kSize =  size/1024;
    
    float allowFileSize = 1024;
    NSDictionary* dic =[[NSUserDefaults standardUserDefaults] valueForKey:TrackLogConfig];
    if (dic[@"allowFileSize"]) {
        allowFileSize = [NSString stringWithFormat:@"%@",dic[@"allowFileSize"]].doubleValue;
    }
    if (kSize >= allowFileSize) {
        return YES;
    }
    return NO;
}
- (long long)fileSizeAtPath:(NSString*) filePath{

    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}
-(void)deleteSourceData{
    NSFileManager* manager = [NSFileManager defaultManager];
    NSString* sourcePath=  [self documentsPath:@"/"];
    
    if ([manager fileExistsAtPath:sourcePath]){
        [manager removeItemAtPath:sourcePath error:nil];
    }
   
}
@end
