

#import <AVFoundation/AVFoundation.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "FDRecorderButton.h"
#import "FDMacros.h"
#import "FDAudioPlayerManager.h"
#import <Lame/lame.h>

@interface FDRecorderButton()<AVAudioRecorderDelegate>{
//    MBProgressHUD *_progressHUD;        ///<指示器
    NSTimer *_timer;                    ///<定时器
    AVAudioRecorder *_recorder;         ///<录音 AVAudioRecorder
    BOOL _sendFlag;                     ///<YES发送，NO没有发送
    
    NSString *_originTitle;             ///<原始titile
    NSString *_changeTitle;             ///<改动title
    NSString *_upChangeTitle;           ///<上滑改动title
    
    UIImage *_originImage;              ///<原始Image
    UIImage *_changeImage;              ///<改动Image
    UIImage *_upChangeImage;            ///<上滑改动Image
    
    UIImage *_originBackgroundImage;    ///<原始groundImage
    UIImage *_changeBackgroundImage;    ///<改动groundImage
    UIImage *_upChangeBackgroundImage;  ///<上滑改动groundImage
    
    NSString * lastaudioRecordFilePath;
    NSString * mp3AudioRecodeFilePath;
    BOOL _volumeAnimation;              ///<音量变化
    
    FDAudioPlayerManager * playerManager;
}


@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) CALayer *gradientLayer;
@property (nonatomic, strong) CAGradientLayer *leftLayer;
@property (nonatomic, strong) CAGradientLayer *rightLayer;
@property (nonatomic, assign) CGFloat AudioRealDuration;

@property (nonatomic, assign) BOOL isAddAudioObserver;
@property (nonatomic, assign) NSInteger valiateCode;
@property (nonatomic, strong) CALayer * historyProgressCircle;//历史播放轨迹
@end

@implementation FDRecorderButton
#pragma mark - 生命周期
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //初始化
        [self initial];
    }
    return self;
}
- (void)awakeFromNib
{
    //初始化
    [super awakeFromNib];
    [self initial];
}
#pragma mark 初始化
- (void)initial
{
    playerManager = [FDAudioPlayerManager sharedManager];//[[FDAudioPlayerManager alloc] init];
    self.recorderDuration=RECORDER_DURATION;
    _originImage=self.imageView.image;
    _originTitle=self.titleLabel.text;
    _originBackgroundImage=self.currentBackgroundImage;
    self.adjustsImageWhenHighlighted=NO;
    //按下
    [self addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
//    //内部松开
//    [self addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
//    //外部松开
//    [self addTarget:self action:@selector(touchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
//    //进入内部
//    [self addTarget:self action:@selector(touchDragEnter:) forControlEvents:UIControlEventTouchDragEnter];
//    //进入外部
//    [self addTarget:self action:@selector(touchDragExit:) forControlEvents:UIControlEventTouchDragExit];
//    //触摸取消事件
//    [self addTarget:self action:@selector(touchCancel:) forControlEvents:UIControlEventTouchCancel];
}
#pragma mark - 重写Button方法
#pragma 重写高亮的方法
//- (void)setHighlighted:(BOOL)highlighted{}
#pragma mark title方法重写
- (void)setTitle:(NSString *)title forState:(UIControlState)state
{
    [super setTitle:title forState:state];
    if (state==UIControlStateNormal) {
        if (_originTitle==nil) {
            _originTitle=title;
        }
        if (_changeTitle==nil) {
            _changeTitle=title;
        }
        if (_upChangeTitle==nil) {
            _upChangeTitle=title;
        }
    }
}
#pragma mark image方法重写
- (void)setImage:(UIImage *)image forState:(UIControlState)state
{
    [super setImage:image forState:state];
    if (state==UIControlStateNormal) {
        if(_originImage==nil){
            _originImage=image;
        }
        if (_changeImage==nil) {
            _changeImage=image;
        }
        if (_upChangeImage==nil) {
            _upChangeImage=image;
        }
    }
}
#pragma mark backgroundImage方法重写
- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state
{
    [super setBackgroundImage:image forState:state];
    if (state==UIControlStateNormal) {
        if(_originBackgroundImage==nil){
            _originBackgroundImage=image;
        }
        if (_changeBackgroundImage==nil) {
            _changeBackgroundImage=image;
        }
        if (_upChangeBackgroundImage==nil) {
            _upChangeBackgroundImage=image;
        }
    }
}
#pragma mark - 类公有方法
#pragma mark 设置改动标题
- (void)setChangeTitle:(NSString *)title
{
    _changeTitle=title;
    if ([_upChangeTitle isEqualToString:_originTitle]) {
        _upChangeTitle=_changeTitle;
    }
}
#pragma mark 设置上滑改动标题
- (void)setUpChangeTitle:(NSString *)title
{
    _upChangeTitle=title;
}
#pragma mark 设置改动图片
- (void)setChangeImage:(UIImage *)image
{
    _changeImage=image;
    if ([_upChangeImage isEqual:_originImage]) {
        _upChangeImage=_changeImage;
    }
}
#pragma mark 设置上滑改动图片
- (void)setUpChangeImage:(UIImage *)image
{
    _upChangeImage=image;
}
#pragma mark 设置改动背景图片
- (void)setChangeBackgroundImage:(UIImage *)backgroundImage
{
    _changeBackgroundImage=backgroundImage;
    if ([_upChangeBackgroundImage isEqual:_originBackgroundImage]) {
        _upChangeBackgroundImage=_changeBackgroundImage;
    }
}

#pragma mark 设置上滑改动背景图片
- (void)setUpChangeBackgroundImage:(UIImage *)backgroundImage
{
    _upChangeBackgroundImage=backgroundImage;
}
#pragma mark - 自定义Target方法
#pragma mark 点击按钮，开始录音~~~~~~~~~~~~~~~~~~~~~~
- (void)touchDown:(UIButton *)button
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(FDRecorderButtonRecordMode:)]) {
        RECORD_MODE mode = [self.delegate FDRecorderButtonRecordMode:self];
        if (mode == RECORD_MODE_RECORD_PLAY) {
            [self runRecordAndPlayMode];
        }
        else{
            [self runRecordPauseMode];
        }
    }
    else{
        [self runRecordPauseMode];
    }
    //注册进入后台监听事件
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}


-(void)runRecordAndPlayMode{
    
    if (!_recorder) {
        [self startRecord];
    }
    else{
        //没有监听播放完成时间，从timer里面得到播放完成的通知
        RECORD_STATE nextstat = [self nextState:self.recordstate];
        
        NSLog(@"\n\nRECORD-STATE : %ld \n\n",nextstat);
        
        //下一个状态是A 则执行A的事件
        if (nextstat ==  RECORD_PAUSE) {
            [self pauseRecord];
        }
        if (nextstat ==  RECORD_STOP) {
            [self stopRecord];
        }
        if (nextstat == RECORD_PLAYING) {
            [self playVoice];
        }
        if (nextstat == RECORD_FINISH) {
            [self stopPlayVoice];
        }
        if (nextstat == RECORD_PLAYFINISH) {
            [self stopPlayVoice];
        }
        if (nextstat == RECORD_NONE) {
            [self playVoice];
        }
        
    }
}


-(void)runRecordPauseMode{
    
    if (!_recorder) {
        [self startRecord];
    }
    else{
        if (_recorder.isRecording) {
            [self pauseRecord];
        }
        else{
            if (_progress >= 1) {
                [self startRecord];
            }
            else{
                [self restartRecord];
            }
        }
    }
}

-(RECORD_MODE)recordmode{
    if (self.delegate && [self.delegate respondsToSelector:@selector(FDRecorderButtonRecordMode:)]) {
        return [self.delegate FDRecorderButtonRecordMode:self];
    }
    return RECORD_MODE_RECORD_PLAY;
}

//创建状态机
-(RECORD_STATE )nextState:(RECORD_STATE)curstate{
    if (self.recordmode == RECORD_MODE_RECORD_PAUSE) {
        if (curstate == RECORD_INIT) {
            return RECORD_RECORDING;
        }
        else if(curstate == RECORD_RECORDING){
            return RECORD_PAUSE;
        }
        else if(curstate == RECORD_PAUSE){
            return RECORD_RECORDING;
        }
    }
    else{//录一遍，播放一遍的模式
        if (curstate == RECORD_RECORDING) {
            return RECORD_STOP;
        }
        else if(curstate == RECORD_PAUSE){
            return RECORD_PLAYING;
        }
        else if(curstate == RECORD_PAUSE){
            return RECORD_PLAYING;
        }
        else if(curstate == RECORD_PLAYING){
            return  RECORD_PLAYFINISH;
        }
        else if(curstate == RECORD_PLAYFINISH){
            return  RECORD_PLAYING;
        }
    }
    return RECORD_NONE;
}

-(void)playVoice{
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, queue, ^{
          dispatch_async(dispatch_get_main_queue(), ^{
              self.isAddAudioObserver = YES;
          });
    });
    dispatch_group_notify(group, queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            @weakify(self)
            [playerManager playWithUrl:lastaudioRecordFilePath duration:^(NSTimeInterval duration){
                @strongify(self)
                self.AudioRealDuration = duration;
                mRemainTime = self.recorderDuration;
                self.recordstate = RECORD_PLAYING;
                
            } from:self];
            
        });
    });
    
}

-(void)stopPlayVoice{
    
    self.recordstate = RECORD_PLAYFINISH;
    [playerManager pauseplay];
    
}


#pragma mark - 录音状态改变，触发UI的变化 ~~~~~~~~~~~~
-(void)setRecordstate:(RECORD_STATE)recordstate{
    _recordstate = recordstate;
    if (self.delegate && [self.delegate respondsToSelector:@selector(FDRecorderButton:recordStateChanged:)]) {
        [self.delegate FDRecorderButton:self recordStateChanged:recordstate];
    }
    
    if (recordstate == RECORD_PLAYING || recordstate == RECORD_RECORDING) {
        self.selected = YES;
        if (!_timer) {
            _timer=[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(volumeMeters:) userInfo:nil repeats:YES];
        }
        if (recordstate == RECORD_PLAYING) {
            if (!_historyProgressCircle) {
                _historyProgressCircle = [self drawHistoryCycleProgress:self.AudioRealDuration/(CGFloat)self.recorderDuration];
            }
        }
        else{
            if (_historyProgressCircle) {
                [_historyProgressCircle removeFromSuperlayer];
                _historyProgressCircle = nil;
            }
        }
        return;
    }
    else if (recordstate == RECORD_INIT) {
//        _timer=[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(volumeMeters:) userInfo:nil repeats:YES];
     }
    else if (recordstate == RECORD_FINISH){
        _sendFlag=NO;
    }
    else if (recordstate == RECORD_STOP){
        _sendFlag=NO;
//        [self drawProgress:0];
    }
    
    if (_timer && [_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
    self.selected = NO;

}

/**
 *  发送语音
 */
-(void)sendAudio{
    
    [self sendAudioMessageWithSendFlag:YES timeout:NO];
    NSLog(@"\nFILEPATH:音频路径 %@  ",lastaudioRecordFilePath);
}

/**
 *  继续录音
 */
-(void)restartRecord{
    self.selected = YES;
    if ([_recorder prepareToRecord]) {
        //录音最长时间
        [_recorder recordForDuration:self.recorderDuration];
        [_recorder record];
    }
    self.recordstate = RECORD_RECORDING;
}
/**
 *  暂停录音
 */
-(void)pauseRecord
{
    [_recorder pause];
    self.recordstate = RECORD_PAUSE;
}

/**
 *  开始录制音频
 */
-(void)startRecord{

    if (_recorder) {
        [_recorder stop];
    }
    _recorder = nil;
    _sendFlag=NO;
    _volumeAnimation=YES;
    
    if (![self canRecord]) {
        return;
    }
    [self setTitle:_changeTitle forState:UIControlStateNormal];
    [self setImage:_changeImage forState:UIControlStateNormal];
    //设置AVAudioRecorder
    mRemainTime = self.recorderDuration;
    [self initialRecord];
    //指示器设置
    //        [self initialProgressHUD];
    self.selected = YES;
    self.recordstate = RECORD_RECORDING;
}



/**
 *  停止录制
 */
-(void)stopRecord{
    
    [_recorder stop];
    self.recordstate = RECORD_STOP;
}

//
///**
// *  提交录制
// */
//-(void)submitRecord{
//    
//    self.recordstate = RECORD_STOP;
//    //停止运行计时器
//    if (_timer && [_timer isValid]) {
//        [_timer invalidate];
//    }
//    if (_recorder) {
//        [self sendAudioMessageWithSendFlag:NO timeout:NO];
//        _recorder = nil;
//    }
//    _sendFlag=NO;
//    _timer = nil;
//    [self drawProgress:0];
//    self.selected = NO;
//}



/**
 *  重新录制
 */
-(void)reRecord{
 
    //创建一个串行队列
   dispatch_queue_t queueConcurrent = dispatch_queue_create("com.juhui.fenda", DISPATCH_QUEUE_SERIAL);
    
   dispatch_async(queueConcurrent, ^{
       dispatch_async(dispatch_get_main_queue(), ^{
           [self stopRecord];
       });
    });
   dispatch_async(queueConcurrent, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startRecord];
        });
    });
}





#pragma mark 进入内部
- (void)touchDragEnter:(UIButton *)button
{
    [button setTitle:_changeTitle forState:UIControlStateNormal];
    [button setImage:_changeImage forState:UIControlStateNormal];
    [button setBackgroundImage:_changeBackgroundImage forState:UIControlStateNormal];
    //    [self progressHUDLabel:@"手指上滑，取消发送" warning:NO];
    //    [self progressHUDImageView:[UIImage imageNamed:@"ButtonAudioRecorder.bundle/record_animate_1.png"] animation:YES];
}
#pragma mark 进入外部
- (void)touchDragExit:(UIButton *)button
{
    [button setTitle:_upChangeTitle forState:UIControlStateNormal];
    [button setImage:_upChangeImage forState:UIControlStateNormal];
    [button setBackgroundImage:_upChangeBackgroundImage forState:UIControlStateNormal];
    //    [self progressHUDLabel:@"松开手指，取消发送" warning:YES];
    //    [self progressHUDImageView:[UIImage imageNamed:@"ButtonAudioRecorder.bundle/record_revocation.png"] animation:NO];
}

#pragma mark 内部松开，发送语音
- (void)touchUpInside:(UIButton *)button
{
    if (!_sendFlag) {
        //发送语音
        //TODO: 发送语音
        NSString * MP3path = [lastaudioRecordFilePath stringByReplacingOccurrencesOfString:@".caf" withString:@".mp3"];
        mp3AudioRecodeFilePath = MP3path;
        [self audio_PCMtoMP3:lastaudioRecordFilePath andMP3FilePath:mp3AudioRecodeFilePath complete:nil];
    }
}

#pragma mark - MP3转码成功 发送
-(void)convert2Mp3Success:(BOOL)timeout
{
    [self sendAudioMessageWithSendFlag:YES timeout:timeout];
}

#pragma mark 外部松开,取消发送语音
- (void)touchUpOutside:(UIButton *)button
{
    if (!_sendFlag) {
        //取消发送语音
        [self sendAudioMessageWithSendFlag:NO timeout:NO];
    }
}
#pragma mark 触摸取消事件
- (void)touchCancel:(UIButton *)sender
{
    if (!_sendFlag) {
        [self sendAudioMessageWithSendFlag:NO timeout:NO];
    }
}
//#pragma mark 程序进入后台
//- (void)applicationWillResignActive:(NSNotification *)notification
//{
//    if (!_sendFlag) {
//        [self sendAudioMessageWithSendFlag:NO timeout:NO];
//    }
//}
#pragma mark - AVAudioRecorderDelegate委托事件
#pragma mark 录音结束
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (!_sendFlag) {
        if (self.autosubmit) {
            //录制完成自动提交
            [self sendAudio];
        }
        else{
            [self pauseRecord];
        }
    }
}

#pragma mark - 类私有方法
#pragma mark AVAudioRecorder设置


- (void)initialRecord
{
    //录音权限设置，IOS7必须设置，得到AVAudioSession单例对象
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //设置类别,此处只支持支持录音
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    //启动音频会话管理,此时会阻断后台音乐的播放
    [audioSession setActive:YES error:nil];
    //录音参数设置设置
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc]init];
    //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM
    //    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    //caf的录制格式
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    
    //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）//acc的采样频率
    //    [recordSetting setValue:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
    
    [recordSetting setValue:[NSNumber numberWithFloat:11025.0] forKey:AVSampleRateKey];
    //录音通道数  1 或 2
    [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    //线性采样位数  8、16、24、32
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    //    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    
    //录音文件保存的URL
    CFUUIDRef cfuuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *cfuuidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, cfuuid));
    NSString * filename = [NSString stringWithFormat:@"%@.caf",cfuuidString];
    NSString *audioRecordFilePath = AUDIORECORDFILEPATH(filename);
    lastaudioRecordFilePath = audioRecordFilePath;
    
    //判断目录是否存在不存在则创建
    NSString *audioRecordDirectories = [audioRecordFilePath stringByDeletingLastPathComponent];
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:audioRecordDirectories]) {
        [fileManager createDirectoryAtPath:audioRecordDirectories withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSURL *url = [NSURL fileURLWithPath:audioRecordFilePath];
    NSError *error=nil;
    //初始化AVAudioRecorder
    _recorder = [[AVAudioRecorder alloc]initWithURL:url settings:recordSetting error:&error];
    if (error != nil) {
        //NSLog(@"初始化录音Error: %@",error);
    }else{
        self.recordstate = RECORD_INIT;
        
        if ([_recorder prepareToRecord]) {
            //录音最长时间
            [_recorder recordForDuration:self.recorderDuration];
            _recorder.delegate=self;
            [_recorder record];
            //开启音量检测
            _recorder.meteringEnabled = YES;
            //开启定时器，音量监测
//            _timer=[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(volumeMeters:) userInfo:nil repeats:YES];
        }
    }
}

//判断是否允许使用麦克风7.0新增的方法requestRecordPermission
-(BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    bCanRecord = YES;
                }
                else {
                    bCanRecord = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:nil
                                                    message:@"需要访问您的麦克风。\n请启用麦克风-设置/隐私/麦克风"
                                                   delegate:nil
                                          cancelButtonTitle:@"关闭"
                                          otherButtonTitles:nil] show];
                    });
                }
            }];
        }
    }
    
    return bCanRecord;
}

static CGFloat mRemainTime = RECORDER_DURATION;
#pragma mark ****实时监测 进度变化****~~~~~~~~~~~~~~~~~~~~~~
- (void)volumeMeters:(NSTimer *)timer
{
    mRemainTime = mRemainTime - 0.05;
    CGFloat progress = 0;
    if (self.recordstate == RECORD_RECORDING) {
        progress = (mRemainTime)/(float)self.recorderDuration;
    }
    if (self.recordstate == RECORD_PLAYING) {
        CGFloat currentTime = self.AudioRealDuration;
        //(_recorder.isRecording || (_recorder.currentTime>0))?_recorder.currentTime:_progress*self.recorderDuration;
        progress = (mRemainTime)/self.recorderDuration;
        if (mRemainTime < (self.recorderDuration - currentTime)) {//到了最大的播放时长则暂停
            progress = 0;
            self.recordstate = RECORD_PLAYFINISH;
        }
    }
    if (progress <=0) {
//        [_timer invalidate];
//        _timer = nil;
//        self.selected = NO;
        self.recordstate = RECORD_PLAYFINISH;
        return;
    }
    //NSLog(@"%.2f",progress);
    [self drawProgress:1-progress];
    if (mRemainTime < 10) {//小于10秒提示
//        [self progressHUDCenterLabel:[NSString stringWithFormat:@"%d",(int)mRemainTime] warning:NO];
        return;
    }
 
    
}


#pragma mark 发送语音信息
/**
 *  发送语音信息
 *
 *  @param sendflag    YES发送，NO取消发送
 *  @param timeoutFlag YES超时，NO没有超时
 */
- (void)sendAudioMessageWithSendFlag:(BOOL)sendflag timeout:(BOOL)timeoutFlag
{
    if (!_recorder) {//防止重复提交录音
       [[[UIAlertView alloc] initWithTitle:@"提示" message:@"请勿重复提交！" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil] show];
        return;
    }
    @synchronized (self) {
        //获取录音时长
        mRemainTime = self.recorderDuration;
        
        CGFloat currentTime =(_recorder.isRecording || (_recorder.currentTime>0))?_recorder.currentTime:_progress*self.recorderDuration;
        double longTime=timeoutFlag?self.recorderDuration:currentTime;
        
        //停止录音
        [_recorder stop];
        //录音权限设置
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        [audioSession setActive:NO error:nil]; 
        //button状态切换
        [self setTitle:_originTitle forState:UIControlStateNormal];
        //    [self setImage:_originImage forState:UIControlStateNormal];
        [self setBackgroundImage:_originBackgroundImage forState:UIControlStateNormal];
        //停止运行计时器
        self.recordstate = RECORD_FINISH;
        //发送语音
        NSMutableDictionary *dicAudioInfo=[[NSMutableDictionary alloc]init];
        if (sendflag) {             //发送语音
            if (longTime<1) {
                //0.5秒后隐藏指示器
                [[[UIAlertView alloc] initWithTitle:@"提示" message:@"说话时间太短！" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil] show];
                //删除录音文件
                [_recorder deleteRecording];
                sendflag=NO;
                self.recordstate = RECORD_FAILED;
            }else{
                
                //音频转码
                NSString * MP3path = [lastaudioRecordFilePath stringByReplacingOccurrencesOfString:@".caf" withString:@".mp3"];
                @weakify(self)
                [self audio_PCMtoMP3:lastaudioRecordFilePath andMP3FilePath:MP3path complete:^(NSError *err) { @strongify(self)
                    if (!err) {
                        [dicAudioInfo setValue:MP3path forKey:AudioRecorderPath];
                        [dicAudioInfo setValue:[MP3path lastPathComponent] forKey:AudioRecorderName];
                        [dicAudioInfo setValue:[NSString stringWithFormat:@"%.0f",(longTime*10+0.5)/10] forKey:AudioRecorderDuration];
                        
                        if (self.delegate && [self.delegate respondsToSelector:@selector(FDRecorderButton:didFinishRcordWithAudioInfo:sendFlag:)]) {
                            //调用委托
                            [self.delegate FDRecorderButton:self didFinishRcordWithAudioInfo:dicAudioInfo sendFlag:sendflag];
                            
                        }
                    }
                }];
                
            }
        }else{
            //取消发送
            [_recorder deleteRecording];
            self.recordstate = RECORD_FAILED;
            return;
        }
    }
   
}


#pragma mark -  画进度条

- (void)drawProgress:(CGFloat )progress
{
    _progress = progress;
    _progressLayer.opacity = 0;
    [self setNeedsDisplay];
    if (self.delegate && [self.delegate respondsToSelector:@selector(FDRecorderButton:recordProgress:)]) {
        [self.delegate FDRecorderButton:self recordProgress:progress];
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    [self drawCycleProgress];
    
}

- (void)drawCycleProgress
{
    CGPoint center = CGPointMake(self.bounds.size.width/2  , self.bounds.size.height/2);
    CGFloat radius = (self.bounds.size.width-5)/2;
    CGFloat startA = - M_PI_2;  //设置进度条起点位置
    CGFloat endA = -M_PI_2 + M_PI * 2 * _progress;  //设置进度条终点位置
    
    //获取环形路径（画一个圆形，填充色透明，设置线框宽度为10，这样就获得了一个环形）
    if (!_progressLayer) {
        _progressLayer = [CAShapeLayer layer];//创建一个track shape layer
        _progressLayer.frame = self.bounds;
     }
    _progressLayer.fillColor = [[UIColor clearColor] CGColor];  //填充色为无色
    _progressLayer.strokeColor = [[UIColor orangeColor] CGColor]; //指定path的渲染颜色,这里可以设置任意不透明颜色
    _progressLayer.opacity = 1; //背景颜色的透明度
    _progressLayer.lineCap = kCALineCapRound;//指定线的边缘是圆的
    _progressLayer.lineWidth = 3;//线的宽度
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startA endAngle:endA clockwise:YES];//上面说明过了用来构建圆形
    _progressLayer.path =[path CGPath]; //把path传递給layer，然后layer会处理相应的渲染，整个逻辑和CoreGraph是一致的。
    
    //生成渐变色
    if (!_gradientLayer) {
        CALayer *gradientLayer = [CALayer layer];
        _gradientLayer = gradientLayer;
    }
    
    //左侧渐变色
    if (!_leftLayer) {
        CAGradientLayer *leftLayer = [CAGradientLayer layer];
        _leftLayer = leftLayer;
        [_gradientLayer addSublayer:_leftLayer];
    }
    _leftLayer.frame = CGRectMake(0, 0, self.bounds.size.width / 2, self.bounds.size.height);    // 分段设置渐变色
    _leftLayer.locations = @[@0.3, @0.9, @1];
    _leftLayer.colors = @[(id)KT_HEXCOLOR(0x7a60f0).CGColor, (id)[UIColor purpleColor].CGColor];
    
//    //右侧渐变色
    if (!_rightLayer) {
        CAGradientLayer *rightLayer = [CAGradientLayer layer];
        _rightLayer = rightLayer;
        [_gradientLayer addSublayer:_rightLayer];
    }
    _rightLayer.frame = CGRectMake(self.bounds.size.width / 2, 0, self.bounds.size.width / 2, self.bounds.size.height);
    _rightLayer.locations = @[@0.3, @0.9, @1];
    _rightLayer.colors = @[(id)KT_HEXCOLOR(0x7a60f0).CGColor, (id)[UIColor purpleColor].CGColor];
    
    [_gradientLayer setMask:_progressLayer]; //用progressLayer来截取渐变层
    [self.layer addSublayer:_gradientLayer];
    
}

- (CALayer *)drawHistoryCycleProgress:(CGFloat)progress
{
    CGPoint center = CGPointMake(self.bounds.size.width/2  , self.bounds.size.height/2);
    CGFloat radius = (self.bounds.size.width-5)/2;
    CGFloat startA = - M_PI_2;  //设置进度条起点位置
    CGFloat endA = -M_PI_2 + M_PI * 2 * _progress;  //设置进度条终点位置
    
    //获取环形路径（画一个圆形，填充色透明，设置线框宽度为10，这样就获得了一个环形）
     CAShapeLayer * progressLayer = [CAShapeLayer layer];//创建一个track shape layer
    progressLayer.frame = self.bounds;
//    [self.layer addSublayer:progressLayer];
    progressLayer.fillColor = [[UIColor clearColor] CGColor];  //填充色为无色
    progressLayer.strokeColor = [[UIColor orangeColor] CGColor]; //指定path的渲染颜色,这里可以设置任意不透明颜色
    progressLayer.opacity = 1; //背景颜色的透明度
    progressLayer.lineCap = kCALineCapRound;//指定线的边缘是圆的
    progressLayer.lineWidth = 3;//线的宽度
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startA endAngle:endA clockwise:YES];//上面说明过了用来构建圆形
    progressLayer.path =[path CGPath]; //把path传递給layer，然后layer会处理相应的渲染，整个逻辑和CoreGraph是一致的。
    
    //生成渐变色
        CALayer *gradientLayer = [CALayer layer];
//        gradientLayer = gradientLayer;
  
    
    //左侧渐变色
    CAGradientLayer *leftLayer = [CAGradientLayer layer];
    [gradientLayer addSublayer:leftLayer];
    UIColor * lightredcolor = [UIColor colorWithRed:102/255. green:61/255. blue:245./255. alpha:0.3];
    UIColor * lightpurpscolor = [UIColor colorWithRed:107./255. green:0./255. blue:108./255. alpha:0.3];
    
    leftLayer.frame = CGRectMake(0, 0, self.bounds.size.width / 2, self.bounds.size.height);    // 分段设置渐变色
    leftLayer.locations = @[@0.3, @0.9, @1];
    leftLayer.colors = @[(id)lightredcolor.CGColor, (id)lightpurpscolor.CGColor];
    
    //    //右侧渐变色
    CAGradientLayer *rightLayer = [CAGradientLayer layer];
    [gradientLayer addSublayer:rightLayer];
   
    rightLayer.frame = CGRectMake(self.bounds.size.width / 2, 0, self.bounds.size.width / 2, self.bounds.size.height);
    rightLayer.locations = @[@0.3, @0.9, @1];
    rightLayer.colors = @[(id)lightredcolor.CGColor, (id)lightpurpscolor.CGColor];
    
    [gradientLayer setMask:progressLayer]; //用progressLayer来截取渐变层
    [self.layer addSublayer:gradientLayer];
    
    return gradientLayer;
}




#pragma mark - 添加播放器监听
-(void)setIsAddAudioObserver:(BOOL)isAddAudioObserver{
    
    if (_isAddAudioObserver != isAddAudioObserver) {
        _isAddAudioObserver = isAddAudioObserver;
        if (isAddAudioObserver) {
            [self addAudioObserVer];
        }
        else{
            [self removeAudioObserver];
        }
    }
    
}
-(void)IMAudioRecordPlayManager_didAudioPlayerStopPlay:(NSNotification *)notify
{
    FDAudioNotifyObject * notifyobj = notify.object;
//    NSString * playurl = notifyobj.filepath;
    id from = notifyobj.from;
    if(from == self)
    {
        self.recordstate = RECORD_PLAYFINISH;
        self.isAddAudioObserver = NO;
    }
}

-(void)IMAudioRecordPlayManager_didAudioPlayerStartPlay:(NSNotification *)notify{
    
    FDAudioNotifyObject * playurl = notify.object;
    if(playurl.from == self) //([playurl.lastPathComponent isEqualToString:lastaudioRecordFilePath.lastPathComponent])
    {
        //这个时机很重要，开始播放了已经就初始化这个校验码
        self.valiateCode = [NSDate timeIntervalSinceReferenceDate];
        NSLog(@"valiateCode %ld",(long)self.valiateCode);
        playerManager.valiateCode = self.valiateCode;
        
    }
    
}

-(void)IMAudioRecordPlayManager_didAudioPlayerResumePlay:(NSNotificationCenter *)notify{

    
}

-(void)addAudioObserVer{
    
    [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(IMAudioRecordPlayManager_didAudioPlayerStopPlay:) name:notify_audioplayer_stop object:nil];
    [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(IMAudioRecordPlayManager_didAudioPlayerStartPlay:) name:notify_audioplayer_startplay object:nil];
    [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(IMAudioRecordPlayManager_didAudioPlayerResumePlay:) name:notify_audioplayer_resume object:nil];
    
}

-(void)removeAudioObserver{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notify_audioplayer_stop object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notify_audioplayer_startplay object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notify_audioplayer_resume object:nil];
}




-(void)dealloc{ 
    self.isAddAudioObserver = NO;
}
//#pragma  -  转编码为 mp3
//
- (void)audio_PCMtoMP3:(NSString *)cafFilePath andMP3FilePath:(NSString *)mp3FilePath complete:(void(^)(NSError * err))complete
{
    NSFileManager* fileManager=[NSFileManager defaultManager];
    if([fileManager removeItemAtPath:mp3FilePath error:nil]) {
        NSLog(@"删除");
    }
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        
        if(pcm == NULL) {
            NSLog(@"file not found");
        } else {
            fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
            FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
            
            const int PCM_SIZE = 8192;
            const int MP3_SIZE = 8192;
            short int pcm_buffer[PCM_SIZE*2];
            unsigned char mp3_buffer[MP3_SIZE];
            
            lame_t lame = lame_init();
            lame_set_in_samplerate(lame, 11025.0);
            lame_set_VBR(lame, vbr_default);
            lame_init_params(lame);
            
            do {
                read = fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
                if (read == 0)
                    write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
                else
                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                
                fwrite(mp3_buffer, write, 1, mp3);
                
            } while (read != 0);
            
            lame_close(lame);
            fclose(mp3);
            fclose(pcm);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        NSLog(@"FILEPATH:%@ MP3生成成功",mp3FilePath);
        if (complete) {
            complete(nil);
        }
    }
}

/*
*/

@end
