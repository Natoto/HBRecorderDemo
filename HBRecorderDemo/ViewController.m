//
//  ViewController.m
//  HBRecorderDemo
//
//  Created by boob on 2017/6/8.
//  Copyright © 2017年 YY.COM. All rights reserved.
//

#import "ViewController.h"
#import "FDRecorderButton.h"

@interface ViewController ()<FDRecorderButtonDelegate>
@property (weak, nonatomic) IBOutlet FDRecorderButton *btn_record;
@property (weak, nonatomic) IBOutlet UILabel *lbl_time;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initrecord];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)recordaginbtn:(id)sender {
 
    [self.btn_record reRecord];
 
}

-(void)initrecord{
    
    UIImage * changimg = [UIImage imageNamed:@"ic_answer_play"] ;
    UIImage * recodeimg = [UIImage imageNamed:@"ic_answer_record"] ;
    UIImage * selectedimg = [UIImage imageNamed:@"ic_answer_stop"];
    [self.btn_record setChangeImage:changimg];
    [self.btn_record setImage:selectedimg forState:UIControlStateSelected];
    [self.btn_record setImage:selectedimg forState:UIControlStateHighlighted];
    [self.btn_record setImage:recodeimg forState:UIControlStateNormal];
    self.btn_record.delegate = self;
    
    self.lbl_time.hidden = YES;
    
}

-(void)FDRecorderButton:(FDRecorderButton *)audioRecorder recordProgress:(CGFloat)progress{
    NSLog(@"recordtime: %.3f",audioRecorder.recorderDuration * progress);
    if (progress > 0) {
        self.lbl_time.text = [NSString stringWithFormat:@"%.0f\"",progress * audioRecorder.recorderDuration];
    }
}

-(RECORD_MODE)FDRecorderButtonRecordMode:(FDRecorderButton *)audioRecorder{
    return RECORD_MODE_RECORD_PLAY;
}

-(void)FDRecorderButton:(FDRecorderButton *)audioRecorder didFinishRcordWithAudioInfo:(NSDictionary *)audioInfo sendFlag:(BOOL)flag{
    
    NSLog(@"\n文件名称:%@\n音频时长:%@\n文件路径:%@",audioInfo[AudioRecorderName],audioInfo[AudioRecorderDuration],audioInfo[AudioRecorderPath]);
          [self.btn_record stopRecord];
    [self initrecord];
    
    
}

-(void)FDRecorderButton:(FDRecorderButton *)audioRecorder recordStateChanged:(RECORD_STATE)recordstate{
    if (recordstate == RECORD_RECORDING || recordstate == RECORD_PLAYING) {
        self.lbl_time.hidden = NO;
    }
    else{
        self.lbl_time.hidden = YES;
    }
}

- (IBAction)reRecordBtnTap:(id)sender {
    [self.btn_record reRecord];
}

@end
