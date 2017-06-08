
static NSString *const AudioRecorderPath=@"audioPath";          ///<文件路径 string
static NSString *const AudioRecorderName=@"audioName";          ///<文件名称 string
static NSString *const AudioRecorderDuration=@"audioDuration";  ///<音频时长 string

typedef enum : NSUInteger {
    RECORD_NONE = 0,        //无操作
    RECORD_INIT,        //初始化
    RECORD_RECORDING,   //录音中
    RECORD_PAUSE,       //录音暂停
    RECORD_STOP,        //录音停止
    RECORD_FAILED,      //录音失败
    RECORD_FINISH,      //录音完成
    RECORD_PLAYING,
    RECORD_PLAYFINISH,
} RECORD_STATE;

typedef enum : NSUInteger {
    RECORD_MODE_RECORD_PAUSE,//录制模式，录制，可以暂停，继续录制
    RECORD_MODE_RECORD_PLAY,//录制模式，录一次，点击暂停，然后播放 重新录制
} RECORD_MODE;

#import <UIKit/UIKit.h>
@class FDRecorderButton;
@protocol FDRecorderButtonDelegate <NSObject>
/**
 *  录音结束后的代理方法
 *
 *  @param audioRecorder 所在类
 *  @param audioInfo     录音文件信息
 *  @param flag          YES发送录音文件，NO不发送录音文件
 */
- (void)FDRecorderButton:(FDRecorderButton *)audioRecorder didFinishRcordWithAudioInfo:(NSDictionary *)audioInfo sendFlag:(BOOL)flag;

- (void)FDRecorderButton:(FDRecorderButton *)audioRecorder recordProgress:(CGFloat)progress;

-(RECORD_MODE)FDRecorderButtonRecordMode:(FDRecorderButton *)audioRecorder;

- (void)FDRecorderButton:(FDRecorderButton *)audioRecorder recordStateChanged:(RECORD_STATE)recordstate;

//- (BOOL)FDRecorderButton:(FDRecorderButton *)audioRecorder recordStateWillChanged:(RECORD_STATE)recordstate;

@end

/**
 * 录音按钮，只提供点击开始，点击结束功能，长按需要自定义
 */
@interface FDRecorderButton : UIButton

@property(assign,nonatomic) CGFloat  RemainTimeDuration;
@property(assign,nonatomic) CGFloat  RecordTimeDuration; //录音时长
@property(assign,nonatomic) NSInteger recorderDuration; //录音最大时长

@property (nonatomic, assign,readonly) RECORD_MODE  recordmode;
@property (nonatomic, assign,readonly) RECORD_STATE recordstate;

@property(weak,nonatomic) id<FDRecorderButtonDelegate> delegate;

/**
 *  录制完成是否自动提交
 */
@property (nonatomic, assign) BOOL autosubmit;
/**
 *  发送语音
 */
-(void)sendAudio;

/**
 *  开始录制音频
 */
-(void)startRecord;
/**
 *  停止录制
 */
-(void)stopRecord;

/**
 *  重新录制
 */
-(void)reRecord;

/**
 *  开始录音时，切换显示图片
 *
 *  @param image UIControlNormal状态下的图片
 */
- (void)setChangeImage:(UIImage *)image;
/**
 *  开始录音时，切换显示标题
 *
 *  @param title UIControlNormal状态下的标题
 */
- (void)setChangeTitle:(NSString *)title;
/**
 *  开始录音时，切换显示背景图片
 *
 *  @param backgroundImage UIControlNormal状态下的背景图片
 */
- (void)setChangeBackgroundImage:(UIImage *)backgroundImage;
/**
 *  开始录音时，上滑切换显示图片
 *
 *  @param image UIControlNormal状态下的图片
 */
- (void)setUpChangeImage:(UIImage *)image;
/**
 *  开始录音时，上滑切换显示标题
 *
 *  @param title UIControlNormal状态下的标题
 */
- (void)setUpChangeTitle:(NSString *)title;
/**
 *  开始录音时，上滑切换显示背景图片
 *
 *  @param backgroundImage UIControlNormal状态下的背景图片
 */
- (void)setUpChangeBackgroundImage:(UIImage *)backgroundImage;

@end
