//
//  AudioPlayer.m
//  AudioTalk
//
//  Created by 孙震 on 2022/5/23.
//

#import "AudioPlayer.h"
#import <AVFoundation/AVFoundation.h>



@interface AudioPlayer()

@property (strong,nonatomic) NSURL *url;
@property (strong,nonatomic) AVPlayer *player;
@property (strong,nonatomic) AVPlayerItem *playerItem;
@property (assign,nonatomic) AudioPlayerStatus status;


@end

@implementation AudioPlayer

- (instancetype)initWithUrl:(NSURL *)url {
    if([self init]) {
        self.url = url;
        [self setup];
    }
    return self;
}


- (void)setup {
    if (self.url) {
        self.status = AudioPlayerStatusUnknown;
        self.autoPlay = NO;
        self.playerItem = [[AVPlayerItem alloc] initWithURL:self.url];
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerMovieFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
        
    } else {
        NSLog(@"error:url is nil");
    }
   
}
 
- (void)play {
    if(self.status == AudioPlayerStatusPrepared || self.status == AudioPlayerStatusPause) {
        [self.player play];
        self.status = AudioPlayerStatusPlaying;
        NSLog(@"AudioPlayerStatusPlaying");
    } else if (self.status == AudioPlayerStatusUnknown) {
        self.autoPlay = YES;
    } else {
        NSLog(@"play failed current status:%ld",self.status);
    }
}
   
- (void)pause {
    [self.player pause];
    self.status = AudioPlayerStatusPause;
}

- (void)stop {
    [self.player pause];
    self.status = AudioPlayerStatusStopped;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if([object isKindOfClass:[AVPlayerItem class]]) {
           if([keyPath isEqualToString:@"status"]) {
               switch(_playerItem.status) {
                   case AVPlayerItemStatusReadyToPlay://推荐将视频播放放这里
                       self.status = AudioPlayerStatusPrepared;
                       NSLog(@"prepared");
                       break;
                   case AVPlayerItemStatusUnknown:
                       self.status = AudioPlayerStatusUnknown;
                       NSLog(@"AVPlayerItemStatusUnknown");
                       break;
                   case AVPlayerItemStatusFailed:
                       self.status = AudioPlayerStatusFailed;
                       NSLog(@"AVPlayerItemStatusFailed");
                       break;
                   default:
                       break;
                }
           }
       }
}

- (void)playerMovieFinish:(AVPlayerItem *)item {
    self.status = AudioPlayerStatusStopped;
    NSLog(@"finished");
}
 

- (void)setStatus:(AudioPlayerStatus)status {
    _status = status;
    if ([self.delegate respondsToSelector:@selector(player:statusChanged:)]) {
        [self.delegate player:self statusChanged:self.status];
    }
    if (status == AudioPlayerStatusPrepared) {
        if (self.autoPlay) {
            [self play];
        }
    } 
}
@end
