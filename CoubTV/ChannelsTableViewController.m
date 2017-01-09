//
//  ChannelsTableViewController.m
//  CoubTV
//
//  Created by George on 2/7/14.
//  Copyright (c) 2014 George. All rights reserved.
//

#import "ChannelsTableViewController.h"
#import "MainViewController.h"

@interface ChannelsTableViewController ()
    @property (nonatomic, strong) TVBoxViewController *tvBox;
@end

@implementation ChannelsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
        [self.view setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.2]];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.opaque = NO;
        
        self.channels = [NSArray arrayWithObjects:
                         [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"Animation", @"name",
                              @"animation", @"link",
                              nil
                          ],
                         [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"Art & Design", @"name",
                              @"art-design", @"link",
                              nil
                          ],
                         [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"Brands & Products", @"name",
                              @"brands-products", @"link",
                          nil
                          ],
                         [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"Comedy", @"name",
                              @"comedy", @"link",
                          nil
                          ],
                         /*[[NSDictionary alloc] initWithObjectsAndKeys:
                              @"Coub App", @"name",
                              @"coub-app", @"link",
                          nil
                          ],*/
                         [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"Everyday Life", @"name",
                              @"everyday-life", @"link",
                          nil
                          ],
                         [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"Fashion", @"name",
                              @"fashion", @"link",
                          nil
                          ],
                         [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"Gaming", @"name",
                              @"gaming", @"link",
                          nil
                          ],
                         /*[[NSDictionary alloc] initWithObjectsAndKeys:
                              @"Girls", @"name",
                              @"girls", @"link",
                          nil
                          ],*/
                         [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"Movies", @"name",
                              @"movies", @"link",
                          nil
                          ],
                         [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"Music", @"name",
                              @"music", @"link",
                          nil
                          ],
                         [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"Nature", @"name",
                              @"nature", @"link",
                          nil
                          ],
                         [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"Science & Tech", @"name",
                              @"science-tech", @"link",
                          nil
                          ],
                         [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"Sports", @"name",
                              @"sports", @"link",
                          nil
                          ],
                          nil
                         ];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 12;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *channelInfo = self.channels[indexPath.row];
    NSString *channelName = (NSString *)[channelInfo objectForKey:@"name"];
    NSString *channelLink = (NSString *)[channelInfo objectForKey:@"link"];
    
     /*= [tableView dequeueReusableCellWithIdentifier:channelLink]*/;
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:channelLink];
    
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.backgroundColor = [UIColor clearColor];
    UIView *bgColorView = [[UIView alloc] init];
    [bgColorView setBackgroundColor:[UIColor colorWithRed:0 green:0.533 blue:0.8 alpha:.8]];
    [cell setSelectedBackgroundView:bgColorView];
   
    self.tvBox = (TVBoxViewController *)[self parentViewController];
    if((channelLink == self.currentChannel) && (self.tvBox.mode == TvBoxModeChannel)){
        
        cell.backgroundView = bgColorView;
    }
    
    UILabel *label = cell.textLabel;
    label.textColor = [UIColor whiteColor];
    
    label.text = [channelInfo objectForKey:@"name"];    
    return cell;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *channelInfo = self.channels[indexPath.row];
    NSString *channelName = (NSString *)[channelInfo objectForKey:@"name"];
    NSString *channelLink = (NSString *)[channelInfo objectForKey:@"link"];
    
    NSLog(@"TABLE SELECT!");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"channelChange" object:channelInfo];
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
