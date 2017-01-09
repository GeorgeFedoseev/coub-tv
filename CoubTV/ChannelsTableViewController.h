//
//  ChannelsTableViewController.h
//  CoubTV
//
//  Created by George on 2/7/14.
//  Copyright (c) 2014 George. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChannelsTableViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>
    @property (nonatomic, strong) NSArray *channels;
    @property (nonatomic, strong) NSString *currentChannel;
@end
