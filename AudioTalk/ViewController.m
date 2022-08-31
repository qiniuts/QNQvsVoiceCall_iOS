//
//  ViewController.m
//  AudioTalk
//
//  Created by 孙震 on 2022/5/23.
//

#import "ViewController.h"
#import "AudioRecorder.h"
#import "AudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "G711/g711_table.h"
#import "AuthUtil.h"

#error 这里替换参数
#define QiNiuToken   @"Qiniu JAwTPb8dmrbiwt89Eaxa4VsL4_xSIYJoJh4rQfOQ:Fv7qD3sLPOxIH3xtIAup0_Y2DuA="
#define nameSpaceId  @"空间ID"
#define deviceId     @"设备国标ID"


@interface ViewController ()<AudioRecorderDelegate,AudioPlayerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *recorderBtn;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (weak, nonatomic) IBOutlet UILabel *timeRecordingLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (assign, nonatomic) NSInteger duration;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) Boolean isPlaying;
@property (strong, nonatomic) AudioRecorder *recorder;
@property (strong, nonatomic) AudioPlayer *player;
@property (strong, nonatomic) NSString *path;
@property (strong ,nonatomic) NSString *talkUrl; //通话的url

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)setup {
    self.path = [NSTemporaryDirectory() stringByAppendingString:@"recording.m4a"];
    self.recorder = [[AudioRecorder alloc] initWithFileUrl:[NSURL fileURLWithPath:self.path]];
    self.recorder.delegate = self;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated]; 
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
#pragma mark -- timer

- (void)setupTimer {
    self.duration = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(count) userInfo:nil repeats:YES];
}

- (void)destoryTimer {
    [self.timer invalidate];
    self.timer = nil;
}
- (void)count {
    self.duration = self.recorder.currentTime;
    NSInteger hour = (self.duration ) /3600;
    NSInteger minute = ((self.duration )  % 3600) / 60;
    NSInteger second = (self.duration ) % 60;
    self.timeRecordingLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",hour,minute,second];
}

#pragma mark -- btn click
- (IBAction)recordButtonClicked:(UIButton *)sender {
    if (self.recorder.isRecording) {
        //停止录制
        [self.recorder stopRecording];
        [self destoryTimer];
        [self.recorderBtn setTitle:@"开始录制" forState:UIControlStateNormal];
        self.playButton.enabled = YES;
        self.sendBtn.enabled = YES;
        [self setStatus:@"录制完成"];
    } else {
        //开始录制
        [self.recorder startRecording];
        [self setupTimer];
        [self.recorderBtn setTitle:@"停止录制" forState:UIControlStateNormal];
        self.playButton.enabled = NO;
        self.sendBtn.enabled = NO;
        [self setStatus:@"正在录制"];
    }
}


- (IBAction)playButtonClicked:(UIButton *)sender {
    if (self.isPlaying) {
        //停止播放
        [self.player stop];
    } else {
        //开始播放recording.m4a
        self.player = [[AudioPlayer alloc] initWithUrl:[NSURL fileURLWithPath:self.path]];
        self.player.delegate = self;
        [self.player setAutoPlay:YES];
    }
}


#pragma mark - AudioRecorderDelegate

- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)url error:(NSError *)error {
    if (error) {
        NSLog(@"record failed with error: %@",error);
    } else {
        NSLog(@"record success with url: %@",url);
    }
}

#pragma mark - AudioPlayerDelegate

-(void)player:(AudioPlayer *)player statusChanged:(AudioPlayerStatus)status {
    if (status == AudioPlayerStatusStopped) {
        self.isPlaying = NO; 
        [self.playButton setTitle:@"开始播放" forState:UIControlStateNormal];
        self.recorderBtn.enabled = YES;
        self.sendBtn.enabled = YES;
    } else if (status == AudioPlayerStatusPrepared) {
        self.isPlaying = YES;
        self.recorderBtn.enabled = NO;
        self.sendBtn.enabled = NO;
        [self.playButton setTitle:@"停止播放" forState:UIControlStateNormal];
    }
}

- (IBAction)sendG711:(UIButton *)sender {
    
    self.sendBtn.enabled = NO;
    self.recorderBtn.enabled = NO;
    self.playButton.enabled = NO;
    
    //1.获取PCM数据
    NSData *pcm = [self extractPCM: [NSURL fileURLWithPath:self.path]];
    
    if(!pcm.length) {
        [self setStatus:@"目前没有音频数据,请先录制"];
        self.sendBtn.enabled = YES;
        self.recorderBtn.enabled = YES;
        self.playButton.enabled = YES;
        return;
    }
    
    //2.生成g711a数据
    NSData *g711 = [self Pcm2G711a:pcm];
    
    if (!g711.length) {
        self.sendBtn.enabled = YES;
        self.recorderBtn.enabled = YES;
        self.playButton.enabled = YES;
        [self setStatus:@"目前没有音频数据,请先录制"];
        return;
    }
    
    //3.请求talk 地址
    [self getTalkUrl:^(NSString *url) {
        if(!url) {
            //1.没有获取到地址
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setStatus:@"get post url  error"];
                self.sendBtn.enabled = YES;
                self.recorderBtn.enabled = YES;
                self.playButton.enabled = YES;
            });
            return;
        }
        //2.成功获取地址 发送数据
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setStatus:@"正在发送语音"];
        });
        [self postData:g711 url:url complete:^(int code) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (code  == 0) {
                    [self setStatus:@"成功发送语音"];
                } else if(code == 6002) {
                    self.talkUrl = nil;
                    [self setStatus:@"talk地址已经失效，请重新获取!"];
                } else {
                    self.talkUrl = nil;
                    [self setStatus:@"其他错误"];
                }
                self.sendBtn.enabled = YES;
                self.recorderBtn.enabled = YES;
                self.playButton.enabled = YES;
            });
        }];
    }];
}


#pragma mark - readPCM
//获取pcm数据
- (NSData *)extractPCM:(NSURL *)url {
    AVAsset *asset = [AVAsset assetWithURL:url];
    if (asset == nil) {
        NSLog(@"asset is not defined!");
        return nil;
    }
    NSLog(@"asset duration:%f",CMTimeGetSeconds(asset.duration));
    
    NSError *error;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    if (error) {
        NSLog(@"AVAssetReader init error:%@",error);
        return nil;
    }
    // 注意 需要转成采样率8K的 16bit
    // g711a采样率是8k 8bit
    NSDictionary *outputSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                   [NSNumber numberWithFloat:8000], AVSampleRateKey,
                                   [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                   [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                   [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                   [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                                   [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                   nil];;
    
    
    AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc] initWithTrack:[asset tracksWithMediaType:AVMediaTypeAudio].firstObject outputSettings:outputSetting];
    
    // 添加输出
    if([assetReader canAddOutput:output]) {
        [assetReader addOutput:output];
    } else {
        NSLog(@"add output failed!");
        return nil;
    }
    
    if(![assetReader startReading]) {
        NSLog(@"reading failed!");
    }
    
    NSMutableData *data = [[NSMutableData alloc]init];
    while (assetReader.status ==  AVAssetReaderStatusReading) {
        CMSampleBufferRef  sampleBuffer = [output copyNextSampleBuffer]; //读取到数据
        if (sampleBuffer) {
            CMBlockBufferRef blockBUfferRef = CMSampleBufferGetDataBuffer(sampleBuffer);//取出数据
            size_t length = CMBlockBufferGetDataLength(blockBUfferRef);   //返回一个大小，size_t针对不同的品台有不同的实现，扩展性更好
            SInt16 sampleBytes[length];
            CMBlockBufferCopyDataBytes(blockBUfferRef, 0, length, sampleBytes); //将数据放入数组
            [data appendBytes:sampleBytes length:length];                 //将数据附加到data中
            CMSampleBufferInvalidate(sampleBuffer);  //销毁
            CFRelease(sampleBuffer);                 //释放
        }
    }
    
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"recording.pcm"];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    [data writeToFile:path atomically:NO];
    NSLog(@"reading pcm complete");
    return data;
}
#pragma mark - PCM2G711A
// pcm转成g711a
// pcm 的采样率 8k  16bit
// g711a 采样率 8k  8bit
- (NSData *)Pcm2G711a:(NSData *)pcmData {
    [self setStatus:@"convert g711  start"];
    char *pcmCdata = (char *)[pcmData bytes];
    char *g711data = malloc(pcmData.length/2);
    pcm16_alaw_tableinit();
    pcm16_to_alaw((int)pcmData.length, pcmCdata, g711data);
    
    NSData *data = [NSData dataWithBytes:g711data length:pcmData.length/2];
    NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"recording.g711"];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    [data writeToFile:path atomically:YES];
    
    [self setStatus:@"convert g711  end"];
    
    return data;
}

#pragma mark - sendData


- (void)getTalkUrl:(void(^)(NSString *url))result {
    /**
     api文档:https://developer.qiniu.com/qvs/8158/voice-call
     token鉴权文档：https://developer.qiniu.com/qvs/6713/authentication
     */
    //如果当前有值 则不需要请求 1分钟内不发送数据才失效
    if(self.talkUrl){
        result(self.talkUrl);
        return;
    }
    
    [self setStatus:@"get post url  start"];
    NSString *urlStr = [NSString stringWithFormat:@"http://qvs.qiniuapi.com/v1/namespaces/%@/devices/%@/talk",nameSpaceId,deviceId];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:QiNiuToken forHTTPHeaderField:@"Authorization"];
    NSData *body = [@"{\"isV2\":true}" dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:body];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed  error:nil];
        NSLog(@"%@",resp);
        NSString *httpUrl = resp[@"audioSendAddrForHttp"];
        result(httpUrl);
    }];
    
    [task resume];
}

//发送数据
-(void)postData:(NSData *)data url:(NSString *)url complete:(void(^)(int code))result {
    self.talkUrl = url;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    //data to base64
    NSString *dataStr = [AuthUtil data2SBase64:data];
    NSLog(@"datastr:%lu",(unsigned long)dataStr.length);
    NSDictionary *param = [NSDictionary dictionaryWithObject:dataStr forKey:@"base64_pcm"];
    NSData *json = [NSJSONSerialization dataWithJSONObject:param options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:json];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed  error:nil];
        result([resp[@"code"] intValue]);
    }];
    
    [task resume];
}

- (void)setStatus:(NSString *)string {
    self.statusLabel.text = string;
    NSLog(@"%@",string);
}

@end
