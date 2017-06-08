//
 
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface FDAudioRecordPlayManager : NSObject

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
