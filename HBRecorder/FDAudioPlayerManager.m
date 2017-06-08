 

#import "FDAudioPlayerManager.h" 
#import "FDMacros.h"
#import <AFNetworking/AFNetworking.h>
//#import "SMDBS2Manager.h"


@interface FDAudioPlayerManager()<AVAudioPlayerDelegate>

@property (nonatomic, strong,readonly) NSString * lastplayurl;
@property (nonatomic, strong) AVAudioSession *session;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSURL *recordFileURL;
@property (nonatomic, copy)   NSString *recordUrlKey;

@property (nonatomic, strong) NSURLSessionDownloadTask * task;
@end

@implementation FDAudioPlayerManager
@synthesize m_notifyObject = _m_notifyObject;//一次只下载一个文件
@synthesize playlist = _playlist;
+ (instancetype)sharedManager
{
    static FDAudioPlayerManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}
-(id)init{
    self = [super init];
    if (self) {
        [self activeAudioSession];
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)activeAudioSession
{
    self.session = [AVAudioSession sharedInstance];
    NSError *sessionError = nil;
    //AVAudioSessionCategoryPlayAndRecord // 开启始终以扬声器模式播放声音
    // AVAudioSessionCategoryAmbient //跟随系统播放模式
//    [self.session setCategory:AVAudioSessionCategoryPlayback  error:&sessionError];
    [self.session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:&sessionError];

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
    [[NSNotificationCenter  defaultCenter] addObserver:self selector:@selector(backToFrontNotify:) name:@"UIApplicationWillEnterForegroundNotification" object:nil];
    
}
//从后台回到前台
-(void)backToFrontNotify:(NSNotification *)notify{

    NSLog(@"从后台回到前台，刷新进度");
    [self updatePlayProgress];
    
}

-(NSString *)lastplayurl{
    return self.m_notifyObject.filepath;
}

-(void)nextAudio{
    NSString * path;
    NSInteger index = self.m_notifyObject.playindex.integerValue;//[self.playlist indexOfObject:self.lastplayurl];
    if (index < self.playlist.count-1) {
        index = index + 1;
        [self playWithIndex:index];
    }
}

-(void)lastAudio{
 
    NSInteger index = self.m_notifyObject.playindex.integerValue;
    if (index >0) {
        index = index - 1;
        [self playWithIndex:index];
    }
}

/**
 * 根据播放列表依次播放音频文件
 */
- (void)playWithIndex:(NSInteger)index{
    if (index < self.playlist.count) {
        NSString * path = self.playlist[index];
        self.m_notifyObject.playindex = @(index);
        [self playWithUrl:path];
    }
}
-(void)valiatePlayList{
    //方案一、去重，重复的音频音频只保留一条链接？ 方案二、或者可以播放重复的，但是会跳转到其他的
    //目前执行方案二，执行的进度依靠index来判断,主要影响在上下曲切换
    
}
-(void)cancelDownloading{
    [self.task cancel];
}
- (void)playWithUrl:(NSString *)url{
 
    [self playWithUrl:url duration:nil];
}
-(NSString *)filepathlastPathComponent:(NSString *)_filepath{
    return [NSURL URLWithString:_filepath].lastPathComponent;
}


-(NSString *)islocalfile:(NSString *)filePath{
   
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return filePath;
    }
    NSString * currentFilePath = [self mp3filePathWithFileName:[self filepathlastPathComponent:filePath]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:currentFilePath]) {
        return currentFilePath;
    }
    return nil;
}



- (void)playWithUrl:(NSString *)url duration:(void(^)(NSTimeInterval duration))block
{
    [self playWithUrl:url duration:block from:nil];
}

- (void)playWithUrl:(NSString *)url duration:(void(^)(NSTimeInterval duration))block from:(id)from{
 
    dispatch_queue_t queue = dispatch_queue_create("audio.fenda1.com", DISPATCH_QUEUE_SERIAL);
    //为了同步，先暂停再执行其他的
    dispatch_async(queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.player) {
                [self updateDownloadProgress:self.lastplayurl progress:0 localpath:nil state:FDAUDIO_STOP];
                [[NSNotificationCenter defaultCenter] postNotificationName:notify_audioplayer_stop object:self.m_notifyObject];
                    _playerState = FDAUDIO_STOP;
                    [self.player stop];
            }
        });
    });
    dispatch_async(queue, ^{ 
        dispatch_async(dispatch_get_main_queue(), ^{
            self.m_notifyObject.from = from;
            NSString *filePath = url;//AUDIORECORDFILEPATH(fileName);
            filePath = [filePath stringByReplacingOccurrencesOfString:@"smd.bs2ul" withString:@"smd.bs2dl"];
            
            if (!url) {
                //如果链接为空则播放上次的内容，上次未播放，则查找播放列表进行播放
                if (self.lastplayurl) {
                    filePath = self.lastplayurl;
                }else if (self.playlist.count) {
                    filePath = self.playlist[0];
                }
            }
            //是否存在本地
            NSString * currentFilePath = [self islocalfile:filePath];
            if ([[NSFileManager defaultManager] fileExistsAtPath:currentFilePath]) {
               
                NSURL * URL = [NSURL fileURLWithPath:currentFilePath];
                NSError *playerError = nil;
                _player = [[AVAudioPlayer alloc] initWithContentsOfURL:URL error:&playerError];
                _playerState = FDAUDIO_INIT;
                [self updateDownloadProgress:filePath progress:0 localpath:nil state:FDAUDIO_INIT];
                if (![self.playlist containsObject:filePath]) {
                    [self.playlist addObject:filePath];
                    NSLog(@"+++++++++++ add to playlist : %@",filePath);
                }
                if (self.player)  {
                    [self activeAudioSession];//防止ios8系统真机未激活
                    self.player.delegate = self;
                    if ([_player prepareToPlay]) {
                        [_player play];
                        _playerState = FDAUDIO_PLAYING;
                        if (block) {
                            block(self.player.duration);
                        }
                        [self updateDownloadProgress:filePath progress:0 localpath:nil state:FDAUDIO_PLAYING];
                        [[NSNotificationCenter defaultCenter] postNotificationName:notify_audioplayer_startplay object:self.m_notifyObject];
                        NSLog(@"self.player.duration:%f",self.player.duration);
                    }
                    else{
                        if(block)  block(0);
                        NSLog(@"no preparetoplay");
                    }
                }
                else {
                    if(block) block(0);
                    NSLog(@"Error creating player: %@", [playerError description]);
                }

            }
            else{
                if ([filePath hasPrefix:@"http://"] || [filePath hasPrefix:@"https://"]) {
                    
                    if (self.task) {
                        [self.task response];
                    }
                    
                    [self updateDownloadProgress:filePath progress:0 localpath:nil state:FDAUDIO_DOWNLOADINIT];
                    //BS2的音频，调用bs2的方式下载否则其他方式下载
                    @weakify(self);
                    
                        self.task = [self downloadAudioWithFilePath:filePath progress:^(CGFloat progress) {
                            @strongify(self);
                            [self updateDownloadProgress:filePath progress:progress localpath:nil state:FDAUDIO_DOWNLOADING];
                            
                        } error:^(NSError *error, NSString * localpathreslativestr) {
                            @strongify(self)
                            
                            if(!error.code){
                                if (self.m_notifyObject.state != FDAUDIO_DEALLOC) {
                                    [self updateDownloadProgress:filePath progress:0 localpath:localpathreslativestr state:FDAUDIO_DOWNLOADSUCCESS];
                                    [self playWithUrl:filePath duration:nil from:self.m_notifyObject.from];
                                }
                            }
                            if (error.code && error.code != -999) {
                                [self updateDownloadProgress:filePath progress:1 localpath:nil state:FDAUDIO_DOWNFAILD];
                            }
                            else if(error.code == FDAUDIO_DOWNLOADCANCEL){
                                
                                [self updateDownloadProgress:filePath progress:0 localpath:nil state:FDAUDIO_DOWNLOADCANCEL];
                            }
                        }];
                }
                
                else{
                    NSLog(@"无效的URL!");
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
    if (![filepath isEqualToString:self.lastplayurl]) {
        return  NO;
    }
    return YES;
}

/**
 *  是否正在播放
 */
-(BOOL)isplaying:(NSString *)filepath{
    
    if (!filepath) {
        if (_player) {
            return _player.isPlaying;
        }
    }
    if (![filepath isEqualToString:self.lastplayurl]) {
        return  NO;
    }
    if (_player) {
        return _player.isPlaying;
    }
    return NO;
}

//当前播放的时间
-(NSTimeInterval)currentPlayTime{
    
    return _player.currentTime;
}

-(CGFloat)currentPlayProgress{
    return (_player.currentTime/_player.duration);
}

//当前播放音频长度
-(NSTimeInterval)totalDuration{
    
    return _player.duration;
}

/**
 *  暂停
 */
-(void)pauseplay{
    
    [self.player pause];
    _playerState = FDAUDIO_PAUSE;        
    [self updateDownloadProgress:self.lastplayurl progress:(_player.currentTime/_player.duration) localpath:nil state:FDAUDIO_PAUSE];
    [[NSNotificationCenter defaultCenter] postNotificationName:notify_audioplayer_pause object:self.m_notifyObject];
    
}

/**
 * 停止播放
 */
-(void)stopPlay{
    [self.player stop];
}

/**
 * 播放的控件被移除了
 */
-(void)removeSuperView:(NSString *)filepath{
   
    if (!filepath || [filepath isEqualToString:self.lastplayurl]) {
        [self.player stop];
    }
    AFHTTPSessionManager *manager=[AFHTTPSessionManager manager];
    // 取消请求
    // 仅仅是取消请求, 不会关闭session
    [manager.tasks makeObjectsPerformSelector:@selector(cancel)];
    // 关闭session并且取消请求(session一旦被关闭了, 这个manager就没法再发送请求)
    //    [manager invalidateSessionCancelingTasks:YES];
    // 一个任务被取消了, 会调用AFN请求的failure这个block
    [_task cancel];
    [self updateDownloadProgress:self.lastplayurl progress:0 localpath:nil state:FDAUDIO_DEALLOC];
}

/**
 *  继续播放
 */
-(void)resumeplay{
    
    if (self.player) {
        [self.player play];
        _playerState = FDAUDIO_RESUME;
        [self updateDownloadProgress:self.lastplayurl progress:(_player.currentTime/_player.duration) localpath:nil state:FDAUDIO_RESUME];
        [[NSNotificationCenter defaultCenter] postNotificationName:notify_audioplayer_resume object:self.m_notifyObject];
    }
    else{
        [self playWithIndex:self.m_notifyObject.playindex.integerValue];
    }
    
}

-(void)playorpause{
    
    if ([self isplaying:nil]) {
        [self pauseplay];
    }else{
        [self resumeplay];
    }
}
#pragma mark - 播放结束
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    _playerState = FDAUDIO_STOP;
    
    [self updateDownloadProgress:self.lastplayurl progress:0 localpath:nil state:_playerState];
    [[NSNotificationCenter defaultCenter] postNotificationName:notify_audioplayer_stop object:self.m_notifyObject];
    if (self.autonext) {
        [self performSelector:@selector(nextAudio) withObject:nil afterDelay:0.5];
    }
} 


-(NSURLSessionDownloadTask *)downloadAudioWithFilePath:(NSString *)audiofilepath
                                              progress:(void(^)(CGFloat progress))progress
                                                 error:(void(^)(NSError * error,NSString * localfilepath))derror{
    
        AFHTTPSessionManager *session=[AFHTTPSessionManager manager];
    
        NSURLRequest *request=[NSURLRequest requestWithURL:[NSURL URLWithString:audiofilepath]];
        _task = [session downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
            //下载进度
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if(progress) progress(downloadProgress.fractionCompleted);
                
            }];
            
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            
            NSString *filePath = [self mp3filePathWithFileName:response.URL.lastPathComponent];
            //下载到哪个文件夹
            return [NSURL fileURLWithPath:filePath];
            
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            //下载完成了
            if (derror) {
                derror(error,filePath.relativePath);
            }
            NSLog(@"下载完成了 %@  \n错误：%@",filePath,error.description);
            if (!error) {
               
            }
            else{
                NSString *filePath = [self mp3filePathWithFileName:response.URL.lastPathComponent];
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    NSLog(@"下载失败删除源文件！");
                    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                }//这里不需要再刷新了其他地方刷新
                //[self updateDownloadProgress:audiofilepath progress:1 localpath:nil state:FDAUDIO_DOWNFAILD];
            };
        }];
    [_task resume];
    return _task;
}
-(FDAudioNotifyObject *)m_notifyObject{
    if (!_m_notifyObject) {
        _m_notifyObject = [FDAudioNotifyObject new];
        
    }
    return _m_notifyObject;
}

/**
 * 更新下载进度
 */
-(void)updateDownloadProgress:(NSString *)audiofilepath
                     progress:(CGFloat)progress
                    localpath:(NSString *)localpath
                        state:(FDAUDIO_STATE)state{
 
    FDAudioNotifyObject * obj = self.m_notifyObject;
    if (!obj) {
        obj = [FDAudioNotifyObject new];
    }
    obj.filepath = audiofilepath;
    obj.progress = @(progress);
    obj.localpath = localpath;
    obj.state = state;
    obj.duration = @(self.totalDuration - self.currentPlayTime);
    obj.totalDuration = @(self.totalDuration);
    obj.playprogress = [self playprogress];
    [self setValue:obj forKey:@"m_notifyObject"];
    if (state == FDAUDIO_PLAYING || state == FDAUDIO_RESUME) {
        [self handleNotification:YES];
    }
    if (state == FDAUDIO_STOP) {
        [self handleNotification:NO];
    }
}
-(void)updatePlayProgress{
    FDAudioNotifyObject * obj = self.m_notifyObject;
    if (!obj) {
        obj = [FDAudioNotifyObject new];
    }
    obj.duration = @(self.totalDuration - self.currentPlayTime);
    obj.totalDuration = @(self.totalDuration);
    obj.playprogress = [self playprogress];
    [self setValue:obj forKey:@"m_notifyObject"];
}

-(NSNumber *)playprogress{
    if (self.totalDuration) {
        return @(self.currentPlayTime/self.totalDuration);
    }
    else{
        return @0;
    } 
}
-(NSString *)mp3filePathWithFileName:(NSString *)FileName{
    
    NSString *docDirPath = AUDIODOWNLOADFILEPATH(FileName);
    //判断目录是否存在不存在则创建
    NSString *audioRecordDirectories = [docDirPath stringByDeletingLastPathComponent];
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:audioRecordDirectories]) {
        [fileManager createDirectoryAtPath:audioRecordDirectories withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return docDirPath;
}

-(void)setPlaylist:(NSMutableArray *)playlist{

    if (_playlist != playlist) {
        if (_m_notifyObject) {
            _m_notifyObject.playindex = @-1;
            _m_notifyObject.progress = @0;
            _m_notifyObject.state = FDAUDIO_STOP;
            _m_notifyObject.duration = @0;
            _m_notifyObject.playprogress = @0;
            _m_notifyObject.totalDuration = @0;
            [self stopPlay];
        }
        _playlist = playlist;
    }
}

-(NSMutableArray *)playlist{
    if (!_playlist) {
        _playlist = [NSMutableArray new];
    }
    return _playlist;
} 

#pragma mark - 监听听筒or扬声器
- (void) handleNotification:(BOOL)state
{
    [[UIDevice currentDevice] setProximityMonitoringEnabled:state];
    //建议在播放之前设置yes，播放结束设置NO，这个功能是开启红外感应
    
    if(state)//添加监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sensorStateChange:) name:@"UIDeviceProximityStateDidChangeNotification"
                                               object:nil];
    else//移除监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
}

-(void)sensorStateChange:(NSNotification *)notification{
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    if ([[UIDevice currentDevice] proximityState] == YES)
    {
        //靠近耳朵
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    }
    else
    {
        //远离耳朵
        [session setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    }
}

@end
