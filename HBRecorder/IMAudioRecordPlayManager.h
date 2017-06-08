//
//  IMAudioRecordPlayManager.h
//  JLWeChat
//
//  Created by jimneylee on 14-10-26.
//  Copyright (c) 2014年 jimneylee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface IMAudioRecordPlayManager : NSObject

+ (instancetype)sharedManager;

- (void)playWithUrl:(NSString *)url;
- (void)playWithUrl:(NSString *)url duration:(void(^)(CGFloat duration))block;

/**
 *  是否正在播放某一个url
 */
-(BOOL)iscurrentplayurl:(NSString *)filepath;

/**
 *  暂停
 */
-(void)pauseplay:(NSString *)filepath;

/**
 *  继续播放
 */
-(void)resumeplay:(NSString *)filepath;


/**
 *  是否正在播放
 */
-(BOOL)isplaying:(NSString *)filepath;


//- (void)startRecord;
//- (void)stopRecordWithBlock:(void (^)(NSString *urlKey, NSInteger time))block;

@end
