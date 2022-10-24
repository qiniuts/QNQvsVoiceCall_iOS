//
//  AudioRecorder.m
//  AudioTalk
//
//  Created by 孙震 on 2022/5/23.
//
#import <AVFoundation/AVFoundation.h>
#import "AudioRecorder.h"

@interface AudioRecorder() <AVCaptureFileOutputRecordingDelegate>
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureMovieFileOutput *fileOutput;
@property (nonatomic) dispatch_queue_t sessionQueue;

@end

@implementation AudioRecorder

- (instancetype)init {
    self = [super init];
    if (self) {
        //初始化
        [self setupSession];
    }
    
    return self;
}

- (instancetype)initWithFileUrl:(NSURL *)url{
    self = [self init];
    if (self) {
        self.url = url;
    }
    return self;
}

- (void)setupSession {
    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    
    //初始化captureSession
    self.captureSession = [[AVCaptureSession alloc] init];
    
    //添加input
    AVCaptureDeviceDiscoverySession *discoverSession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInMicrophone] mediaType:AVMediaTypeAudio  position:AVCaptureDevicePositionUnspecified];
    
    NSArray<AVCaptureDevice *> *devices = [discoverSession devices];
    if (!(devices && devices.count > 0) ) {
        NSLog(@"devices is not exist!");
        return;
    }
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:devices.firstObject error:&error];
    if (error) {
        NSLog(@"AVCaptureDeviceInput create failed,%@",error);
        return;
    }
    
    if([self.captureSession canAddInput:deviceInput]) {
        [self.captureSession addInput:deviceInput];
    }else{
        NSLog(@"can not add deviceInput!");
        return;
    }
    
    //添加output
    self.fileOutput = [AVCaptureMovieFileOutput new];
    
    if([self.captureSession canAddOutput:self.fileOutput]) {
        [self.captureSession addOutput:self.fileOutput];
    } else {
        NSLog(@"can not add MovieFileOutput!");
        return;
    }
    
    
}

/// 开始录制
- (void)startRecording {
    if(![self isRecording]){
        if (self.url) {
            if([[NSFileManager defaultManager] fileExistsAtPath:self.url.path]) {
                [[NSFileManager defaultManager] removeItemAtURL:self.url error:nil];
            }
            [self startSession];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), self.sessionQueue, ^{
                [self.fileOutput startRecordingToOutputFileURL:self.url recordingDelegate:self];
            });
           
        } }else {
            NSLog(@"文件路径不存在");
        }
}

/// 停止录制
- (void)stopRecording {
    if([self.captureSession isRunning]) {
        dispatch_async(self.sessionQueue, ^{
            [self.fileOutput stopRecording];
        });
    }
    [self stopSession];
}

/// 开始录制
- (void)startSession {
    if(![self.captureSession isRunning]) {
        dispatch_async(self.sessionQueue, ^{
            [self.captureSession startRunning];
            
        });
    }
}

/// 停止录制
- (void)stopSession {
    if([self.captureSession isRunning]) {
        dispatch_async(self.sessionQueue, ^{
            [self.captureSession stopRunning];
            
        });
    }
}


#pragma mark -AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(nonnull AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(nonnull NSURL *)outputFileURL fromConnections:(nonnull NSArray<AVCaptureConnection *> *)connections error:(nullable NSError *)error {
    NSLog(@"didFinishRecordingToOutputFileAtURL:%@",outputFileURL);
    if ([self.delegate respondsToSelector:@selector(didFinishRecordingToOutputFileAtURL:error:)]) {
        [self.delegate didFinishRecordingToOutputFileAtURL:outputFileURL error:error];
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    NSLog(@"didStartRecordingToOutputFileAtURL:%@",fileURL);
}


- (Boolean)isRecording {
    return self.fileOutput.isRecording;
}

- (double)currentTime {
    return CMTimeGetSeconds(self.fileOutput.recordedDuration);
}


- (void)dealloc {
    [self.captureSession stopRunning];
    NSLog(@"Audio Recorder dealloc");
}

@end
