//
//  ScreenViewController.m
//  CoubTV
//
//  Created by George on 2/5/14.
//  Copyright (c) 2014 George. All rights reserved.
//

#import "ScreenViewController.h"
#import "UIImage+animatedGIF.h"
#import "NSMutableArray+Queue.h"



char *stateNames[] = {"IDLE", "ONTHEWAY", "PLAYING", "LOADING",
                        "AUDIO_LOADING_COMPLETE", "VIDEO_LOADING_COMPLETE",
                          "AUDIO_READY_TO_PLAY", "VIDEO_READY_TO_PLAY"};

@interface ScreenViewController ()
    @property (nonatomic, strong) AVAudioPlayer *snowSound;
    @property (nonatomic, strong) UIImageView *snow;

    
    @property (nonatomic, strong) NSMutableDictionary *properties;

    

    // cache props
    @property long long bytesReceivedOfVideo;
    @property long long expectedBytesOfVideo;
    @property float progressOfVideoDownloading;
    @property (nonatomic, strong) NSMutableData* receivedDataOfVideo;

    @property BOOL noSound;

    @property NSURLConnection *currentConnection;



@end

@implementation ScreenViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.properties = [[NSMutableDictionary alloc] init];
        self.queuePointer = 0;
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    
    // CONTROLS NOTIFICATIONS
    // fullscreen/tvscreen
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goFullScreen:) name:@"goFullScreen" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goTvScreen:) name:@"goTvScreen" object:nil];
    // replay
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(replayCurrent:) name:@"replayCurrent" object:nil];
    
}

- (void) setupSnow
{
    NSURL *gifSnow = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tvsnow2" ofType:@"gif"]];
    NSURL *snowSound = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tvstatic2" ofType:@"wav"]];
   
    
    self.snow = [[UIImageView alloc] initWithImage:[UIImage animatedImageWithAnimatedGIFURL:gifSnow]];
    self.snow.frame = CGRectMake(115, 115+30-40, 610, 480);
    [self.view addSubview:self.snow];
    
    //AVAsset *composition = [self makeAssetCompositionWithUrl:snowSound];
    // *playerItem = [AVPlayerItem playerItemWithURL:snowSound];

    self.snowSound = [[AVAudioPlayer alloc] initWithContentsOfURL:snowSound error:nil];
    self.snowSound.numberOfLoops = -1;
    [self.snowSound setVolume:.1];
    
    [self showSnow];
}

-(void) showSnow
{
    self.snow.alpha = 1.0;
   
    [self.snowSound play];
    // stop players
    if(self.videoPlayerLayer)
        [self.videoPlayerLayer.player pause];
    if(self.audioPlayer)
        [self.audioPlayer stop];
    
    @try{
        [self.videoPlayerLayer.player removeObserver:self forKeyPath:@"status"];
    }@catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
    
}

- (void) hideSnow
{
    self.snow.alpha = 0.0;
    [self.snowSound pause];
}

- (void) goFullScreen: (NSNotification *) notification
{
    if(!self.FullScreen){
        if(self.videoPlayerLayer)
            [self.videoPlayerLayer setFrame:CGRectMake(0, 0, 1024, 768)];
        
        if(self.snow)
            [self.snow setFrame:CGRectMake(0, 0, 1024, 768)];
        
        
        self.FullScreen = YES;
        NSLog(@"SET FLSCR TRUE %i", self.FullScreen);
    }
}

- (void) goTvScreen: (NSNotification *) notification
{
    if(self.FullScreen){
        
        if(self.videoPlayerLayer)
            [self.videoPlayerLayer setFrame:CGRectMake(115, 115+30-40, 610, 480)];
        if(self.snow)
            [self.snow setFrame:CGRectMake(115, 115+30-40, 610, 480)];
        
        self.FullScreen = NO;        
    }
}

- (void) replayCurrent: (NSNotificationCenter *) notification
{
    // reset video and audio
    [self.videoPlayerLayer.player seekToTime:kCMTimeZero];
    [self.audioPlayer setCurrentTime:0.0];
    
    [self.videoPlayerLayer.player play];
}


- (void) clearQueue
{
    self.videoQueue = [[NSMutableArray alloc] init];
    self.queuePointer = 0;
}

- (void) addCoubsToQueue: (NSArray *) coubs
{
    NSLog(@"ADD TO QUEUE");
    
    if(!self.videoQueue)
        self.videoQueue = [coubs mutableCopy];
    else
        [self.videoQueue addObjectsFromArray: coubs];
    
}

- (BOOL) playPreviousInQueue
{
    if(self.queuePointer > 1){
        self.queuePointer-=2;
        [self playNextInQueue];
        return YES;
    }
    return NO;
}

- (BOOL) playNextInQueue
{
    [self setState:CoubTVStateLoading];
    
    if(self.videoQueue.count > self.queuePointer){
        
        NSDictionary *coub = self.videoQueue[self.queuePointer];
        
        self.queuePointer++;
        
        //NSLog(@"%@", coub);
        
       
        
        
       // NSURL *videoUrl = [NSURL URLWithString:[coub objectForKey:@"gifv"]];
        
       // NSLog(@"video url str: %@", videoUrl);
        
       // NSURL *audioUrl;
        
        
        NSDictionary *integrations = [[coub objectForKey:@"file_versions"] objectForKey:@"integrations"];
        NSString *videoUrlStr = [integrations objectForKey:@"ifunny_video"];
        NSLog(@"video url str: %@", videoUrlStr);
        
        NSURL *videoUrl = [NSURL URLWithString:videoUrlStr];

        
        /*if(audioUrlStr != (id)[NSNull null]){
            audioUrl = [NSURL URLWithString:[mobile objectForKey:@"looped_audio"]];
            self.noSound = NO;
        }else{
            self.noSound = YES;
        }*/
        
        self.noSound = YES;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"videoLoadingComplete" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"audioLoadingComplete" object:nil];
       
        
        // cache video
        self.receivedDataOfVideo = [[NSMutableData alloc] initWithLength:0];
        self.bytesReceivedOfVideo = self.expectedBytesOfVideo = 0;
        
        NSURLRequest *videoDownloadRequest = [[NSURLRequest alloc] initWithURL:videoUrl cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval: 20];
        NSURLConnection *videoDownloadConnection =  [[NSURLConnection alloc] initWithRequest:videoDownloadRequest delegate:self startImmediately:YES];
        self.currentConnection = videoDownloadConnection;
        [videoDownloadConnection start];
        
        
        /*if(!self.noSound){
            // cache audio
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(audioLoadingComplete:)
                                                         name:@"audioLoadingComplete" object:nil];
            [self performSelectorInBackground:@selector(preloadAudioWithUrl:) withObject: audioUrl];
        }else{*/
            self.state = CoubTVStateAudioLoadingComplete;
        /*}*/
        
        return YES;
    }
    
    return NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
   
    if(![connection isEqual:self.currentConnection]){
        //NSLog(@"STRANGER CONNECTION");
        return;
    }
    
    [self.receivedDataOfVideo appendData:data];
    
    NSInteger receivedLen = [data length];
    self.bytesReceivedOfVideo = (self.bytesReceivedOfVideo + receivedLen);
    
    if(self.expectedBytesOfVideo != NSURLResponseUnknownLength) {
        self.progressOfVideoDownloading = ((self.bytesReceivedOfVideo/(float)self.expectedBytesOfVideo)*100)/100;
        self.progressOfVideoDownloading *= 100;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"videoDownloadPercentageChange"
                                               object:[NSString stringWithFormat:@"%f",self.progressOfVideoDownloading]];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"VIDEO DOWNLOAD ERROR: %@. Starting NEXT", error.localizedDescription);
    [self setState:CoubTVStateLoading];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"next" object:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if(![connection isEqual:self.currentConnection]){
        //NSLog(@"STRANGER CONNECTION");
        return;
    }
    self.expectedBytesOfVideo = [response expectedContentLength];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if(![connection isEqual:self.currentConnection]){
        //NSLog(@"STRANGER CONNECTION");
        return;
    }
    
    NSData *videoData = self.receivedDataOfVideo;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [paths[0] stringByAppendingPathComponent:@"cachedVideo.mp4"];
    
    /*NSString *path = [NSString stringWithFormat:@"%@/%@",
                      [[NSBundle mainBundle] resourcePath],
                      @"cachedVideo.mp4"];*/
    
    [videoData writeToFile:path atomically:NO];
    NSLog(@"caching video complete to %@", path);
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    NSLog(@"FILE EXISTS: %@", fileExists?@"YES":@"NO");
    
    NSURL *url = [NSURL fileURLWithPath:path];
    
    [self.properties setObject:url forKey:@"videoLocalURL"];
    
    if(self.state == CoubTVStateAudioLoadingComplete){
        [self setState:CoubTVStateOnTheWay];
        
        NSURL *audioURL = (NSURL *)[self.properties objectForKey:@"audioLocalURL"];
        [self playVideo: url withAudio:audioURL];
        
    }else{
        [self setState:CoubTVStateVideoLoadingComplete];
    }
}





// runs in background
    - (void) preloadAudioWithUrl: (NSURL *) url
    {
        NSData *audioData = [NSData dataWithContentsOfURL: url];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"audioLoadingComplete" object:audioData];
    }

- (void) audioLoadingComplete: (NSNotification *) notification
{
    NSData *audioData = notification.object;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [paths[0] stringByAppendingPathComponent:@"cachedAudio.mp3"];
    
    [audioData writeToFile:path atomically:NO];
    NSLog(@"caching audio complete to %@", path);
    NSURL *url = [NSURL fileURLWithPath:path];
    
    [self.properties setObject:url forKey:@"audioLocalURL"];
    
    if(self.state == CoubTVStateVideoLoadingComplete){
        [self setState:CoubTVStateOnTheWay];
        NSURL *videoURL = (NSURL *)[self.properties objectForKey:@"videoLocalURL"];
        [self playVideo: videoURL withAudio:url];
    }else{
        [self setState:CoubTVStateAudioLoadingComplete];
    }
}

- (void) playVideo: (NSURL *) videoURL withAudio: (NSURL *) audioURL
{
    
    
    NSLog(@"Setting up players");
    
    // AUDIO
    if(!self.noSound){
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:nil];
        self.audioPlayer.numberOfLoops = -1;
    }
    
    // VIDEO
    
    // remove old layer if exists
    if(self.videoPlayerLayer != nil){        
       [self.videoPlayerLayer removeFromSuperlayer];
    }
    AVAsset *composition = [self makeAssetCompositionWithUrl:videoURL];
    
    // create an AVPlayer with your composition
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:composition];
    //AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:videoURL];
    AVPlayer* mp = [AVPlayer playerWithPlayerItem:playerItem];
    mp.muted = audioURL?YES:NO;
    //mp.muted = NO;
    
    
    // Add the player to your UserInterface
    // Create a PlayerLayer:
    self.videoPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:mp];
    self.videoPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    if(self.FullScreen)
        self.videoPlayerLayer.frame = CGRectMake(0, 0, 1024, 768);
    else
        self.videoPlayerLayer.frame = CGRectMake(115, 115+30-40, 610, 480);
   
    
    [[self view].layer insertSublayer:self.videoPlayerLayer atIndex:0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
    
    [self.videoPlayerLayer.player addObserver:self
                           forKeyPath:@"status"
                           options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
                           context:nil];
}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (object == self.videoPlayerLayer.player && [keyPath isEqualToString:@"status"]) {
        if (self.videoPlayerLayer.player.status == AVPlayerStatusReadyToPlay) {
            [self hideSnow];
            NSLog(@"Video is ready to play");
            
            [self.videoPlayerLayer.player play];
        
            if(!self.noSound)
                [self.audioPlayer play];
        
            [self setState:CoubTVStatePlaying];
           
            
        } else if (self.videoPlayerLayer.player.status == AVPlayerStatusFailed) {
           
        }
    }
}

- (AVAsset*) makeAssetCompositionWithUrl:(NSURL *) url {
    
    int numOfCopies = 550;
    
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];
    AVURLAsset* sourceAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    // calculate time
    CMTimeRange editRange = CMTimeRangeMake(CMTimeMake(0, 600), CMTimeMake(sourceAsset.duration.value, sourceAsset.duration.timescale));
    
    NSError *editError;
    
    // and add into your composition
    BOOL result = [composition insertTimeRange:editRange ofAsset:sourceAsset atTime:composition.duration error:&editError];
    
    if (result) {
        for (int i = 0; i < numOfCopies; i++) {
            [composition insertTimeRange:editRange ofAsset:sourceAsset atTime:composition.duration error:&editError];
        }
    }
    
    return composition;
}


-(void)videoDidFinishPlaying:(NSNotification *) notification {
    NSLog(@"video finished");
    [self showSnow];
    self.queuePointer--;
    [self playNextInQueue];
}


- (void) setState:(CoubTVState)state{
    NSLog(@"State changed to %s", stateNames[state]);
    if(state == CoubTVStatePlaying){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"newVideoStarted" object:nil];
    }else{
        
         [[NSNotificationCenter defaultCenter] postNotificationName:@"newVideoLoading" object:nil];
        
        self.loadingTimeStart = [[NSDate date] timeIntervalSince1970];
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 3);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            
            if([[NSDate date] timeIntervalSince1970]-self.loadingTimeStart > 3
                    && (self.state == CoubTVStateIdle)){
                NSLog(@"Waiting too long in IDLE. Trying reloading current coub.");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadCoub" object:self];
            }
            
        });
        
    }
    _state = state;
}

- (CoubTVState) getState
{
    return _state;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
