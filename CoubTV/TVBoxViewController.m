//
//  TVBoxViewController.m
//  CoubTV
//
//  Created by George on 2/5/14.
//  Copyright (c) 2014 George. All rights reserved.
//

#import "TVBoxViewController.h"

#import "MainViewController.h"




@interface TVBoxViewController ()
    @property (nonatomic, strong) MainViewController *mvc;
@end

@implementation TVBoxViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        
        
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(videoDownloadPercentageChange:)
                                                     name:@"videoDownloadPercentageChange" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(newVideoStarted:)
                                                     name:@"newVideoStarted" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(newVideoLoading:)
                                                     name:@"newVideoLoading" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(shareTo:)
                                                     name:@"shareTo" object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.clickSound = [[AVAudioPlayer alloc] initWithContentsOfURL:
                       [NSURL URLWithString:
                        [[NSBundle mainBundle]
                         pathForResource:@"click" ofType:@"mp3"]] error:nil];
    [self.clickSound setVolume:.2];
    
    self.mvc = (MainViewController *)self.parentViewController;
    BOOL channels_and_search_unlocked = [[self.mvc getIcloudUserDataForKey:@"channels_and_search_unlocked"] boolValue]
                                            || [[self.mvc getLocalUserDataForKey:@"channels_and_search_unlocked"] boolValue];
    channels_and_search_unlocked = YES;
    
    // EFFECTS
#pragma mark Effects
    {
    // Pixel grid
    self.pixelGrid = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pixels.png"]];
    [self.pixelGrid setFrame:CGRectMake(115, 115+30-40, 610, 480)];
    [self.view addSubview:self.pixelGrid];
    
    // Tv Box
    self.oldTvImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"oldtv2.png"]];
    self.oldTvImage.frame = CGRectMake(50, 80-40, 924, 668);
    self.oldTvImage.userInteractionEnabled = NO;
    [self.view addSubview:self.oldTvImage];
    
    // Particles
    self.emitterLayer = [CAEmitterLayer layer]; // 1
    self.emitterLayer.emitterPosition = CGPointMake(self.view.bounds.size.width*1.25, self.view.bounds.size.height*0.5); // 2
    self.emitterLayer.emitterZPosition = 5; // 3
    self.emitterLayer.emitterSize = CGSizeMake(self.view.bounds.size.width, 0); // 4
    self.emitterLayer.emitterShape = kCAEmitterLayerSphere; // 5
    
    CAEmitterCell *emitterCell = [CAEmitterCell emitterCell]; // 6
    emitterCell.scale = 0.008; // 7
    emitterCell.scaleRange = 0.1; // 8
    emitterCell.emissionRange = (CGFloat)M_PI_2; // 9
    emitterCell.lifetime = 20.0; // 10
    emitterCell.birthRate = 10; // 11
    emitterCell.velocity = 10; // 12
    emitterCell.velocityRange = 50; // 13
    emitterCell.yAcceleration = -.5; // 14

    
    emitterCell.contents = (id)[[UIImage imageNamed:@"particle.png"] CGImage]; // 15
    self.emitterLayer.emitterCells = [NSArray arrayWithObject:emitterCell]; // 16
    [self.view.layer addSublayer:self.emitterLayer]; // 17
    
    
    // Screen glow
    self.glowView = [[UIView alloc] init];
    [self.view addSubview:self.glowView];
    [self makeViewShine:self.glowView];
    }
    
    // Bottom progressBar
    self.bottomProgressBar = [[UIView alloc] initWithFrame:CGRectMake(0, 763, 0, 5)];
    self.bottomProgressBar.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:.2];
    [self.view addSubview:self.bottomProgressBar];
    [self makeViewGlow:self.bottomProgressBar];
    
    
    // CONTROLS
    // panel (switch next)
    UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnControls:)];
    
    self.controlsView = [[UIView alloc] initWithFrame:CGRectMake(790, 390-40, 150, 250)];
    [self.view addSubview:self.controlsView];
    [self.controlsView addGestureRecognizer:tapRec];
    
    
    // control view over screen
    self.screenControls = [[UIView alloc] initWithFrame:CGRectMake(115, 115+30-40, 610, 480)];
    [self.view addSubview:self.screenControls];
    
    
    // VIDEO SCREEN INFO
    self.videoScreenInfo = [[UIView alloc] init];
    [self.screenControls addSubview:self.videoScreenInfo];
    
    // SCREEN CONTROLS
#pragma mark Screen buttons
    {
        
        self.screenButtons = [[UIView alloc] initWithFrame:CGRectMake(630, 130, 70, 230)];
        //[self.screenButtons setBackgroundColor:[UIColor redColor]];
        [self.view addSubview:self.screenButtons];
        
        self.screenButtonsLeft = [[UIView alloc] initWithFrame:CGRectMake(140, 130, 70, 70)];
        //[self.screenButtonsLeft setBackgroundColor:[UIColor redColor]];
        [self.view addSubview:self.screenButtonsLeft];
            
        // restart coub
        UIView *restartButton = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        [restartButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.8]];
        restartButton.layer.cornerRadius = 10;
        restartButton.layer.masksToBounds = YES;
        self.restartIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"restart.png"]];
        [self.restartIcon setFrame:CGRectMake(10, 10, 50, 50)];
        [self.restartIcon setAlpha:.9];
        [restartButton addSubview:self.restartIcon];
        [restartButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        
        UITapGestureRecognizer *restartRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(replayButtonTap:)];
        [restartButton addGestureRecognizer:restartRec];
        
        [self.screenButtonsLeft addSubview:restartButton];
        
        // favourite coub
        UIView *favouriteButton  = [[UIView alloc] initWithFrame:CGRectMake(0, 80, 70, 70)];
        [favouriteButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.8]];
        favouriteButton.layer.cornerRadius = 10;
        favouriteButton.layer.masksToBounds = YES;
        self.favouriteIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"favourite.png"]];
        [self.favouriteIcon setFrame:CGRectMake(10, 10, 50, 50)];
        [self.favouriteIcon setAlpha:.9];
        [favouriteButton addSubview:self.favouriteIcon];
        [favouriteButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        
        UITapGestureRecognizer *favouriteRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(favouriteButtonTap:)];
        [favouriteButton addGestureRecognizer:favouriteRec];
        
        [self.screenButtons addSubview:favouriteButton];
        
        // share
        UIView *shareButton  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        [shareButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.8]];
        shareButton.layer.cornerRadius = 10;
        shareButton.layer.masksToBounds = YES;
        self.shareIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"share.png"]];
        [self.shareIcon setFrame:CGRectMake(10, 10, 50, 50)];
        [self.shareIcon setAlpha:.9];
        [shareButton addSubview:self.shareIcon];
        [shareButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        
        UITapGestureRecognizer *shareRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shareButtonTap:)];
        [shareButton addGestureRecognizer:shareRec];
        
        [self.screenButtons addSubview:shareButton];
    
        // playlist
        self.playlistButton  = [[UIView alloc] initWithFrame:CGRectMake(0, 160, 70, 70)];
        [self.playlistButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.8]];
        self.playlistButton.layer.cornerRadius = 10;
        self.playlistButton.layer.masksToBounds = YES;
        self.playlistIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"playlist.png"]];
        [self.playlistIcon setFrame:CGRectMake(10, 10, 50, 50)];
        [self.playlistIcon setAlpha:.9];
        [self.playlistButton addSubview:self.playlistIcon];
        [self.playlistButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        
        UITapGestureRecognizer *playlistRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playlistButtonTap:)];
        [self.playlistButton addGestureRecognizer:playlistRec];
        
        [self.screenButtons addSubview:self.playlistButton];
        
        
        
    }
    
    // PLAYLIST BOX
#pragma mark Playlist box
    {
        self.playlistBox = [[UIView alloc] initWithFrame:CGRectMake(160, 190-40, 420, 500)];
        [self.view addSubview:self.playlistBox];
        
        self.playlistTableViewController = [[PlaylistTableViewController alloc] initWithStyle:UITableViewStylePlain];
        [self addChildViewController:self.playlistTableViewController];
        self.playlistTableViewController.view.frame = CGRectMake(0, 40, 420, 350);
        
        self.playlistTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 420, 40)];
        self.playlistTitleView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:.9];
        
        // KOSTIL to fix genie animation white box on left top when startup
        self.playlistTitleView.alpha = 0;
        
        UILabel *playlistTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 0, 0)];
        playlistTitleLabel.text = @"playlist";
        playlistTitleLabel.font = [UIFont fontWithName:@"Helvetica" size:25];
        [playlistTitleLabel sizeToFit];
        [self.playlistTitleView addSubview:playlistTitleLabel];
        [self.playlistBox addSubview:self.playlistTitleView];
        
        
        [self.playlistBox addSubview:self.playlistTableViewController.view];
        
        [self hidePlaylistWithAnimation:NO];
        self.playlistTitleView.alpha = 1;
    }

    
    // CHANNEL SELECT
#pragma mark Channel select
    {
    self.channelSelect = [[UIView alloc] initWithFrame:CGRectMake(160, 190-40, 420, 500)];
    [self.view addSubview:self.channelSelect];
    
    self.channelsTableViewController = [[ChannelsTableViewController alloc] initWithStyle:UITableViewStylePlain];
    [self addChildViewController:self.channelsTableViewController];
    self.channelsTableViewController.view.frame = CGRectMake(0, 40, 420, 350);
    
    UIView *channelTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 420, 40)];
    channelTitleView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:.9];
    UILabel *channelTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 0, 0)];
    channelTitleLabel.text = @"select channel";
    //channelTitleLabel.textColor = [UIColor colorWithRed:0 green:0.533 blue:0.8 alpha:.9];
    channelTitleLabel.font = [UIFont fontWithName:@"Helvetica" size:25];
    [channelTitleLabel sizeToFit];
    [channelTitleView addSubview:channelTitleLabel];
    [self.channelSelect addSubview:channelTitleView];
    
    
    [self.channelSelect addSubview:self.channelsTableViewController.view];
    
    [self hideChannelSelectWithAnimation:NO];
    }

    
    // SEARCHBOX
#pragma mark Searchbox
    {
    [self hideSearchboxWithAnimation:NO];
    
    self.searchBox = [[UIView alloc] initWithFrame:CGRectMake(160, 190-40, 420, 25)];
    [self.view addSubview:self.searchBox];
      
    UIView *searchboxTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 420, 40)];
    searchboxTitleView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
    
    UIImageView *searchBoxIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"search_gray.png"]];
        searchBoxIcon.frame = CGRectMake(8, 8, 24, 24);
        searchBoxIcon.alpha = .3;
        [searchboxTitleView addSubview:searchBoxIcon];
        
    self.searhboxTextField = [[UITextField alloc] initWithFrame:CGRectMake(40, 0, 380, 40)];
    self.searhboxTextField.placeholder = @"search for ...";
    self.searhboxTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.searhboxTextField.font = [UIFont fontWithName:@"Helvetica" size:25];
    [searchboxTitleView addSubview:self.searhboxTextField];
    [self.searhboxTextField addTarget:self action:@selector(searchKeywordsChange:) forControlEvents:UIControlEventEditingChanged];
    [self.searhboxTextField addTarget:self action:@selector(searchGoPressed:) forControlEvents:UIControlEventEditingDidEndOnExit];
    self.searhboxTextField.returnKeyType = UIReturnKeyGo;
    [self.searchBox addSubview:searchboxTitleView];
      
    [self hideSearchboxWithAnimation:NO];
    }
    
    // MESSAGE BOX
#pragma mark Message box
    {
    self.messageBox = [[UILabel alloc] init];
    self.messageBox.center = CGPointMake(305, 240);
    self.messageBox.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.8];
    self.messageBox.textColor = [UIColor whiteColor];
    self.messageBox.textAlignment = NSTextAlignmentCenter;
    self.messageBox.font = [UIFont fontWithName:@"Helvetica" size: 19];
    
    self.messageBox.layer.cornerRadius = 10;
    self.messageBox.layer.masksToBounds = YES;
    
    [self.screenControls addSubview:self.messageBox];
    }
    
    // BOTTOM CONTROLS
#pragma mark Bottom controls
    {
    self.bottomControls = [[UIView alloc] initWithFrame:channels_and_search_unlocked?CGRectMake(10, 730, 670, 30):CGRectMake(10, 730, 715, 30)];
    [self.bottomControls setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.bottomControls];
    
    // PROGRAM SELECTOR
    // more
    self.moreButton = [[UIView alloc] initWithFrame:CGRectMake(10, 0, 100, 30)];
    
    UIImageView *moreIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"more.png"]];
    [moreIcon setFrame:CGRectMake(0, 0, 30, 30)];
    [self.moreButton addSubview:moreIcon];
    
    UILabel *moreLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 0, 70, 30)];
    moreLabel.text = @"more";
    moreLabel.textColor = [UIColor whiteColor];
    moreLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
    [self.moreButton addSubview:moreLabel];
    
    [self.bottomControls addSubview:self.moreButton];
    self.moreButton.alpha = 0.5;
    
    self.moreButton.userInteractionEnabled = YES;
    UITapGestureRecognizer *moreTapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moreButtonTap:)];
    [self.moreButton addGestureRecognizer:moreTapRec];
    
    // program panel
    self.programPanel = [[UIView alloc] initWithFrame:CGRectMake(110, 0, 1024, 30)];
    [self.bottomControls addSubview:self.programPanel];
    
    // random button
    self.randomButton = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 115, 30)];
    
    UIImageView *randomIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"random.png"]];
    [randomIcon setFrame:CGRectMake(5, 2.5, 30, 25)];
    [self.randomButton addSubview:randomIcon];
    
    UILabel *randomLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, 70, 30)];
    randomLabel.text = @"random";
    randomLabel.textColor = [UIColor whiteColor];
    randomLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
    [self.randomButton addSubview:randomLabel];
    
    [self.programPanel addSubview:self.randomButton];
    self.randomButton.alpha = 0.2;
    self.randomButton.layer.cornerRadius = 5;
    
    self.randomButton.userInteractionEnabled = YES;
    UITapGestureRecognizer *randomTapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(randomButtonTap:)];
    [self.randomButton addGestureRecognizer:randomTapRec];
    
    // hot button
    self.hotButton = [[UIView alloc] initWithFrame:CGRectMake(130, 0, 70, 30)];
    
    UIImageView *hotIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hot.png"]];
    [hotIcon setFrame:CGRectMake(5, 2.5, 25, 25)];
    [self.hotButton addSubview:hotIcon];
    
    UILabel *hotLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 0, 70, 30)];
    hotLabel.text = @"hot";
    hotLabel.textColor = [UIColor whiteColor];
    hotLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
    [self.hotButton addSubview:hotLabel];
    
    [self.programPanel addSubview:self.hotButton];
    self.hotButton.alpha = 0.2;
    

    self.hotButton.layer.cornerRadius = 5;
    
    self.hotButton.userInteractionEnabled = YES;
    UITapGestureRecognizer *hotTapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hotButtonTap:)];
    [self.hotButton addGestureRecognizer:hotTapRec];
        
    // favourite bottom button
    self.favouriteBottomButton = [[UIView alloc] initWithFrame:CGRectMake(210, 0, 90, 30)];
    
    UIImageView *favouriteBottomIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"favourite.png"]];
    [favouriteBottomIcon setFrame:CGRectMake(5, 2.5, 25, 25)];
    [self.favouriteBottomButton addSubview:favouriteBottomIcon];
    
    UILabel *favouriteBottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 0, 90, 30)];
    favouriteBottomLabel.text = @"favourite";
    favouriteBottomLabel.textColor = [UIColor whiteColor];
    favouriteBottomLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
    [self.favouriteBottomButton addSubview:favouriteBottomLabel];
    
    [self.programPanel addSubview:self.favouriteBottomButton];
    self.favouriteBottomButton.alpha = 0.2;
    
    
    self.favouriteBottomButton.layer.cornerRadius = 5;
    
    self.favouriteBottomButton.userInteractionEnabled = YES;
    UITapGestureRecognizer *favouriteBottomTapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(favouriteBottomTap:)];
    [self.favouriteBottomButton addGestureRecognizer:favouriteBottomTapRec];
    
    
    // channel button
    /*self.channelButton = [[UIView alloc] initWithFrame:CGRectMake(340, 0, 112, 30)];
    
    UIImageView *channelIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"channels.png"]];
    [channelIcon setFrame:CGRectMake(5, 5, 25, 20)];
    [self.channelButton addSubview:channelIcon];
    
    UILabel *channelLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 0, 90, 30)];
    channelLabel.text = @"channel";
    channelLabel.textColor = [UIColor whiteColor];
    channelLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
    [self.channelButton addSubview:channelLabel];
    
    [self.programPanel addSubview:self.channelButton];
    self.channelButton.alpha = 0.2;
    
    
    self.channelButton.layer.cornerRadius = 5;
    
    self.channelButton.userInteractionEnabled = YES;
    UITapGestureRecognizer *channelTapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(channelButtonTap:)];
    [self.channelButton addGestureRecognizer:channelTapRec];
    */
    // search button
    self.searchButton = [[UIView alloc] initWithFrame:CGRectMake(340, 0, 97, 30)];
    
    UIImageView *searchIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"search.png"]];
    [searchIcon setFrame:CGRectMake(5, 5, 20, 20)];
    [self.searchButton addSubview:searchIcon];
    
    UILabel *searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, 90, 30)];
    searchLabel.text = @"search";
    searchLabel.textColor = [UIColor whiteColor];
    searchLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
    [self.searchButton addSubview:searchLabel];
    
    [self.programPanel addSubview:self.searchButton];
    self.searchButton.alpha = 0.2;
    
    
    self.searchButton.layer.cornerRadius = 5;
    
    self.searchButton.userInteractionEnabled = YES;
    UITapGestureRecognizer *searchTapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(searchButtonTap:)];
    [self.searchButton addGestureRecognizer:searchTapRec];
    
    
    
    self.programPanel.alpha = 0.0;
    self.programPanel.frame = CGRectOffset(self.programPanel.frame, 0, 50);
    self.moreHidden = YES;
        
        
#pragma mark Unlock
        
    if(channels_and_search_unlocked){
        self.searchButton.hidden = NO;
        self.channelButton.hidden = YES;
    }else{
        self.searchButton.hidden = YES;
        self.channelButton.hidden = YES;
        
        // unlock button

        self.unlockButton = [[UIView alloc] initWithFrame:CGRectMake(340, 0, 260, 30)];
        
        UIImageView *unlockIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"unlock.png"]];
        [unlockIcon setFrame:CGRectMake(5, 5, 25, 25)];
        [self.unlockButton addSubview:unlockIcon];
        
        UILabel *unlockLabel = [[UILabel alloc] initWithFrame:CGRectMake(35, 0, 250, 30)];
        unlockLabel.text = @"unlock search&channels";
        unlockLabel.textColor = [UIColor whiteColor];
        unlockLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
        [self.unlockButton addSubview:unlockLabel];
        
        [self.programPanel addSubview:self.unlockButton];
        self.unlockButton.alpha = 0.2;
        
        
        self.unlockButton.layer.cornerRadius = 5;
        
        self.unlockButton.userInteractionEnabled = YES;
        UITapGestureRecognizer *unlockTapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(unlockTap:)];
        [self.unlockButton addGestureRecognizer:unlockTapRec];
        
        self.unlockView = [[UIView alloc] initWithFrame:CGRectMake(160, 190-40, 520, 400)];
        [self.unlockView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.8]];
        UILabel *unlockTitle = [[UILabel alloc] init];
        unlockTitle.text = @"Check out that features!";
        unlockTitle.textColor = [UIColor whiteColor];
        unlockTitle.font = [UIFont fontWithName:@"Helvetica" size:40];
        [unlockTitle sizeToFit];
        unlockTitle.center = CGPointMake(260, 50);
        [self.unlockView addSubview:unlockTitle];
        
        UIImageView *searchFeatureImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"search_feature.png"]];
        [searchFeatureImage setFrame:CGRectMake(50, 90, 200, 170)];
        [self.unlockView addSubview:searchFeatureImage];
        
        UIImageView *channelFeatureImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"channel_feature.png"]];
        [channelFeatureImage setFrame:CGRectMake(130, 140, 200, 170)];
        [self.unlockView addSubview:channelFeatureImage];
        
        UILabel *searchLabel = [[UILabel alloc] init];
        searchLabel.text = @"search";
        searchLabel.textColor = [UIColor whiteColor];
        searchLabel.font = [UIFont fontWithName:@"Helvetica" size:30];
        [searchLabel sizeToFit];
        searchLabel.center = CGPointMake(390, 110);
        [self.unlockView addSubview:searchLabel];
        
        UILabel *channelsLabel = [[UILabel alloc] init];
        channelsLabel.text = @"&channels";
        channelsLabel.textColor = [UIColor whiteColor];
        channelsLabel.font = [UIFont fontWithName:@"Helvetica" size:30];
        [channelsLabel sizeToFit];
        channelsLabel.center = CGPointMake(430, 145);
        [self.unlockView addSubview:channelsLabel];
        
        UILabel *updateLabel = [[UILabel alloc] init];
        updateLabel.text = @"$1.99 update";
        updateLabel.textColor = [UIColor whiteColor];
        updateLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
        [updateLabel sizeToFit];
        updateLabel.center = CGPointMake(450, 175);
        [self.unlockView addSubview:updateLabel];
        
        UIButton *buyButton = [[UIButton alloc] initWithFrame:CGRectMake(370, 210, 100, 50)];
        [buyButton setTitle:@"Get" forState:UIControlStateNormal];
        buyButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:30];
        [buyButton setBackgroundColor:[UIColor colorWithRed:0 green:0.533 blue:0.8 alpha:1]];
        buyButton.layer.cornerRadius = 3;
        [self.unlockView addSubview:buyButton];
        
        UITapGestureRecognizer *buyTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapsUnlockFeatures:)];
        [buyButton addGestureRecognizer:buyTap];
        
        UILabel *orLabel = [[UILabel alloc] init];
        orLabel.text = @"or";
        orLabel.textColor = [UIColor whiteColor];
        orLabel.font = [UIFont fontWithName:@"Helvetica" size:20];
        [orLabel sizeToFit];
        orLabel.center = CGPointMake(385, 280);
        [self.unlockView addSubview:orLabel];
        
        UIButton *restoreButton = [[UIButton alloc] initWithFrame:CGRectMake(400, 268, 80, 25)];
        [restoreButton setTitle:@"restore" forState:UIControlStateNormal];
        restoreButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
        [restoreButton setBackgroundColor:[UIColor grayColor]];
        restoreButton.layer.cornerRadius = 3;
        [self.unlockView addSubview:restoreButton];
        
        UITapGestureRecognizer *restoreTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(restoreTap:)];
        [restoreButton addGestureRecognizer:restoreTap];
        
        UIButton *notNowButton = [[UIButton alloc] initWithFrame:CGRectMake(400, 347, 100, 35)];
        [notNowButton setTitle:@"not now" forState:UIControlStateNormal];
        notNowButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:22];
        [notNowButton setBackgroundColor:[UIColor grayColor]];
        notNowButton.layer.cornerRadius = 3;
        [self.unlockView addSubview:notNowButton];
        
        UITapGestureRecognizer *notNowTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapsNotNow:)];
        [notNowButton addGestureRecognizer:notNowTap];
        
        [self.view addSubview:self.unlockView];
        
        
        
        
        self.unlockView.alpha = 0;
        self.unlockView.hidden = YES;
        self.unlockView.userInteractionEnabled = YES;
    }
    
    }
    
#pragma mark InfoView
    // info button
    self.infoButton = [[UIButton alloc] init];
    [self.infoButton setBackgroundImage:[UIImage imageNamed:@"info_icon.png"] forState:UIControlStateNormal];
    self.infoButton.frame = CGRectMake(0, 0, 30, 30);
    self.infoButton.center = CGPointMake(994, 743);
    self.infoButton.alpha = .2;
    [self.view addSubview:self.infoButton];
    
    UITapGestureRecognizer *infoTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(infoTap:)];
    [self.infoButton addGestureRecognizer:infoTap];
    
    self.infoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1024, 728)];
    self.infoView.alpha = 0;
    [self.view addSubview:self.infoView];
    
    UITapGestureRecognizer *infoTap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(infoTap:)];
    [self.infoView addGestureRecognizer:infoTap2];
    
    UILabel *tapToSeeControls = [[UILabel alloc] init];
    tapToSeeControls.text = @"tap on screen to see controls";
    tapToSeeControls.textColor = [UIColor whiteColor];
    tapToSeeControls.font = [UIFont fontWithName:@"Helvetica" size:30];
    tapToSeeControls.layer.shadowOpacity = 1;
    tapToSeeControls.layer.shadowRadius = 5;
    tapToSeeControls.layer.shadowColor = [UIColor blackColor].CGColor;
    tapToSeeControls.layer.shadowOffset = CGSizeZero;
    [tapToSeeControls sizeToFit];
    tapToSeeControls.center = CGPointMake(425, 320);
    [self.infoView addSubview:tapToSeeControls];
    
    UILabel *swipeToPlay = [[UILabel alloc] init];
    swipeToPlay.text = @"swipe right/left to play next/prev";
    swipeToPlay.textColor = [UIColor whiteColor];
    swipeToPlay.font = [UIFont fontWithName:@"Helvetica" size:30];
    swipeToPlay.layer.shadowOpacity = 1;
    swipeToPlay.layer.shadowRadius = 5;
    swipeToPlay.layer.shadowColor = [UIColor blackColor].CGColor;
    swipeToPlay.layer.shadowOffset = CGSizeZero;
    [swipeToPlay sizeToFit];
    swipeToPlay.center = CGPointMake(425, 380);
    [self.infoView addSubview:swipeToPlay];
    
    UILabel *pinchToZoom = [[UILabel alloc] init];
    pinchToZoom.text = @"pinch to go fullscreen";
    pinchToZoom.textColor = [UIColor whiteColor];
    pinchToZoom.font = [UIFont fontWithName:@"Helvetica" size:30];
    pinchToZoom.layer.shadowOpacity = 1;
    pinchToZoom.layer.shadowRadius = 5;
    pinchToZoom.layer.shadowColor = [UIColor blackColor].CGColor;
    pinchToZoom.layer.shadowOffset = CGSizeZero;
    [pinchToZoom sizeToFit];
    pinchToZoom.center = CGPointMake(425, 440);
    [self.infoView addSubview:pinchToZoom];

    
    UILabel *tapToPlayNext = [[UILabel alloc] init];
    tapToPlayNext.text = @"tap to play next";
    tapToPlayNext.textColor = [UIColor whiteColor];
    tapToPlayNext.font = [UIFont fontWithName:@"Helvetica" size:30];
    tapToPlayNext.layer.shadowOpacity = 1;
    tapToPlayNext.layer.shadowRadius = 5;
    tapToPlayNext.layer.shadowColor = [UIColor blackColor].CGColor;
    tapToPlayNext.layer.shadowOffset = CGSizeZero;
    [tapToPlayNext sizeToFit];
    tapToPlayNext.center = CGPointMake(885, 480);
    [self.infoView addSubview:tapToPlayNext];
    
    UILabel *contactDev = [[UILabel alloc] init];
    contactDev.text = @"contact developer";
    contactDev.textColor = [UIColor whiteColor];
    contactDev.font = [UIFont fontWithName:@"Helvetica" size:30];
    contactDev.layer.shadowOpacity = 1;
    contactDev.layer.shadowRadius = 5;
    contactDev.layer.shadowColor = [UIColor blackColor].CGColor;
    contactDev.layer.shadowOffset = CGSizeZero;
    [contactDev sizeToFit];
    contactDev.center = CGPointMake(880, 40);
    UITapGestureRecognizer *contactDevTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(composeMailToDev:)];
    [contactDev addGestureRecognizer:contactDevTap];
    [contactDev setUserInteractionEnabled:YES];
    [self.infoView addSubview:contactDev];
    
#pragma mark ShareView
    _shareRect = CGRectMake(705, 160, 1, 1);
    _shareDirection = UIPopoverArrowDirectionLeft;
    self.shareSelectViewController = [[ShareTableViewController alloc] init];
    
    
    
    
    // screen gestures
#pragma mark Screen gestures
    UIPinchGestureRecognizer *zoomScreenRec = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomScreen:)];
    zoomScreenRec.delegate = self;
    [self.screenControls addGestureRecognizer:zoomScreenRec];
    
    UITapGestureRecognizer *tapOnScreenRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenTap:)];
    tapOnScreenRec.cancelsTouchesInView = NO;
    [self.screenControls addGestureRecognizer:tapOnScreenRec];
    
    UIPanGestureRecognizer *panOnScreenRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panScreen:)];
    panOnScreenRec.cancelsTouchesInView = NO;
    panOnScreenRec.delegate = self;
    [self.screenControls addGestureRecognizer:panOnScreenRec];
    
    
    
    [self hideScreenControlsWithAnimation:NO];
    
}




- (void) infoTap: (UITapGestureRecognizer *) rec
{
    
    if(!self.infoView.alpha){
        // show info
        [UIView animateWithDuration:.5 animations:^{
            self.infoView.alpha = 1;
            self.infoButton.alpha = .8;
        }];
    }else{
        // hide info
        [UIView animateWithDuration:.5 animations:^{
            self.infoView.alpha = 0;
            self.infoButton.alpha = .2;
        }];
    }
    
}

- (void) composeMailToDev: (id) sender {
    _mailSupportComposer = [[MFMailComposeViewController alloc]init];
    [_mailSupportComposer setMailComposeDelegate:self];
    if([MFMailComposeViewController canSendMail])
    {
        [_mailSupportComposer setToRecipients:[NSArray arrayWithObjects:@"george.fedoseev@me.com", nil]];
        [_mailSupportComposer setSubject:@"CoubTV Support"];
        [_mailSupportComposer setMessageBody:@"" isHTML:NO];
        [_mailSupportComposer setModalPresentationStyle:UIModalPresentationPageSheet];
        [self presentViewController:_mailSupportComposer animated:YES completion:nil];
    }
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
   
    if(_mailSupportComposer){
        [_mailSupportComposer dismissViewControllerAnimated:YES completion:^{}];
    }
}


#pragma mark Purchases
// PURCHASES

- (void) unlockFeatures
{
    [self.mvc saveIcloudUserDataForKey:@"channels_and_search_unlocked" value:@"1"];
    [self.mvc saveLocalUserDataForKey:@"channels_and_search_unlocked" value:@"1"];
    
    self.searchButton.hidden = NO;
    self.channelButton.hidden = NO;
    self.unlockButton.hidden = YES;
    self.unlockView.hidden = YES;
    self.randomButton.alpha = (self.mode == TvBoxModeRandom)?1:0.2;
    self.hotButton.alpha = (self.mode == TvBoxModeHot)?1:0.2;
    self.favouriteBottomButton.alpha = (self.mode == TvBoxModeFavourites)?1:0.2;
    self.channelButton.alpha = (self.mode == TvBoxModeChannel)?1:0.2;
    self.searchButton.alpha = (self.mode == TvBoxModeSearch)?1:0.2;
    
    self.bottomControls.frame = CGRectMake(10, 730, 670, 30);
    
    [self showScreenControlsHide:YES];
    [self displayMessage:@"Features unlocked!" hide:YES];
}

#define kUnlockProductIdentifier @"search_and_channels"

- (void)tapsNotNow: (id) sender
{
    [self changeScreenConrtrolsStateTo:self.previousScreenControlsState];
    [self glowButtonByCurrentModeWithAnimation:YES];
}
        

- (void)tapsUnlockFeatures: (id) sender
{
    NSLog(@"User requests to remove ads");
    
    if([SKPaymentQueue canMakePayments]){
        NSLog(@"User can make payments");
        
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kUnlockProductIdentifier]];
        productsRequest.delegate = self;
        [productsRequest start];
        
    }
    else{
        NSLog(@"User cannot make payments due to parental controls");
        //this is called the user cannot make payments, most likely due to parental controls
    }
}



- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    SKProduct *validProduct = nil;
    int count = [response.products count];
    if(count > 0){
        validProduct = [response.products objectAtIndex:0];
        NSLog(@"Products Available!");
        [self purchase:validProduct];
    }
    else if(!validProduct){
        NSLog(@"No products available");
        //this is called if your product id is not valid, this shouldn't be called unless that happens.
    }
}

- (IBAction)purchase:(SKProduct *)product{
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void) restoreTap: (UIGestureRecognizer *)rec
{
    //this is called when the user restores purchases, you should hook this up to a button
    //[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}



- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"received restored transactions: %i", queue.transactions.count);
    for (SKPaymentTransaction *transaction in queue.transactions)
    {
        if(SKPaymentTransactionStateRestored){
            NSLog(@"Transaction state -> Restored");
            //called when the user successfully restores a purchase
            NSLog(@"ADD FEATURES!");
            [self unlockFeatures];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            break;
        }
        
    }
    
}

- (void) paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"ERRRO PURCHASING: %@", error.userInfo);
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    for(SKPaymentTransaction *transaction in transactions){
        switch (transaction.transactionState){
            case SKPaymentTransactionStatePurchasing: NSLog(@"Transaction state -> Purchasing");
                //called when the user is in the process of purchasing, do not add any of your own code here.
                break;
            case SKPaymentTransactionStatePurchased:
                //this is called when the user has successfully purchased the package (Cha-Ching!)
                [self unlockFeatures];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                NSLog(@"Transaction state -> Purchased");
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Transaction state -> Restored");
                //add the same code as you did from SKPaymentTransactionStatePurchased here
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                //called when the transaction does not finnish
                if(transaction.error.code != SKErrorPaymentCancelled){
                    NSLog(@"Transaction state -> Cancelled: %@", transaction.error.userInfo);
                    //the user cancelled the payment ;(
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
        }
    }
}


// TAP ON BOTTOM BUTTONS
#pragma mark - Tap on bottom buttons


- (void) changeScreenConrtrolsStateTo: (ScreenControlsState) state
{
    self.previousScreenControlsState = self.screenControlsState;
    self.screenControlsState = state;
    
    if(state == ScreenControlsStateClear){
        [self hideScreenControlsWithAnimation:YES];
    }
    
    if(state != ScreenControlsStateButtons){
        [self hideVideoScreenInfoWithAnimation:YES];
    }
    
    if(state != ScreenControlsStateChannels){
        [self hideChannelSelectWithAnimation:YES];
    }
    
    if(state != ScreenControlsStatePlaylist){
        if(self.mode == TvBoxModeSearch){
            [self hidePlaylistWithAnimation:NO];
        }else{
            [self hidePlaylistWithAnimation:YES];
        }
    }
    if(state != ScreenControlsStateSearch){
        [self hideSearchboxWithAnimation:YES];
    }
    if(state == ScreenControlsStateClear){
        [self hideScreenControlsWithAnimation:YES];
    }
    
    if(state != ScreenControlsStateUnlock){
        [self hideUnlockWithAnimation:YES];
    }
    
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * .1);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        if(state == ScreenControlsStateButtons){
            [self showScreenControlsHide:NO];
            [self showLeftButtonsWithAnimation:YES];
            
            if(self.mvc.screen.state == CoubTVStatePlaying)
                [self showVideoScreenInfoWithAnimation:YES];
            
        } else if(state == ScreenControlsStatePlaylist){
            [self showPlaylistWithAnimation:YES];
            [self showScreenControlsHide:NO];
            
            [self hideLeftButtonsWithAnimation:NO];
            
            if(self.mode == TvBoxModeSearch){
                [self showSearchboxWithAnimation:NO];
            }
        } else if(state == ScreenControlsStateChannels){
            [self showChannelSelectWithAnimation:YES];
            [self hideLeftButtonsWithAnimation:NO];
        } else if(state == ScreenControlsStateSearch){
            [self showSearchboxWithAnimation:NO];
            [self showScreenControlsHide:NO];
            
            [self hideLeftButtonsWithAnimation:NO];
            
            if(self.mode == TvBoxModeSearch){
                [self showPlaylistWithAnimation:YES];
            }
        } else if(state == ScreenControlsStateClear){
            
        } else if(state == ScreenControlsStateUnlock){
            
            if(self.moreHidden){
                [self moreButtonTap:nil];
            }
            
            [self showUnlockWithAnimation:YES];
            [self hideLeftButtonsWithAnimation:NO];
            [self hideScreenControlsWithAnimation:NO];
        }
    });
}

- (void) glowBottomButton: (UIView *) button withAnimation: (BOOL) animation {
    [UIView animateWithDuration:animation?.3:0 animations:^{
        self.randomButton.alpha = 0.2;
        self.hotButton.alpha = 0.2;
        self.favouriteBottomButton.alpha = 0.2;
        self.channelButton.alpha = 0.2;
        self.searchButton.alpha = 0.2;
        self.unlockButton.alpha = 0.2;
        
        button.alpha = 1;
    } completion:^(BOOL finished) {
    }];
}

- (void) glowButtonByCurrentModeWithAnimation: (BOOL) animation {
    [UIView animateWithDuration:animation?.3:0 animations:^{
        self.randomButton.alpha = (self.mode == TvBoxModeRandom)?1:0.2;
        self.hotButton.alpha = (self.mode == TvBoxModeHot)?1:0.2;
        self.favouriteBottomButton.alpha = (self.mode == TvBoxModeFavourites)?1:0.2;
        self.channelButton.alpha = (self.mode == TvBoxModeChannel)?1:0.2;
        self.searchButton.alpha = (self.mode == TvBoxModeSearch)?1:0.2;
        self.unlockButton.alpha = 0.2;
    } completion:^(BOOL finished) {
    }];
}

- (void) shareButtonTap: (UITapGestureRecognizer *) rec {
    NSLog(@"SHARE");
    self.shareSelectPopoverController = [[UIPopoverController alloc]
                    initWithContentViewController:self.shareSelectViewController];
    self.shareSelectPopoverController.popoverContentSize = CGSizeMake(300, 200);
    [self.shareSelectPopoverController setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.4]];

    [self.shareSelectPopoverController presentPopoverFromRect:
                    _shareRect
                    inView:self.view
                     permittedArrowDirections:_shareDirection
                                     animated:YES];    
    
}

- (void) shareTo:(NSNotification *) notification {
    
    // load cookies
    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData: [[NSUserDefaults standardUserDefaults] objectForKey: @"cookies"]];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    for (NSHTTPCookie *cookie in cookies)
    {
        [cookieStorage setCookie: cookie];
    }
    
    
    ShareTo shareTo = (ShareTo)[(NSString *)notification.object intValue];
    if(self.mvc.playlistPointer >= 0 && self.mvc.playlistPointer < self.mvc.currentPlaylist.count){
        NSDictionary *coub = self.mvc.currentPlaylist[self.mvc.playlistPointer];
        if(coub){
            NSString *coubId = [coub objectForKey:@"permalink"];
            NSString *coubUrl = [NSString stringWithFormat:@"http://coub.com/view/%@", coubId];
            NSString *coubTitle = [coub objectForKey:@"title"];
            NSString *shortTitle = ([coubTitle length]>90 ? [[coubTitle substringToIndex:90] stringByAppendingString:@"..."] : coubTitle);
           
            
            NSString *urlStr;
            switch (shareTo) {
                case ShareToFacebook:
                    urlStr = [NSString stringWithFormat:@"https://www.facebook.com/sharer/sharer.php?p[url]=%@&p[title]=%@ %@", coubUrl, coubTitle, @"#coubtv"];
                    break;
                case ShareToGoogle:
                    urlStr = [NSString stringWithFormat:@"https://plus.google.com/share?url=%@&title=%@ %@", coubUrl, coubTitle, @"#coubtv"];
                    break;
                case ShareToTwitter:
                    urlStr = [NSString stringWithFormat:@"https://twitter.com/home?status=%@ %@ %@", shortTitle, coubUrl, @"@coubtv #coubtv"];
                    break;
                case ShareToVk:
                    urlStr = [NSString stringWithFormat:@"http://vk.com/share.php?url=%@&title=%@ %@&description=%@ %@", coubUrl, coubTitle, @"| Shared using [coubtv_app|CoubTV iPad app] #coubtv", coubTitle, @"| Shared using http://vk.com/coubtv_app"];
                    break;
                default:
                    break;
            }
            
            urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
            
            [NSHTTPCookieStorage sharedHTTPCookieStorage].cookieAcceptPolicy =
            NSHTTPCookieAcceptPolicyAlways;
            

            UIWebView * webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 540, 620)];
            webView.scrollView.contentSize = CGSizeMake(540, 620);
            UIViewController *webViewController = [[UIViewController alloc] init];
            webViewController.view = webView;
            
            
            self.shareNavigationController = [[UINavigationController alloc] initWithRootViewController:webViewController];
            self.shareNavigationController.modalPresentationStyle
                                    = UIModalPresentationFormSheet;
            
            
            UIBarButtonItem *doneButton = [[UIBarButtonItem alloc ]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                           target:self action:@selector(doneShare:)];
            
            webViewController.navigationItem.rightBarButtonItem = doneButton;
            webViewController.navigationItem.title = @"Share";
            
            
            [self dismissViewControllerAnimated:NO completion:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:self.shareNavigationController animated:YES completion:^{
                    NSURL* url = [NSURL URLWithString:urlStr];
                    NSURLRequest* request = [NSURLRequest requestWithURL:url];
                    [webView loadRequest:request];
                }];
            });
            

        }
    }
    
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.2);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        [self.shareSelectPopoverController dismissPopoverAnimated:YES];
    });
    
    
}

- (void) doneShare: (id) sender {
    [self.shareNavigationController dismissViewControllerAnimated:YES completion:^{
        NSData         *cookiesData = [NSKeyedArchiver archivedDataWithRootObject: [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
        NSUserDefaults *defaults    = [NSUserDefaults standardUserDefaults];
        [defaults setObject: cookiesData forKey: @"cookies"];
        [defaults synchronize];
    }];
}


- (void) playlistButtonTap: (UITapGestureRecognizer *) rec
{
    NSLog(@"PLAYLIST TAP");
    if(self.playlistBox.hidden){
        if(self.mode == TvBoxModeSearch){
            [self changeScreenConrtrolsStateTo:ScreenControlsStateSearch];
        }else{
            [self changeScreenConrtrolsStateTo:ScreenControlsStatePlaylist];
        }
    }else{
        [self changeScreenConrtrolsStateTo:ScreenControlsStateButtons];
    }
    
}

    - (void) showPlaylistWithAnimation: (BOOL) animation
    {
        self.playlistBox.hidden = NO;
        
        [UIView animateWithDuration:animation?.3:0 animations:^{
            self.playlistBox.alpha = 1;
            [self.playlistButton setBackgroundColor:[UIColor colorWithRed:255.0/255.0 green:136.0/255.0 blue:0.0/255.0 alpha:.8]];
            self.playlistButton.layer.borderColor = [UIColor colorWithRed:255.0/255.0 green:126.0/255.0 blue:0.0/255.0 alpha:1].CGColor;
            self.playlistButton.layer.borderWidth = 2;
        } completion:^(BOOL finished) {
        }];
    }

    - (void) hidePlaylistWithAnimation: (BOOL) animation
    {
        [UIView animateWithDuration:animation?.5:0 animations:^{
            [self.playlistButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.8]];
            self.playlistButton.layer.borderWidth = 0;
            self.playlistBox.alpha = 0;
        } completion:^(BOOL finished) {
            self.playlistBox.hidden = YES;
        }];
    }


- (void) unlockTap:(UITapGestureRecognizer *) rec
{
    NSLog(@"unlock");
    if(self.unlockView.hidden){
        NSLog(@"yes");
        [self glowBottomButton:self.unlockButton withAnimation:YES];
        [self changeScreenConrtrolsStateTo:ScreenControlsStateUnlock];
    }else{
        [self glowButtonByCurrentModeWithAnimation:YES];
        [self changeScreenConrtrolsStateTo:self.previousScreenControlsState];
    }
}

    - (void) showUnlockWithAnimation: (BOOL) animation {
        self.unlockView.hidden = NO;
        [UIView animateWithDuration:animation?.3:0 animations:^{
            self.unlockView.alpha = 1;
        } completion:^(BOOL finished) {
        }];
    }

    - (void) hideUnlockWithAnimation: (BOOL) animation {
        
        [UIView animateWithDuration:animation?.3:0 animations:^{
            self.unlockView.alpha = 0;
            self.unlockView.hidden = YES;
        } completion:^(BOOL finished) {
        }];
    }

- (void) favouriteBottomTap: (UITapGestureRecognizer *) rec
{
    NSLog(@"favourite mode");
    [UIView animateWithDuration:.3 animations:^{
        [self glowBottomButton:self.favouriteBottomButton withAnimation:YES];
    } completion:^(BOOL finished) {}];
    self.mode = TvBoxModeFavourites;
}

- (void) searchButtonTap: (UITapGestureRecognizer *) rec
{
    NSLog(@"search");
    
    if(![MainViewController isNetworkAvailable]){
        [self.mvc.tvBox showScreenControlsHide:NO];
        [self.mvc.tvBox displayMessage:@"Check network connection" hide:NO];
        return;
    }
    
    if(self.searchBox.hidden){
        [self glowBottomButton:self.searchButton withAnimation:YES];
        [self changeScreenConrtrolsStateTo:ScreenControlsStateSearch];
        
    }else{
        if(self.mode != TvBoxModeSearch){
            [self glowButtonByCurrentModeWithAnimation:YES];
            [self changeScreenConrtrolsStateTo:self.previousScreenControlsState];
        }
    }

}

    - (void) showSearchboxWithAnimation: (BOOL) animation
    {
        self.searchBox.hidden = NO;
        
        [UIView animateWithDuration:animation?.3:0 animations:^{
            self.searchBox.alpha = 1;
            for(UIView *subview in self.searchBox.subviews){
                subview.alpha = 1;
            }
        } completion:^(BOOL finished) {
        }];
    }

    - (void) hideSearchboxWithAnimation: (BOOL) animation
    {
        [UIView animateWithDuration:animation?.5:0 animations:^{
            for(UIView *subview in self.searchBox.subviews){
                subview.alpha = 0;
            }
            self.searchBox.alpha = 0;
        } completion:^(BOOL finished) {
            self.searchBox.hidden = YES;
        }];
    }

-(void) searchKeywordsChange: (UITextField *) textField
{
    NSLog(@"Keywords changed to %@", textField.text);
    self.currentKeywords = textField.text;
}
- (void) searchGoPressed: (id) sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"searchboxSearch" object:self.currentKeywords];
    NSLog(@"Return");
    
}


- (void) channelButtonTap: (UITapGestureRecognizer *) rec
{
    NSLog(@"channel");
    
    if(self.channelSelect.hidden){
        [self glowBottomButton:self.channelButton withAnimation:YES];
        [self changeScreenConrtrolsStateTo:ScreenControlsStateChannels];
    }else{
        if(self.mode != TvBoxModeChannel){
            [self glowButtonByCurrentModeWithAnimation:YES];
            [self changeScreenConrtrolsStateTo:self.previousScreenControlsState];
        }
    }
}

    - (void) showChannelSelectWithAnimation: (BOOL) animation
    {
        [UIView animateWithDuration:animation?.3:0 animations:^{
            for(UIView *subview in self.channelSelect.subviews){
                subview.alpha = 1;
            }
            self.channelSelect.alpha = 1;
        } completion:^(BOOL finished) {}];
        
        self.channelSelect.hidden = NO;
    }

    - (void) hideChannelSelectWithAnimation: (BOOL) animation
    {
        [UIView animateWithDuration:animation?.5:0 animations:^{
            for(UIView *subview in self.channelSelect.subviews){
                subview.alpha = 0;
            }
            self.channelSelect.alpha = 0;
        } completion:^(BOOL finished) {
            self.channelSelect.hidden = YES;
        }];
    }

- (void) showLeftButtonsWithAnimation: (BOOL) animation{
    [UIView animateWithDuration:animation?.3:0 animations:^{
        self.screenButtonsLeft.alpha = 1;
    } completion:^(BOOL finished) {}];
}

- (void) hideLeftButtonsWithAnimation: (BOOL) animation{
    [UIView animateWithDuration:animation?.3:0 animations:^{
        self.screenButtonsLeft.alpha = 0;
    } completion:^(BOOL finished) {}];
}


- (void) showVideoScreenInfoWithAnimation: (BOOL) animation {
    [UIView animateWithDuration:animation?.3:0 animations:^{
        self.videoScreenInfo.alpha = 1;
    } completion:^(BOOL finished) {}];
}

- (void) hideVideoScreenInfoWithAnimation: (BOOL) animation {
    [UIView animateWithDuration:animation?.3:0 animations:^{
        self.videoScreenInfo.alpha = 0;
    } completion:^(BOOL finished) {}];
}


#pragma mark Video Screen Info
- (void) updateVideoScreenInfo:(NSDictionary *) coub  {
    // clear prev
    for(UIView *view in self.videoScreenInfo.subviews){
        [view removeFromSuperview];
    }
    
    NSString *videoTitle = [coub objectForKey:@"title"];
    
    
    UIView *marqueeTitleBackground = [[UIView alloc] init];
    marqueeTitleBackground.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.5];
    
    MarqueeLabel *marqueeTitle = [[MarqueeLabel alloc] init];
    [marqueeTitle setRate: 20];
    marqueeTitle.text = videoTitle;
    marqueeTitle.font = [UIFont fontWithName:@"Helvetica" size:30];
    marqueeTitle.textColor = [UIColor whiteColor];
    
    [marqueeTitle sizeToFit];
    CGRect mtFrame = marqueeTitle.frame;
    
    mtFrame = marqueeTitle.frame = CGRectMake(25+10, 390+10,
                                        (mtFrame.size.width > 520)?520:mtFrame.size.width,
                                        mtFrame.size.height);
    
    marqueeTitleBackground.frame = CGRectMake(25, 390, mtFrame.size.width+20,
                                              mtFrame.size.height+20);
    
    [self.videoScreenInfo addSubview:marqueeTitleBackground];
    [self.videoScreenInfo addSubview:marqueeTitle];
    
    // music info
    NSDictionary *mediaBlock = [coub objectForKey:@"media_block_audio"];
    
    
    UIView *marqueeMusicBackground;
    MarqueeLabel *marqueeMusic;
    if(mediaBlock){
        NSString *title = [mediaBlock objectForKey:@"title"];
        NSString *artist = [mediaBlock objectForKey:@"artist"];
        
        if(title && artist
           && title != NULL
           && ![title  isEqual: @"Unknown"]
           && artist != NULL
           && ![artist  isEqual: @"Unknown"] )
        {
            
            NSString *musicString = [NSString stringWithFormat:@"%@ - %@", artist, title];
            
            marqueeMusicBackground = [[UIView alloc] init];
            marqueeMusicBackground.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.5];
            
            marqueeMusic = [[MarqueeLabel alloc] init];
            [marqueeMusic setRate: 20];
            marqueeMusic.text = [NSString stringWithFormat:@"♫ %@", musicString];
            marqueeMusic.font = [UIFont fontWithName:@"Helvetica" size:18];
            marqueeMusic.textColor = [UIColor whiteColor];
            
            [marqueeMusic sizeToFit];
            CGRect mmFrame = marqueeMusic.frame;
            
            mmFrame = marqueeMusic.frame = CGRectMake(25+5, 410+5,
                                                      (mmFrame.size.width > 520)?520:mmFrame.size.width,
                                                      mmFrame.size.height);
            
            marqueeMusicBackground.frame = CGRectMake(25, 410, mmFrame.size.width+10,
                                                      mmFrame.size.height+10);
            
            [self.videoScreenInfo addSubview:marqueeMusicBackground];
            [self.videoScreenInfo addSubview:marqueeMusic];
            
            
            marqueeTitle.frame = CGRectOffset(marqueeTitle.frame, 0, -40);
            marqueeTitleBackground.frame = CGRectOffset(marqueeTitleBackground.frame, 0, -40);
            
        }
    }
    
    if(self.screenControlsState == ScreenControlsStateClear){
        static NSTimeInterval lastTimeCalled;
        lastTimeCalled = [[NSDate date] timeIntervalSince1970];
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 5);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            if([[NSDate date] timeIntervalSince1970] - lastTimeCalled > 4){
                [UIView animateWithDuration:.25 animations:^{
                    self.videoScreenInfo.alpha = 0;
                    self.videoScreenInfo.frame = CGRectOffset(self.videoScreenInfo.frame, 200, 0);
                } completion:^(BOOL finished) {
                    self.videoScreenInfo.frame = CGRectOffset(self.videoScreenInfo.frame, -200, 0);
                }];
            }
        });
    }
    
}



- (void) hotButtonTap: (UITapGestureRecognizer *) rec
{
    NSLog(@"hot");
    [UIView animateWithDuration:.3 animations:^{
        [self glowBottomButton:self.hotButton withAnimation:YES];
    } completion:^(BOOL finished) {}];
    
    self.mode = TvBoxModeHot;
}

- (void) randomButtonTap: (UITapGestureRecognizer *) rec
{
    NSLog(@"random");
    [UIView animateWithDuration:.3 animations:^{
        [self glowBottomButton:self.randomButton withAnimation:YES];
    } completion:^(BOOL finished) {}];
    
     self.mode = TvBoxModeRandom;
}

- (void) moreButtonTap: (UITapGestureRecognizer *) rec
{
    NSLog(@"more");
    if(self.moreHidden){
        // open more
        [UIView animateWithDuration:.5 animations:^{
            self.moreButton.alpha = 1;
            self.programPanel.alpha = 1;

            if(self.mvc.screen.FullScreen){
                [self.bottomControls setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.8]];
            }
            
            self.programPanel.frame = CGRectOffset(self.programPanel.frame, 0, -50);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.3 animations:^{
                self.moreButton.alpha = .4;
            }];
        }];
        self.moreHidden = NO;
    }else{
        // close more
        [UIView animateWithDuration:.5 animations:^{
            self.moreButton.alpha = 0.5;
            self.programPanel.alpha = 0;
            [self.bottomControls setBackgroundColor:[UIColor clearColor]];
            self.programPanel.frame = CGRectOffset(self.programPanel.frame, 0, 50);
        } completion:^(BOOL finished) {}];
        self.moreHidden = YES;
    }
}


- (void) displayMessage: (NSString *) message hide: (BOOL) hide
{
    static NSTimeInterval lastFired;
    
    self.messageBox.text = message;
    [self.messageBox sizeToFit];
    CGRect frame = self.messageBox.frame;
    frame.size.width += 20;
    frame.size.height += 20;
    self.messageBox.frame = frame;
    self.messageBox.center = self.mvc.screen.FullScreen?CGPointMake(512, 384):CGPointMake(305, 240);
    
    if([[NSDate date] timeIntervalSince1970] - lastFired > 1.0)
        self.messageBox.transform = CGAffineTransformMakeScale(0, 0);
    
    [UIView animateWithDuration:0.2 animations:^(void) {
        if([[NSDate date] timeIntervalSince1970] - lastFired > 1.0)
            self.messageBox.transform = CGAffineTransformMakeScale(1.5, 1.5);
        if(!self.screenControlsHidden)
            self.messageBox.alpha = 1.0;
        
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.3 animations:^(void) {
            self.messageBox.transform = CGAffineTransformMakeScale(1, 1);
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 5);
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                if(([[NSDate date] timeIntervalSince1970] - lastFired > 5) && hide){
                    [self hideMesssage];
                }
            });
        }];
    }];
    
    
    lastFired = [[NSDate date] timeIntervalSince1970];
}

- (void) hideMesssage
{
    [UIView animateWithDuration:0.2 animations:^(void) {
        self.messageBox.alpha = 0.0;
        self.messageBox.transform = CGAffineTransformMakeScale(0, 0);
    } completion:^(BOOL finished) {
        self.messageBox.transform = CGAffineTransformMakeScale(1, 1);
    }];
}

- (void) updateBottomProgressBar: (int) percents
{
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.bottomProgressBar.frame = CGRectMake(0, 763, 1024*(percents/100.0), 5);
    } completion:^(BOOL finished) {}];
}



- (void) videoDownloadPercentageChange: (NSNotification *) notification
{
    static int prevPercentage;
    int percentage = [((NSString *)notification.object) intValue];
    [self displayMessage:[NSString stringWithFormat:@"%i%% complete", percentage] hide:YES];
    [self updateBottomProgressBar:percentage];
    
    // check if hanging
    static NSTimeInterval percentageLastChanged;
    
    if(percentage != prevPercentage)
        percentageLastChanged = [[NSDate date] timeIntervalSince1970];
    
    if([[NSDate date] timeIntervalSince1970] - percentageLastChanged > 5){
        // 5 sec hanging - restart
        [self.mvc reloadCurrentCoub];
        NSLog(@"LOADING TOO LONG - RESTART LOADING");
        percentageLastChanged = [[NSDate date] timeIntervalSince1970];
    }
    
    prevPercentage = percentage;
    
}

- (void) setFavourite: (BOOL) favourite withAnimation: (BOOL) animation
{
    if(favourite){
        [self.favouriteIcon setImage:[UIImage imageNamed:@"favourite_active.png"]];
    }else{
        [self.favouriteIcon setImage:[UIImage imageNamed:@"favourite.png"]];
    }
    
    if(animation){
        if(favourite)
            [self displayMessage:@"Favourited on iCloud!" hide:YES];
        
        [UIView animateWithDuration:0.2 animations:^(void) {
            self.favouriteIcon.transform = CGAffineTransformMakeScale(0.5, 0.5);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.3 animations:^(void) {
                self.favouriteIcon.transform = CGAffineTransformMakeScale(1, 1);
            }];
        }];
    }
}


- (void) favouriteButtonTap: (UITapGestureRecognizer *) rec
{
    NSLog(@"favourite TAP");
    if(self.mvc.screen.state != CoubTVStatePlaying)
        return;
    if(!self.currentVideoFavourited){
        if([self addToFavouritesCurrentVideo]){
            [self setFavourite:YES withAnimation:YES];
        }else{
            [self displayMessage:@"No iCloud access" hide:YES];
        }
    }else{
        if([self removeFromFavouritesCurrentVideo]){
            [self setFavourite:NO withAnimation:YES];
        }else{
            [self displayMessage:@"No iCloud access" hide:YES];
        }
    }
}

- (void) newVideoLoading: (NSNotification *) notification
{
    [self setFavourite:NO withAnimation:NO];
    [self hideVideoScreenInfoWithAnimation:NO];
    
    long long videoCounter = 0;
    
    if([[NSUserDefaults standardUserDefaults] objectForKey: @"videoCounter"]){
        NSString *videoCounterStr = [[NSUserDefaults standardUserDefaults] objectForKey: @"videoCounter"];
        NSLog(@"VideoCount: %@", videoCounterStr);
        videoCounter = [videoCounterStr longLongValue];
        
    }    
    
    if(videoCounter % 50 == 0){
        [self unlockTap:nil];
    }
    
    videoCounter++;
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%lli", videoCounter] forKey:@"videoCounter"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    

}

- (void) newVideoStarted: (NSNotification *) notification
{
    self.currentVideoFavourited = [self isCurrentVideoFavourited];
    [self setFavourite:self.currentVideoFavourited withAnimation:NO];
    
    
    NSDictionary *coub = self.playlistTableViewController.currentPlaylist[self.playlistTableViewController.playlistPointer];
    [self updateVideoScreenInfo: coub];
    [self showVideoScreenInfoWithAnimation:YES];
    [self updateBottomProgressBar:0];
}

- (BOOL) isCurrentVideoFavourited
{
    NSDictionary *currentCoubId = [self.playlistTableViewController.currentPlaylist[self.playlistTableViewController.playlistPointer] objectForKey:@"permalink"];
    NSMutableArray *favouriteCoubs = [[self.mvc getIcloudUserDataForKey:@"favourited_coubs"] mutableCopy];
    if(!favouriteCoubs)
        return NO;
    return ([favouriteCoubs indexOfObject:currentCoubId]!=NSNotFound);
}

- (BOOL) addToFavouritesCurrentVideo
{
    
    NSDictionary *currentCoub = self.playlistTableViewController.currentPlaylist[self.playlistTableViewController.playlistPointer];
    NSString *coubId = (NSString *)[currentCoub objectForKey:@"permalink"];
    
    NSMutableArray *favouriteCoubs = [[self.mvc getIcloudUserDataForKey:@"favourited_coubs"] mutableCopy];
    if(!favouriteCoubs)
        return NO;
    [favouriteCoubs addObject:coubId];
    
    if([self.mvc saveIcloudUserDataForKey:@"favourited_coubs" value:favouriteCoubs]){
        //NSLog(@"favourited count: %li", favouriteCoubs.count);
        
        self.currentVideoFavourited = YES;
        return YES;
    }
    
    return NO;
}

- (BOOL) removeFromFavouritesCurrentVideo
{
    NSDictionary *currentCoub = self.playlistTableViewController.currentPlaylist[self.playlistTableViewController.playlistPointer];
    NSString *coubId = (NSString *)[currentCoub objectForKey:@"permalink"];
    
    NSMutableArray *favouriteCoubs = [[self.mvc getIcloudUserDataForKey:@"favourited_coubs"] mutableCopy];
    if(!favouriteCoubs)
        return NO;
    [favouriteCoubs removeObject:coubId];
    if([self.mvc saveIcloudUserDataForKey:@"favourited_coubs" value:favouriteCoubs]){
        self.currentVideoFavourited = NO;
        return YES;
    }
    
    return NO;
    
}

- (void) replayButtonTap: (UITapGestureRecognizer *) rec
{
    NSLog(@"replay TAP");
    
    if(self.mvc.screen.state == CoubTVStatePlaying){
        [UIView animateWithDuration:0.7 animations:^(void) {
            self.restartIcon.transform = CGAffineTransformMakeRotation(M_PI);
        } completion:^(BOOL finished) {
            self.restartIcon.transform = CGAffineTransformMakeRotation(0);
        }];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"replayCurrent" object:nil];
    }
}

- (void) screenTap: (UITapGestureRecognizer *) rec
{
    NSLog(@"SCREEN TAP");
    if(self.screenControlsHidden){
        [self changeScreenConrtrolsStateTo:ScreenControlsStateButtons];
    }else{
        [self changeScreenConrtrolsStateTo:ScreenControlsStateClear];
    }
    
    [self glowButtonByCurrentModeWithAnimation:YES];
}

- (void) showScreenControlsHide: (BOOL) hide
{
    static NSTimeInterval lastTapped;
    lastTapped = [[NSDate date] timeIntervalSince1970];
    
    self.screenControlsHidden = NO;
    
    [UIView animateWithDuration:.3 animations:^(void) {
        for(UIView *subview in self.screenControls.subviews){
            if(subview != self.messageBox
               && subview != self.channelsTableViewController.view
               && subview != self.videoScreenInfo
            ){
                subview.alpha = 1.0;
            }
        }
        
        self.screenButtons.alpha = 1;
        self.screenButtonsLeft.alpha = 1;
        
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 9);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            if(!self.screenControlsHidden && ([[NSDate date] timeIntervalSince1970] - lastTapped > 9) && hide){
                [self hideScreenControlsWithAnimation:YES];
            }
        });
    } completion:^(BOOL finished) {
    }];
}

- (void) hideScreenControlsWithAnimation: (BOOL) animation
{
    
    [UIView animateWithDuration:animation?.3:0 animations:^(void) {
        for(UIView *subview in self.screenControls.subviews)
            subview.alpha = 0;
        
        self.screenButtons.alpha = 0;
        self.screenButtonsLeft.alpha = 0;
        
    } completion:^(BOOL finished) {
        self.screenControlsHidden = YES;
    }];
}


- (void) zoomScreen: (UIPinchGestureRecognizer *) rec
{
    
    if([rec state] == UIGestureRecognizerStateEnded) {
        //NSLog(@"%f", rec.scale);
        if(rec.scale > 1.2){
            // go fullscreen. hide controls
            self.pixelGrid.hidden = YES;
            self.oldTvImage.hidden = YES;
            self.emitterLayer.hidden = YES;
            self.glowView.hidden = YES;
            self.controlsView.hidden = YES;
            [self.screenControls setFrame:CGRectMake(0, 0, 1024, 768)];
            self.screenButtons.frame = CGRectMake(934, 20, 70, 230);
            self.screenButtonsLeft.frame = CGRectMake(20, 20, 70, 70);
            self.messageBox.center = CGPointMake(512, 384);
            
            self.playlistBox.frame = CGRectMake(570-20, 190-40+190-20, 420, 500);
            self.channelSelect.frame = CGRectMake(570-20, 190-40+190-20, 420, 500);
            self.unlockView.frame = CGRectMake(570-20, 190-40+190-20, 420, 500);
            self.searchBox.frame = CGRectMake(570-20, 190-40+190-20, 420, 25);
            
            if(!self.moreHidden){
                [self.bottomControls setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.8]];
            }
            
            self.infoButton.hidden = YES;
            self.infoView.hidden = YES;
            
            self.videoScreenInfo.frame = CGRectMake(0, 250,
                                                    self.videoScreenInfo.frame.size.width,
                                                    self.videoScreenInfo.frame.size.height);
            _shareRect = CGRectMake(925, 70, 1, 1);
            _shareDirection = UIPopoverArrowDirectionRight;

            [[NSNotificationCenter defaultCenter] postNotificationName:@"goFullScreen" object:nil];
        }else if(rec.scale < 0.7){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"goTvScreen" object:nil];
            
            // go tv. show controls
            self.pixelGrid.hidden = NO;
            self.oldTvImage.hidden = NO;
            self.emitterLayer.hidden = NO;
            self.glowView.hidden = NO;
            self.controlsView.hidden = NO;
            [self.screenControls setFrame:CGRectMake(115, 115+30-40, 610, 480)];
            
            self.screenButtons.frame = CGRectMake(630, 130, 70, 230);
            self.screenButtonsLeft.frame = CGRectMake(140, 130, 70, 70);
            self.messageBox.center = CGPointMake(305, 240);
            
            self.playlistBox.frame = CGRectMake(160, 190-40, 420, 500);
            self.channelSelect.frame = CGRectMake(160, 190-40, 420, 500);
            self.unlockView.frame = CGRectMake(160, 190-40, 420, 500);
            self.searchBox.frame = CGRectMake(160, 190-40, 420, 25);
            
            self.infoButton.hidden = NO;
            self.infoView.hidden = NO;
            
            self.videoScreenInfo.frame = CGRectMake(0, 0,
                                                    self.videoScreenInfo.frame.size.width,
                                                    self.videoScreenInfo.frame.size.height);
            _shareRect = CGRectMake(705, 160, 1, 1);
            _shareDirection = UIPopoverArrowDirectionLeft;
            

            
            [self.bottomControls setBackgroundColor:[UIColor clearColor]];
        }
    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

- (void) panScreen: (UIPanGestureRecognizer *) rec
{
    NSLog(@"Pan");
    if ((rec.state == UIGestureRecognizerStateChanged)/* ||
        (rec.state == UIGestureRecognizerStateEnded)*/)
    {
        CGPoint velocity = [rec velocityInView:self.view];
        if (abs(velocity.y) < 1000)
        {
           // NSLog(@"x: %f, y: %f", velocity.x, velocity.y);
            if(velocity.x > 2000){
                [self.clickSound play];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"next" object:self];
            }else if(velocity.x < -2000){
                [self.clickSound play];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"previous" object:self];
            }
        }
    }
    
    
    
}

- (void) tapOnControls: (UIGestureRecognizer *) rec
{
    [self.clickSound play];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"next" object:self];
    
}

-(void)makeViewGlow:(UIView*) view
{
    [view.layer setShouldRasterize:YES];
    [view.layer setRasterizationScale:0.5];
}

-(void)makeViewShine:(UIView*) view
{
    view.layer.shadowColor = [UIColor colorWithRed:108.0/255 green:188.0/255 blue:255.0/255 alpha:.9].CGColor;
    view.layer.shadowRadius = 100.0f;
    view.layer.shadowOpacity = .25;
    view.layer.shadowOffset = CGSizeZero;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(115, 115+30, 610, 480) cornerRadius:20];
    view.layer.shadowPath = path.CGPath;
    
    
    [UIView animateWithDuration:1.7f delay:2.0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationCurveEaseInOut | UIViewAnimationOptionRepeat | UIViewAnimationOptionAllowUserInteraction  animations:^{
        
        [UIView setAnimationRepeatCount:100000];
        
        view.transform = CGAffineTransformMakeScale(1.07f, 1.07f);
        
        
    } completion:^(BOOL finished) {
        view.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    }];
}



- (void) setMode:(TvBoxMode)mode
{
    if(mode != TvBoxModeSearch){
        if(_mode == mode)
            return;
        
        [self setFavourite:NO withAnimation:NO];
    }
    
    
    NSLog(@"Mode changed to %i", mode);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"modeChange" object:
        [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSString stringWithFormat:@"%i", mode], @"mode",         
                        nil
        ]
     
     ];
    _mode = mode;
    
    self.randomButton.alpha = (mode == TvBoxModeRandom)?1:0.2;
    self.hotButton.alpha = (mode == TvBoxModeHot)?1:0.2;
    self.channelButton.alpha = (mode == TvBoxModeChannel)?1:0.2;
    self.searchButton.alpha = (mode == TvBoxModeSearch)?1:0.2;
    
    [self.mvc.tvBox.channelsTableViewController.tableView reloadData];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
