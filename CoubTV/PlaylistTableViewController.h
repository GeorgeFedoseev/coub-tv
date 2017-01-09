//
//  PlaylistTableViewController.h
//  CoubTV
//
//  Created by George on 2/8/14.
//  Copyright (c) 2014 George. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlaylistTableViewController : UITableViewController
    @property (nonatomic, strong) NSMutableArray *currentPlaylist;
    @property long playlistPointer;
    @property BOOL loadingItems;
@end
