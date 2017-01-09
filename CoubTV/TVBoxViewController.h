//
//  TVBoxViewController.h
//  CoubTV
//
//  Created by George on 2/5/14.
//  Copyright (c) 2014 George. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScreenViewController.h"
#import "ChannelsTableViewController.h"
#import "PlaylistTableViewController.h"
#import <StoreKit/StoreKit.h>

#import <QuartzCore/QuartzCore.h>
#import "UIImage+BoxBlur.h"

#import "UIView+Genie.h"
#import "MarqueeLabel.h"

#import "ShareTableViewController.h"

#import <MessageUI/MessageUI.h>

typedef enum {
    ScreenControlsStateClear,
    ScreenControlsStateButtons,
    ScreenControlsStatePlaylist,
    ScreenControlsStateChannels,
    ScreenControlsStateSearch,
    ScreenControlsStateUnlock
} ScreenControlsState;

typedef enum {
    ShareToTwitter,
    ShareToFacebook,
    ShareToGoogle,
    ShareToVk
} ShareTo;

typedef enum {TvBoxModeRandom, TvBoxModeHot, TvBoxModeFavourites, TvBoxModeChannel, TvBoxModeSearch} TvBoxMode;

@interface TVBoxViewController : UIViewController <UIGestureRecognizerDelegate,
                                    UITextFieldDelegate, SKProductsRequestDelegate,
                                    SKPaymentTransactionObserver, SKStoreProductViewControllerDelegate,
                                    SKRequestDelegate, MFMailComposeViewControllerDelegate>


    @property (nonatomic, strong) AVAudioPlayer *clickSound;

    @property (nonatomic, strong) UIImageView *pixelGrid, *oldTvImage,
                                                *favouriteIcon, *restartIcon,
                                                *playlistIcon, *shareIcon;
    @property (nonatomic, strong) UIView *controlsView, *glowView, *screenControls,
                                            *menu, *bottomControls, *channelSelect, *searchBox,
                                                *screenButtons, *screenButtonsLeft, *playlistBox,
                                                        *playlistTitleView, *infoView;
    @property (nonatomic, strong) ShareTableViewController *shareSelectViewController;
    @property (nonatomic, strong) UIPopoverController *shareSelectPopoverController;
    @property (nonatomic, strong) UINavigationController *shareNavigationController;
    @property (nonatomic) CGRect shareRect;
    @property (nonatomic) UIPopoverArrowDirection shareDirection;

    @property (nonatomic, strong) UILabel *messageBox;
    @property (nonatomic, strong) CAEmitterLayer *emitterLayer;
    @property (nonatomic, strong) UIImageView *tvProgram;
    @property (nonatomic, strong) UITextField *searhboxTextField;

    @property ScreenControlsState screenControlsState, previousScreenControlsState;

    @property (nonatomic, strong) UIView *videoScreenInfo;
    @property (nonatomic, strong) UIView *bottomProgressBar;


    @property (nonatomic, strong) UIButton  *infoButton;
    @property (nonatomic, strong) MFMailComposeViewController *mailSupportComposer;

    @property (nonatomic, strong) UIView *moreButton, *programPanel, *randomButton, *hotButton,
                                            *channelButton, *searchButton, *playlistButton,
                                                *favouriteBottomButton, *unlockButton, *unlockView;
    @property (nonatomic, strong) NSString *currentKeywords;

    @property  BOOL currentVideoFavourited;

    @property (nonatomic) TvBoxMode mode;
    @property (nonatomic, strong) ChannelsTableViewController *channelsTableViewController;
    @property (nonatomic, strong) PlaylistTableViewController *playlistTableViewController;
    - (void) hideChannelSelectWithAnimation: (BOOL) animation;
    - (void) hideSearchboxWithAnimation: (BOOL) animation;
    - (void) displayMessage: (NSString *) message hide: (BOOL) hide;
    - (void) showScreenControlsHide: (BOOL) hide;
- (void) showPlaylistWithAnimation: (BOOL) animation;
- (void) hidePlaylistWithAnimation: (BOOL) animation;



- (void) setFavourite: (BOOL) favourite withAnimation: (BOOL) animation;


    @property (nonatomic) BOOL screenControlsHidden;
    @property (nonatomic) BOOL moreHidden;
@end
