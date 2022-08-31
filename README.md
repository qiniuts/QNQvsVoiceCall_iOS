
# 一、demo运行说明

### 替换项目中宏定义

```
#define QiNiuToken   @"从后台获取toekn"
#define nameSpaceId  @"空间ID"
#define deviceId     @"设备国标ID"
```



#	二、主要代码


## 录制音频文件

```
  self.path = [NSTemporaryDirectory() stringByAppendingString:@"recording.m4a"];
  self.recorder = [[AudioRecorder alloc] initWithFileUrl:[NSURL fileURLWithPath:self.path]];
  //开始录制
  [self.recorder startRecording];
```
 ## 提取PCM


```
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
```


 

## PCM 转成 G711a


```
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

```

