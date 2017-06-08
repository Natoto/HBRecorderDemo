//
//  FDAudioNotifyObject.h
//  fenda
//
//  Created by boob on 16/12/22.
//  Copyright © 2016年 YY.COM. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    FDAUDIO_INIT = 1000,
    FDAUDIO_DOWNLOADING = 1,//正在下载
    FDAUDIO_DOWNLOADSUCCESS = 2,//下载成功
    FDAUDIO_PLAYING = 3,
    FDAUDIO_PAUSE = 4,
    FDAUDIO_STOP = 5,
    FDAUDIO_DEALLOC = 6,   //移除播放的view
    FDAUDIO_RESUME = 7,
    FDAUDIO_DOWNLOADINIT = 8,
    FDAUDIO_DOWNLOADCANCEL = -999,
    FDAUDIO_DOWNFAILD = -1,//下载失败
} FDAUDIO_STATE;

//发送通知的时候带的object 是 m_notifyObject

static NSString * notify_audioplayer_stop = @"IMAudioRecordPlayManager_didAudioPlayerStopPlay";
static NSString * notify_audioplayer_pause = @"IMAudioRecordPlayManager_didAudioPlayerPausePlay";
static NSString * notify_audioplayer_startplay = @"IMAudioRecordPlayManager_didAudioPlayerStartPlay";
static NSString * notify_audioplayer_resume = @"IMAudioRecordPlayManager_didAudioPlayerResumePlay";
static NSString * notify_audioplayer_playerror = @"IMAudioRecordPlayManager_didAudioPlayerPlayError";

@interface FDAudioNotifyObject : NSObject
@property (nonatomic, strong) NSNumber * playindex;     //播放的序号是列表中的第几个
@property (nonatomic, strong) NSString * filepath;
@property (nonatomic, strong) NSString * localpath;
@property (nonatomic, strong) NSNumber * progress;
@property (nonatomic, strong) NSNumber * duration;      //剩余多少时间
@property (nonatomic, strong) NSNumber * totalDuration;
@property (nonatomic, strong) NSNumber * playprogress;
@property (nonatomic, strong) NSString * viewuuid;
@property (nonatomic, assign) FDAUDIO_STATE  state;//0 未开始下载 1 正在下载 2 下载成功  3播放 -1 下载失败 4 结束播放
@property (nonatomic, strong) NSIndexPath * indexPath;
@property (nonatomic, weak) id from;//从哪里启动的
@property (nonatomic, weak) id fromvc;
@end

 
