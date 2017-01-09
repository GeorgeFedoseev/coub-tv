//
//  MainViewController.m
//  CoubTV
//
//  Created by George on 2/4/14.
//  Copyright (c) 2014 George. All rights reserved.
//

#import "MainViewController.h"
#import "HTMLParser.h"
#import "Reachability.h"





@interface MainViewController ()
   

    @property (nonatomic) NSInteger currentPage;
    @property (nonatomic, strong) NSString *currentChannel;
    @property (nonatomic, strong) NSString *currentSearchKeywords;
    @property BOOL playlistLoadMoreAvailable;
    @property BOOL icloudAccess;

    
@end





@implementation MainViewController


+ (BOOL) isNetworkAvailable
{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    if (networkStatus == NotReachable) {
        return NO;
    }
    return YES;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.137 Safari/537.36", @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        
        
        
        // ICLOUD
        NSURL *ubiq = [[NSFileManager defaultManager]
                       URLForUbiquityContainerIdentifier:nil];
        if (ubiq) {
            self.icloudAccess = YES;
            // TODO: Load document...
        } else {
            self.icloudAccess = NO;
            NSLog(@"No iCloud access");
        }
        
        // load user settings if exist
        
        if(self.icloudAccess){
            //  Observer to catch changes from iCloud
            NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(icloudStoreDidChange:)
                                                         name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                       object:store];
            
            [store synchronize];
            
            // get icloud user data
            
            
            self.icloudUserData = [[NSKeyedUnarchiver unarchiveObjectWithData:[[NSUbiquitousKeyValueStore defaultStore] objectForKey:@"userData"]]
                                    mutableCopy];
            
            //self.icloudUserData = [[[NSUbiquitousKeyValueStore defaultStore] objectForKey:@"userData"] mutableCopy];
            
        }
        
        if(!self.icloudUserData){
            NSLog(@"No userdata in iCloud. Init it.");
            self.icloudUserData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                   [[NSMutableArray alloc] init], @"favourited_coubs",
                                   @"0", @"channels_and_search_unlocked",
                                   nil
                                   ];
            [[NSUbiquitousKeyValueStore defaultStore] setObject:self.icloudUserData forKey:@"userData"];
        }
        
        
        
        // LOCAL USER DATA
        self.localUserData = [[[NSUserDefaults standardUserDefaults] objectForKey:@"userData"] mutableCopy];
        if(!self.localUserData){
            NSLog(@"No userdata in local staorage. Init it.");
            self.localUserData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                  @"0", @"channels_and_search_unlocked",
                                  @"", @"last_search_keywords",
                                  @"1", @"last_mode",
                                  nil
                                  ];
            [[NSUserDefaults standardUserDefaults] setObject:self.localUserData forKey:@"userData"];
        }
        
        
        self.currentPlaylist = [[NSMutableArray alloc] init];
        
        UIImageView *darkRoom = [[UIImageView alloc]
                                 initWithImage:[UIImage imageNamed:@"darkroom2.jpg"]];
        darkRoom.frame = CGRectMake(0, 0, 1024, 768);
        [self.view addSubview:darkRoom];
        
        
        UIView *blackView = [[UIView alloc] initWithFrame:CGRectMake(115, 115+30-40, 610, 480)];
        [blackView setBackgroundColor:[UIColor blackColor]];
        [self.view addSubview:blackView];
        
        self.screen = [[ScreenViewController alloc] init];
        [self addChildViewController:self.screen];
        [self.view addSubview:self.screen.view];
        
        
        self.tvBox = [[TVBoxViewController alloc] init];
        [self addChildViewController:self.tvBox];
        [self.view addSubview:self.tvBox.view];
        
        
    }
    return self;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // iOS 7
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    } else {
        // iOS 6
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    
    
    
   
    
    // respond to tvbox controls
    [[NSNotificationCenter defaultCenter]
                 addObserver:self selector:@selector(nextVideoObserver:)
                 name:@"next" object:nil];
    [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(previousVideoObserver:)
         name:@"previous" object:nil];
    [[NSNotificationCenter defaultCenter]
                 addObserver:self selector:@selector(modeChangeObserver:)
                 name:@"modeChange" object:nil];
    [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(channelChangeObserver:)
         name:@"channelChange" object:nil];
    [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(searchboxSearchObserver:)
         name:@"searchboxSearch" object:nil];
    [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(playlistWantsMoreCoubs:)
         name:@"loadMoreCoubs" object:nil];
    [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(playCoubNumberObserver:)
         name:@"playCoubNumber" object:nil];
    
    [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(reloadCoubObserver:)
         name:@"reloadCoub" object:nil];

}


// FOR ICLOUD SYNC
- (BOOL) saveIcloudUserDataForKey: (NSString *) key value: (id) value
{
    if(!self.icloudAccess)
        return NO;
    [self.icloudUserData setObject:value forKey:key];
    [[NSUbiquitousKeyValueStore defaultStore] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.icloudUserData] forKey:@"userData"];
    return YES;
}

- (id) getIcloudUserDataForKey: (NSString *) key
{
    if(!self.icloudAccess)
        return nil;
    return [self.icloudUserData objectForKey:key];
}

- (void) icloudStoreDidChange: (NSNotification *) notification
{
    //self.icloudUserData = [[[NSUbiquitousKeyValueStore defaultStore] objectForKey:@"userData"] mutableCopy];
    self.icloudUserData = [[NSKeyedUnarchiver unarchiveObjectWithData:[[NSUbiquitousKeyValueStore defaultStore] objectForKey:@"userData"]]
                           mutableCopy];
}

// LOCAL USER DATA
- (void) saveLocalUserDataForKey: (NSString *) key value: (id) value
{
    [self.localUserData setObject:value forKey:key];
    [[NSUserDefaults standardUserDefaults] setObject:self.localUserData forKey:@"userData"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id) getLocalUserDataForKey: (NSString *) key
{
    return [self.localUserData objectForKey:key];
}


- (void) viewDidAppear:(BOOL)animated
{
    [self.screen setState:CoubTVStateIdle];
    
    // setup snow
    [self.screen setupSnow];
    
    
    
    // GO!
    [self.tvBox setMode:TvBoxModeHot];

}



- (void) playCoubNumberObserver: (NSNotification *) notification
{
    long index = (long)[(NSString *)notification.object longLongValue];
    [self playCoubNumber:index];
}

- (void) playCoubNumber: (long) index
{
    [self.screen showSnow];
    NSLog(@"wants coub number %li", index);
    if(index >=0 && index < self.currentPlaylist.count){
        self.playlistPointer = self.tvBox.playlistTableViewController.playlistPointer = index;
        self.screen.queuePointer = index;
        [self.tvBox.playlistTableViewController.tableView reloadData];
        [self.screen playNextInQueue];
    }else{
        NSLog(@"ERROR: no such coub index %li", index);
    }
    
}

- (void) reloadCoubObserver: (id) sender
{
    [self reloadCurrentCoub];
}

- (void) reloadCurrentCoub
{
    [self playCoubNumber:self.playlistPointer];
}

- (void) searchboxSearchObserver: (NSNotification *) notification
{
    
    
    NSString *keywords = (NSString *) notification.object;
    self.currentSearchKeywords = keywords;
    
    [self saveLocalUserDataForKey:@"last_search_keywords" value:keywords];
    // load coubs by keywords
    NSLog(@"Load coubs by keywords: %@", keywords);
    self.tvBox.mode = TvBoxModeSearch;
    
}


- (void) channelChangeObserver: (NSNotification *) notification
{
    NSDictionary *channelInfo = (NSDictionary *) notification.object;
    
    [self.tvBox setMode:TvBoxModeChannel];
    
    [self.screen showSnow];
    
    self.tvBox.channelsTableViewController.currentChannel = self.currentChannel = [channelInfo objectForKey:@"link"];
    [self.tvBox.channelsTableViewController.tableView reloadData];
    [self.tvBox hideChannelSelectWithAnimation:YES];
    
    [self.tvBox showScreenControlsHide:YES];
    [self.tvBox displayMessage:[channelInfo objectForKey:@"name"] hide:YES];
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.1);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){

        // clear playlists
        [self clearPlaylists];
        
        NSArray *coubs = [self loadMoreVideos];
        [self addCoubsToPlaylists:coubs];
        [self.screen playNextInQueue];
    });
    
}

- (void) modeChangeObserver: (NSNotification *) notification
{
    
    if(![MainViewController isNetworkAvailable]){
        [self.tvBox showScreenControlsHide:NO];
        [self.tvBox displayMessage:@"Check network connection" hide:NO];
        return;
    }
    
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.1);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        TvBoxMode mode = [[((NSDictionary *)notification.object) objectForKey:@"mode"] intValue];
        
    
        
    [self.tvBox hideChannelSelectWithAnimation:YES];
        
    [self clearPlaylists];
    [self.tvBox.playlistTableViewController.tableView reloadData];
        
    if(self.tvBox.mode != TvBoxModeSearch){
        [self.tvBox hideSearchboxWithAnimation:YES];
    }else{
        [self.tvBox showPlaylistWithAnimation:YES];
    }
        
        if(mode < 3){
            [self.screen setState:CoubTVStateIdle];
            [self.screen showSnow];
            
            if(self.tvBox.mode == TvBoxModeFavourites){
                NSArray *coubs = [self loadMoreVideos];
                [self addCoubsToPlaylists:coubs];
                //[self.tvBox showPlaylistWithAnimation:YES];
                [self.screen playNextInQueue];
                if(!coubs.count){
                   [self.tvBox showScreenControlsHide:NO];
                   [self.tvBox displayMessage:@"No favourited coubs" hide:NO];
                }
            }else{
                
                // random or hot or favourites
                // load first playlist in queue
                NSArray *coubs = [self loadMoreVideos];
                [self addCoubsToPlaylists:coubs];
                // and play it
                [self.screen playNextInQueue];
            }
            
          
            
        }else{
            if(mode == TvBoxModeChannel){
                [self.screen showSnow];
                [self.tvBox hideSearchboxWithAnimation:YES];
                self.tvBox.channelsTableViewController.currentChannel = self.currentChannel;
                [self.tvBox.channelsTableViewController.tableView reloadData];
            }else if(mode == TvBoxModeSearch){
                [self.tvBox.channelsTableViewController.tableView reloadData];
            }
        }
    });
}

- (void) addCoubsToPlaylists: (NSArray *) coubs
{
    // filter coubs
    NSMutableArray *allowedCoubs = [[NSMutableArray alloc] init];
    for(NSDictionary *coub in coubs){
        if(self.tvBox.mode == TvBoxModeSearch || self.tvBox.mode == TvBoxModeFavourites){
            allowedCoubs = [coubs mutableCopy];
        }else{
            if([coub objectForKey:@"global_safe"] != [NSNull null]){
                NSLog(@"a_r: %@ safe: %@", [coub objectForKey:@"age_restricted"], [coub objectForKey:@"global_safe"]);
                if(![[coub objectForKey:@"age_restricted"] boolValue] && [[coub objectForKey:@"global_safe"] boolValue]){
                    NSLog(@"Video is safe. Accepted");
                    [allowedCoubs addObject:coub];
                }
            }else{
                NSLog(@"No global_safe param");
            }
        }
    }
    
    [self.currentPlaylist addObjectsFromArray:allowedCoubs];
    [self.screen addCoubsToQueue:allowedCoubs];
    [self.tvBox.playlistTableViewController.currentPlaylist addObjectsFromArray:allowedCoubs];
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.5);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        [self.tvBox.playlistTableViewController.tableView reloadData];
        
        if(allowedCoubs.count < 2 && self.playlistLoadMoreAvailable){
            NSLog(@"TO FEW COUBS IN PLAYLIST");
            [self playlistWantsMoreCoubs:nil];
        }else{
            //[self.screen playNextInQueue];
            //[self.screen playPreviousInQueue];
        }
        
    });
   
}

- (void) clearPlaylists
{
    self.playlistPointer = self.tvBox.playlistTableViewController.playlistPointer = 0;
    // clear playlists
    self.currentPlaylist =  [[NSMutableArray alloc] init];
    self.tvBox.playlistTableViewController.currentPlaylist = [[NSMutableArray alloc] init];
    [self.screen clearQueue];
    // reset page
    self.currentPage = 1;
    self.playlistLoadMoreAvailable = YES;
}

- (void) playlistWantsMoreCoubs: (NSNotification *) notification
{
    if(!self.playlistLoadMoreAvailable){
        NSLog(@"no more coubs available to load");
        return;
    }
    
    if(![MainViewController isNetworkAvailable]){
        [self.tvBox showScreenControlsHide:NO];
        [self.tvBox displayMessage:@"Check network connection" hide:NO];
        return;
    }
        
        
/*    if(self.currentPage > 1 && !self.tvBox.playlistTableViewController.currentPlaylist.count)
        return;*/
    
    NSLog(@"Playlist wants more coubs");
    dispatch_queue_t thread = dispatch_queue_create("your dispatch name", NULL);
    dispatch_async(thread, ^{
        
        self.tvBox.playlistTableViewController.loadingItems = YES;
        [self.tvBox.playlistTableViewController.tableView reloadData];
        
        
        NSArray *coubs = [self loadMoreVideos];
        [self addCoubsToPlaylists:coubs];
        
        
        self.tvBox.playlistTableViewController.loadingItems = NO;
        
        
    });
    
}

- (void) previousVideoObserver: (NSNotification *) notification{
    NSLog(@"wants prev");
    
    if(![MainViewController isNetworkAvailable]){
        [self.tvBox showScreenControlsHide:NO];
        [self.tvBox displayMessage:@"Check network connection" hide:NO];
        return;
    }
    
    if(self.playlistPointer==0)
        return;
    
    if(self.screen.state == CoubTVStateIdle || self.screen.state == CoubTVStatePlaying)
    {
        [self.screen setState:CoubTVStateLoading];
        NSLog(@"GETS prev");
        [self.screen showSnow];
        
        
        if([self.screen playPreviousInQueue]){
            self.tvBox.playlistTableViewController.playlistPointer--;
            self.playlistPointer--;
        }
        
        
        [self.tvBox.playlistTableViewController.tableView reloadData];
        
        // scroll to next video
        if(self.tvBox.playlistBox.hidden){
            [self.tvBox.playlistTableViewController.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.playlistPointer inSection:0]
                                                                    atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        }
    }

}

- (void) nextVideoObserver: (NSNotification *) notification
{
    NSLog(@"wants next");
    
    if(![MainViewController isNetworkAvailable]){
        [self.tvBox showScreenControlsHide:NO];
        [self.tvBox displayMessage:@"Check network connection" hide:NO];
        return;
    }
    
    
    if(self.screen.state == CoubTVStateIdle || self.screen.state == CoubTVStatePlaying)
    {
        [self.screen setState:CoubTVStateLoading];
        NSLog(@"GETS next");
        [self.screen showSnow];
        
        
        if(![self.screen playNextInQueue]){
            if(self.playlistLoadMoreAvailable){
                NSArray *coubs = [self loadMoreVideos];
                [self addCoubsToPlaylists:coubs];
                self.tvBox.playlistTableViewController.playlistPointer++;
                self.playlistPointer++;
                [self.screen playNextInQueue];
            }else{
                [self.tvBox showScreenControlsHide:NO];
                [self.tvBox displayMessage:@"No more coubs in this playlist" hide:NO];
            }
        }else{
            self.tvBox.playlistTableViewController.playlistPointer++;
            self.playlistPointer++;
        }
        
        
        
        [self.tvBox.playlistTableViewController.tableView reloadData];
        
        // scroll to next video
        if(self.tvBox.playlistBox.hidden){
            [self.tvBox.playlistTableViewController.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.playlistPointer inSection:0]
                                                                    atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        }
    }
}




- (NSArray *) loadMoreVideos
{
    
    if(![MainViewController isNetworkAvailable]){
        //[self.tvBox showScreenControlsHide:NO];
        [self.tvBox displayMessage:@"Check network connection" hide:NO];
        return nil;
    }
    
    
    if (self.tvBox.mode == TvBoxModeRandom) {
        NSArray *randomCoubs = [self getRandomCoubsWithPage:self.currentPage++];
        return randomCoubs;
    }else if(self.tvBox.mode == TvBoxModeHot){
        NSArray *hotCoubs = [self getHotCoubsWithPage:self.currentPage++];
        return hotCoubs;
    }else if(self.tvBox.mode == TvBoxModeChannel){
        NSArray *channelCoubs = [self getChannelCoubs: self.currentChannel withPage:self.currentPage++];
        return channelCoubs;
    }else if(self.tvBox.mode == TvBoxModeSearch){
        NSArray *searchCoubs = [self getSearchCoubs: self.currentSearchKeywords withPage:self.currentPage++];
        return searchCoubs;
    }else if(self.tvBox.mode == TvBoxModeFavourites){
        //self.playlistLoadMoreAvailable = NO;
        NSArray *allPermalinks = [[[self getIcloudUserDataForKey:@"favourited_coubs"] reverseObjectEnumerator] allObjects];
        NSMutableArray *coubs = [[NSMutableArray alloc] init];
        
        long length = 5;
        if(self.currentPage > ((float)allPermalinks.count/5)){
            length = allPermalinks.count - (self.currentPage-1)*5;
            self.playlistLoadMoreAvailable = NO;
        }
        
        NSArray *currentPermalinks = [allPermalinks subarrayWithRange: NSMakeRange(0+(self.currentPage-1)*5, length)];
        
        for(NSString *coubId in currentPermalinks){
            NSLog(@"Favourite coub %@", [NSString stringWithFormat:@"http://coub.com/embed/%@", coubId]);
            NSDictionary *coub = [self getCoubByUrl:[NSString stringWithFormat:@"http://coub.com/embed/%@", coubId]];
            if(coub)
                [coubs addObject:coub];
        }
        
        self.currentPage++;        
        return coubs;
    }else{
        NSLog(@"Error: Undefined tvbox mode");
        return nil;
    }
}



- (NSArray *) getSearchCoubs: (NSString *) keywords withPage: (NSInteger) page
{
    return [self getCoubsByUrl:[NSString stringWithFormat: @"http://coub.com/api/v1/search?q=%@&sort_by=relevance&page=%li",
                                [keywords stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                page]];
}

- (NSArray *) getChannelCoubs: (NSString *) channel withPage: (NSInteger) page
{
    return [self getCoubsByUrl:[NSString stringWithFormat:@"http://coub.com/api/v1/timeline/explore/%@?page=%li", channel, (long)page]];
}

- (NSArray *) getHotCoubsWithPage: (NSInteger) page
{
    return [self getCoubsByUrl:[NSString stringWithFormat:@"http://coub.com/api/v1/timeline/explore/hot?page=%li", page]];
}

- (NSArray *) getRandomCoubsWithPage: (NSInteger) page
{
    return [self getCoubsByUrl:[NSString stringWithFormat:@"http://coub.com/api/v1/timeline/explore/random?page=%li", page]];
}

- (NSArray *) getCoubsByUrl: (NSString *) url
{
    NSLog(@"Get coubs page with url: %@",url);
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSError *grabPageError;
    NSData *jsonData = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:&grabPageError];
    
    if(grabPageError){
        NSLog(@"Error when loading coubs page: %@", grabPageError.localizedDescription);
        return nil;
    }
    
    NSError *jsonError;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];
    if(jsonError){
        NSLog(@"Error when parsing coub json: %@", jsonError.userInfo);
        return nil;
    }
    
    long totalPages = [[dict objectForKey:@"total_pages"] longValue];
    self.playlistLoadMoreAvailable = (self.currentPage<totalPages);
    
    if(dict.count)
        return ((NSArray *)[dict objectForKey:@"coubs"]);
    
    return nil;
}


- (NSDictionary *) getCoubByUrl: (NSString *) urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithContentsOfURL:url error:&error];
    
    if (error) {
        NSLog(@"Error when parsing webpage: %@", error);
        return nil;
    }
    
    HTMLNode *bodyNode = [parser body];
    HTMLNode *scriptNode = [bodyNode findChildWithAttribute:@"type" matchingName:@"text/json" allowPartial:NO];
    
    if(scriptNode != nil){
        NSError *jsonError;
        
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[scriptNode.contents dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&jsonError];
        
        if(!error){
            return dict;
        }else{
            NSLog(@"Error when parsing json %i", jsonError.code);
        }
    }
    
    return nil;
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
