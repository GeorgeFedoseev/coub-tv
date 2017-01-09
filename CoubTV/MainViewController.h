//
//  MainViewController.h
//  CoubTV
//
//  Created by George on 2/4/14.
//  Copyright (c) 2014 George. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TVBoxViewController.h"
#import "ScreenViewController.h"
#import "TVBoxViewController.h"

@interface MainViewController : UIViewController 
    @property (nonatomic, strong) ScreenViewController *screen;
    @property (nonatomic, strong) TVBoxViewController *tvBox;

    @property (nonatomic, strong) NSMutableArray *currentPlaylist;
    @property long playlistPointer;

    @property (nonatomic, strong) NSMutableDictionary *icloudUserData;
    @property (nonatomic, strong) NSMutableDictionary *localUserData;

    - (BOOL) saveIcloudUserDataForKey: (NSString *) key value: (id) value;
    - (id) getIcloudUserDataForKey: (NSString *) key;
    - (void) saveLocalUserDataForKey: (NSString *) key value: (id) value;
    - (id) getLocalUserDataForKey: (NSString *) key;
    - (void) reloadCurrentCoub;
+ (BOOL) isNetworkAvailable;
    /*
     Icloud User Data structure
        - favourited_coubs (nsdictionary)
        - channels_and_search_unlocked (nsstring)
     */

    /*
     Local User Data
     - last_search_keywords (nsstring)
     - last_mode (nsstring)
     */
@end
