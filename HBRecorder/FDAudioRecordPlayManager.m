//
//  FDAudioRecordPlayManager.m
//  JLWeChat
//
//  Created by jimneylee on 14-10-26.
//  Copyright (c) 2014年 jimneylee. All rights reserved.
//

#import "FDAudioRecordPlayManager.h"
//#import "QNResourceManager.h"
#import "FDMacros.h"

@interface FDAudioRecordPlayManager()<AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioSession *session;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSURL *recordFileURL;
@property (nonatomic, copy)   NSString *recordUrlKey;

@end

@implementation FDAudioRecordPlayManager

+ (instancetype)sharedManager
{
    static FDAudioRecordPlayManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc ] init];
        [_sharedManager activeAudioSession];
    });
    
    return _sharedManager;
}

// 开启始终以扬声器模式播放声音
- (void)activeAudioSession
{
    self.session = [AVAudioSession sharedInstance];
    NSError *sessionError = nil;
    [self.session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (
                             kAudioSessionProperty_OverrideAudioRoute,
                             sizeof (audioRouteOverride),
                             &audioRouteOverride
                             );
    if(!self.session) {
        NSLog(@"Error creating session: %@", [sessionError description]);
    }
    else {
        [self.session setActive:YES error:nil];
    }
}
static NSString * lastplayurl;

- (void)playWithUrl:(NSString *)url{
    [self playWithUrl:url duration:nil];
}

- (void)playWithUrl:(NSString *)url duration:(void(^)(CGFloat duration))block
{
    dispatch_queue_t queue = dispatch_queue_create("audio.fenda.com", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(queue, ^{
        if (self.player) {
            if (self.player.isPlaying) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"FDAudioRecordPlayManager_didAudioPlayerStopPlay" object:lastplayurl];
                    [self.player stop];
                });
            }
            self.player = nil;
        }
    });
    
    dispatch_async(queue, ^{
       
//        NSString *fileName = [url lastPathComponent];
        NSString *filePath = url;//AUDIORECORDFILEPATH(fileName);
        NSURL *URL = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            URL = [NSURL fileURLWithPath:filePath];
        }
        else {
            URL = [NSURL URLWithString:url];
        }
        
        NSError *playerError = nil;
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:URL error:&playerError];
        
        if (self.player)  {
            dispatch_async(dispatch_get_main_queue(), ^{
                lastplayurl = url;
                self.player.delegate = self;
                [self.player play];
                if (block) {
                    block(self.player.duration);
                }
            });
            NSLog(@"self.player.duration:%f",self.player.duration);
        }
        else {
            NSLog(@"Error creating player: %@", [playerError description]);
            [self downloadMusicData:URL fileName:filePath.lastPathComponent duration:block];
        }
    });
}

-(void)downloadMusicData:(NSURL *)someURL fileName:(NSString *)fileName duration:(void(^)(CGFloat duration))block{

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"正在下载... %@",someURL);
        NSData *audioData = [NSData dataWithContentsOfURL:someURL];
        NSString *docDirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", docDirPath , fileName];
        [audioData writeToFile:filePath atomically:YES];
          NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.player) {
                [self.player stop];
                self.player = nil;
            }
            NSError *error;
            self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
      
            if (self.player == nil)
            { NSLog(@"AudioPlayer did not load properly: %@", [error description]); }
            else
            {
                lastplayurl = someURL.absoluteString;
                self.player.delegate = self;
                [self.player play];
                if (block) {
                    block(self.player.duration);
                }
            }
        });

    });

}

/**
 *  是否正在播放某一个url
 */
-(BOOL)iscurrentplayurl:(NSString *)filepath
{
    if (![filepath isEqualToString:lastplayurl]) {
        return  NO;
    }
    return YES;
}

/**
 *  是否正在播放
 */
-(BOOL)isplaying:(NSString *)filepath{
    
    if (![filepath isEqualToString:lastplayurl]) {
        return  NO;
    }
    if (_player) {
        return _player.isPlaying;
    }
    return NO;
}

/**
 *  暂停
 */
-(void)pauseplay:(NSString *)filepath{
   
    if ([filepath isEqualToString:lastplayurl]) {
        [self.player pause];
    }
}

/**
 *  继续播放
 */
-(void)resumeplay:(NSString *)filepath{
    
    if ([filepath isEqualToString:lastplayurl]) {
        [self.player play];
    }
    
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
     [[NSNotificationCenter defaultCenter] postNotificationName:@"FDAudioRecordPlayManager_didAudioPlayerStopPlay" object:lastplayurl];
}



#pragma mark - 录音器
//TODO:start record

- (void)startRecord
{
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = @"testuser";//[QNResourceManager generateAudioTimeKeyWithPrefix:MY_JID.user];
    NSString *filePath = [cacheDir stringByAppendingPathComponent:fileName];
    self.recordUrlKey = fileName;
    self.recordFileURL = [NSURL fileURLWithPath:filePath];
    self.recorder = [[AVAudioRecorder alloc] initWithURL:self.recordFileURL settings:nil error:nil];
    [self.recorder prepareToRecord];
    [self.recorder record];
}

- (void)stopRecordWithBlock:(void (^)(NSString *urlKey, NSInteger time))block
{
    [self.recorder stop];
#if 0
    AVURLAsset* audioAsset = [AVURLAsset URLAssetWithURL:self.recordFileURL options:nil];
    CMTime audioDuration = audioAsset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
#else
    // 暂时通过AVAudioPlayer获取音频时长，后面用更合理的方法替换，定时器是一个不优美、不准确的解决方式
    NSTimeInterval duration = 0;
    NSError *playerError = nil;
    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recordFileURL
                                                                        error:&playerError];
    if (audioPlayer)  {
        duration = audioPlayer.duration;
    }
    else {
        NSLog(@"Error creating player: %@", [playerError description]);
    }
#endif
    block(self.recordUrlKey, (NSInteger)(ceilf(duration)));
}

@end
