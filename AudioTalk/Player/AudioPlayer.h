//
//  AudioPlayer.h
//  AudioTalk
//
//  Created by 孙震 on 2022/5/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef enum : NSUInteger {
    AudioPlayerStatusUnknown,
    AudioPlayerStatusPrepared,
    AudioPlayerStatusPlaying,
    AudioPlayerStatusPause,
    AudioPlayerStatusStopped,
    AudioPlayerStatusFailed
} AudioPlayerStatus;

@class AudioPlayer;

@protocol AudioPlayerDelegate <NSObject>

-(void)player:(AudioPlayer *)player statusChanged:(AudioPlayerStatus)status;

@end

@interface AudioPlayer : NSObject

@property (weak,nonatomic) id<AudioPlayerDelegate> delegate;

@property (assign,nonatomic) Boolean autoPlay;

- (instancetype)initWithUrl:(NSURL *)url;

- (void)play;

- (void)stop;



@end

NS_ASSUME_NONNULL_END
