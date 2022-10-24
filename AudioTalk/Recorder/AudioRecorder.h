//
//  AudioRecorder.h
//  AudioTalk
//
//  Created by 孙震 on 2022/5/23.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMSampleBuffer.h>

@protocol AudioRecorderDelegate <NSObject>

@optional

- (void)didFinishRecordingToOutputFileAtURL:(nonnull NSURL *)url  error:(nullable NSError *)error ;

 
@end

NS_ASSUME_NONNULL_BEGIN

@interface AudioRecorder : NSObject

@property (strong, nonatomic) NSURL *url;

@property (weak, nonatomic) id<AudioRecorderDelegate> delegate;

@property (nonatomic,readonly,getter=isRecording) Boolean recording;

@property(nonatomic, readonly) double currentTime;


/**
 @param url 输出文件的url file://
 */
- (instancetype)initWithFileUrl:(NSURL *)url;

/// 开始采集
- (void)startSession;
/// 停止采集
- (void)stopSession;

/// 开始录制
- (void)startRecording;
/// 停止录制
- (void)stopRecording;





@end

NS_ASSUME_NONNULL_END
