//
//  ScreenViewController.h
//  CoubTV
//
//  Created by George on 2/5/14.
//  Copyright (c) 2014 George. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

typedef enum {
    CoubTVStateIdle,
    CoubTVStateOnTheWay,
    CoubTVStatePlaying,
    CoubTVStateLoading,
    CoubTVStateAudioLoadingComplete,
    CoubTVStateVideoLoadingComplete,
    CoubTVStateAudioReadyToPlay,
    CoubTVStateVideoReadyToPlay
} CoubTVState;



@interface ScreenViewController : UIViewController <NSURLConnectionDataDelegate, AVAudioPlayerDelegate>
    @property (atomic) CoubTVState state;
    @property (nonatomic) NSTimeInterval loadingTimeStart;
    @property BOOL FullScreen;
@property (nonatomic, strong) AVPlayerLayer *videoPlayerLayer;
//@property (nonatomic, strong) MPMoviePlayerViewController *moviePlayerViewController;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

    @property (nonatomic, strong) NSMutableArray *videoQueue;
    @property (nonatomic) long queuePointer;

    - (void) clearQueue;
    - (void) addCoubsToQueue: (NSArray *) coubs;
    - (BOOL) playNextInQueue;
    - (BOOL) playPreviousInQueue;


    - (void) setupSnow;
    - (void) showSnow;
    - (void) hideSnow;

@end
