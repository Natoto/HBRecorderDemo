//
//  FDAudioPlayerManager.h
//  JLWeChat
//
//  Created by jimneylee on 14-10-26.
//  Copyright (c) 2014年 jimneylee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FDAudioNotifyObject.h"

@interface FDAudioPlayerManager : NSObject

+ (instancetype)sharedManager;

//播放列表
@property (nonatomic, strong) NSMutableArray * playlist;

@property (nonatomic, assign,readonly) FDAUDIO_STATE playerState;

@property (nonatomic, assign) NSInteger valiateCode;

@property (nonatomic, assign) BOOL  autonext;
//下载进度
/**
 *      NSDictionary * dic = @{@"filepath":FDAudioNotifyObject,
 */
@property (nonatomic, strong,readonly) FDAudioNotifyObject * m_notifyObject;

/**
 * 设置了playlist的情况下推荐使用
 */
- (void)playWithIndex:(NSInteger)index;
/**
 * 在没有设置playlist的情况下使用
 */
- (void)playWithUrl:(NSString *)url;
- (void)playWithUrl:(NSString *)url duration:(void(^)(NSTimeInterval duration))block;
//从哪里开始启动的 from 一般填 self
- (void)playWithUrl:(NSString *)url duration:(void(^)(NSTimeInterval duration))block from:(id)from;

-(void)updatePlayProgress;

/**
 * 停止播放
 */
-(void)stopPlay;

/**
 *  是否正在播放某一个url
 */
-(BOOL)iscurrentplayurl:(NSString *)filepath;

/**
 *  暂停
 */
-(void)pauseplay;

/**
 *  继续播放
 */
-(void)resumeplay;

-(void)playorpause;

/**
 *  是否正在播放
 */
-(BOOL)isplaying:(NSString *)filepath;
/**
 * 播放的控件被移除了
 */
-(void)removeSuperView:(NSString *)filepath;

//当前播放的时间
-(NSTimeInterval)currentPlayTime;
//当前播放音频长度
-(NSTimeInterval)totalDuration;

-(CGFloat)currentPlayProgress;

/**
 *  下一首
 */
-(void)nextAudio;
/**
 *  上一首
 */
-(void)lastAudio;

-(void)cancelDownloading;

@end
