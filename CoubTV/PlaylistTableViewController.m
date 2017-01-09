//
//  PlaylistTableViewController.m
//  CoubTV
//
//  Created by George on 2/8/14.
//  Copyright (c) 2014 George. All rights reserved.
//

#import "PlaylistTableViewController.h"
#import "TVBoxViewController.h"
#import "UIImageView+WebCache.h"

@interface PlaylistTableViewController ()
    @property (nonatomic, strong) TVBoxViewController *tvBox;
@end

@implementation PlaylistTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        [self.view setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.5]];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.opaque = NO;
        self.loadingItems = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tvBox = (TVBoxViewController *)[self parentViewController];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.loadingItems)
        return (self.currentPlaylist?self.currentPlaylist.count:0)+1;
    if(self.currentPlaylist.count)
        return self.currentPlaylist.count;
    return 1; // to say that nothing
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];*/
    long index = indexPath.row;
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.backgroundColor = [UIColor clearColor];
    UIView *bgColorView = [[UIView alloc] init];
    [bgColorView setBackgroundColor:[UIColor colorWithRed:0 green:0.533 blue:0.8 alpha:.8]];
    [cell setSelectedBackgroundView:bgColorView];
    
    UILabel *label = cell.textLabel;
    label.textColor = [UIColor whiteColor];
    
    
    if(self.currentPlaylist.count){
        if(index < self.currentPlaylist.count){
            if(self.playlistPointer == index){
                [cell setBackgroundColor:[UIColor colorWithRed:0 green:0.533 blue:0.8 alpha:.8]];
            }
            
            NSDictionary *coub = self.currentPlaylist[index];
            NSString *title = [coub objectForKey:@"title"];
            NSURL *pictureURL = [NSURL URLWithString:[coub objectForKey:@"small_picture"]];
            NSDictionary *channel = [coub objectForKey:@"channel"];
            NSString *channelTitle = [channel objectForKey:@"title"];
            NSURL *channelPictureURL = [NSURL URLWithString:
                                 [[
                                    [channel objectForKey:@"avatar_versions"] objectForKey:@"template"]
                                  stringByReplacingOccurrencesOfString:@"%{version}" withString:@"tiny"] ];
            
            
            long likes_count = [[coub objectForKey:@"likes_count"] longValue];
            long recoubs_count = [[coub objectForKey:@"recoubs_count"] longValue];
            
            // coub picture
            UIImageView *coubPicture = [[UIImageView alloc] init];
            [coubPicture sd_setImageWithURL:pictureURL placeholderImage:[UIImage imageNamed:@"image_placeholder.png"]];
            [coubPicture setFrame:CGRectMake(20, 20, 80, 60)];
            coubPicture.layer.borderColor = [UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1].CGColor;
            coubPicture.layer.borderWidth = 5.0;
            coubPicture.layer.shadowOffset = CGSizeMake(3, 3);
            coubPicture.layer.shadowOpacity = .3;
            coubPicture.layer.shadowPath = [UIBezierPath bezierPathWithRect:coubPicture.bounds].CGPath;
            coubPicture.layer.masksToBounds = NO;
            [cell addSubview:coubPicture];
            
            
            
            // coub title
            UILabel *coubTitle = [[UILabel alloc] initWithFrame:CGRectMake(120, 20, 0, 0)];
            coubTitle.text = title;
            coubTitle.textColor = [UIColor whiteColor];
            coubTitle.font = [UIFont fontWithName:@"Helvetica" size:18];
            [coubTitle sizeToFit];
            coubTitle.frame = CGRectMake(coubTitle.frame.origin.x, coubTitle.frame.origin.y, 280, coubTitle.frame.size.height);
            [cell addSubview:coubTitle];
            
            // author picture
            UIImageView *authorPicture = [[UIImageView alloc] init];
            [authorPicture sd_setImageWithURL:channelPictureURL placeholderImage:[UIImage imageNamed:@"image_placeholder.png"]];
            [authorPicture setFrame:CGRectMake(120, 50, 20, 20)];
            [cell addSubview:authorPicture];
            
            // author name
            UILabel *authorName = [[UILabel alloc] initWithFrame:CGRectMake(150, 58, 0, 0)];
            authorName.text = channelTitle;
            authorName.textColor = [UIColor whiteColor];
            authorName.font = [UIFont fontWithName:@"Helvetica" size:12];
            [authorName sizeToFit];
            authorName.frame = CGRectMake(authorName.frame.origin.x, authorName.frame.origin.y, 280, authorName.frame.size.height);
            [cell addSubview:authorName];
            
            // likes and recoubs
            UILabel *likesCount = [[UILabel alloc] initWithFrame:CGRectMake(300, 48, 100, 15)];
            likesCount.text = [NSString stringWithFormat:@"%li likes", likes_count];
            likesCount.textColor = [UIColor whiteColor];
            likesCount.textAlignment = NSTextAlignmentRight;
            likesCount.font = [UIFont fontWithName:@"Helvetica" size:12];
            //[likesCount sizeToFit];
            [cell addSubview:likesCount];
            
            UILabel *recoubsCount = [[UILabel alloc] initWithFrame:CGRectMake(300, 63, 100, 15)];
            recoubsCount.text = [NSString stringWithFormat:@"%li recoubs", recoubs_count];
            recoubsCount.textColor = [UIColor whiteColor];
            recoubsCount.textAlignment = NSTextAlignmentRight;
            recoubsCount.font = [UIFont fontWithName:@"Helvetica" size:12];
            //[recoubsCount sizeToFit];
            [cell addSubview:recoubsCount];
        }
    }else{
        if(!self.loadingItems){
            label.text = @"no coubs";
            label.font = [UIFont fontWithName:@"Helvetica" size:30];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.backgroundView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:.3];
            cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:.3];
        }
    }
    
   
    
    NSLog(@"Loading items: %@ Playlist count: %li Index: %i", self.loadingItems?@"YES":@"NO", self.currentPlaylist.count, index);
    if(self.loadingItems){
        NSLog(@"loading items");
        if(index == self.currentPlaylist.count){
            NSLog(@"ADD ACTIVITY VIEW");
            UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
            activityView.center = CGPointMake(210, 50);
            activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
            [cell addSubview:activityView];
            [cell bringSubviewToFront:activityView];
            [activityView stopAnimating];
            [activityView startAnimating];
            
        }
    }else{        
        // load more if reached end
        NSLog(@"load more cause we reached end of playlist");
        if(index == self.currentPlaylist.count-1 || (!self.currentPlaylist.count)){
            NSLog(@"ok send notification to load more");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadMoreCoubs" object:nil];
        }
    }
    
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    long index = indexPath.row;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"playCoubNumber" object:[NSString stringWithFormat:@"%li", index]];
    
    
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
