
//
//  MainViewController.m
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "MainViewController.h"
#import "HootGroupCell.h"
#import "AFNetworking.h"
#import "AFHTTPRequestOperation.h"
#import "HootLobby.h"
#import "SummaryViewController.h"
#import <FacebookSDK/FacebookSDK.h>



static NSString * const BaseURLString = @"http://54.215.240.73:3000/";

@interface MainViewController () {
    NSMutableArray *lobbies;
    NSMutableArray *hostImages;
    HootLobby *chosenHoot;
    __block BOOL isAdmin;
    
    
    __block NSString *facebookID;
}

@end

@implementation MainViewController

typedef enum accessType {
    ADMIN_FIRST,
    ADMIN_RETURNS,
    FRIEND_FIRST,
    FRIEND_RETURNS
} accessType;


//NEed to modify different heights of the view because it doesnt work well in all devices
-(void)addImageOnTopOfTheNavigationBar {
    _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"owl_try_2.png"]];
    _imageView.frame = CGRectMake(self.navigationController.navigationBar.frame.origin.x + 10.0, self.navigationController.navigationBar.frame.origin.y, self.navigationController.navigationBar.frame.size.height * (3.0/2.0), self.navigationController.navigationBar.frame.size.height * (3.0/2.0) + [self addSizeforDevice]); //set the proper frame here
    [self.navigationController.view addSubview:_imageView];
}

-(float)addSizeforDevice{
    NSLog(@"%@",[[UIDevice currentDevice] name]);
    return 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [_coverIndicator startAnimating];
    _coverIndicator.color = [UIColor colorWithRed:240.0/255.0 green:110.0/255.0 blue:72.0/255.0 alpha:1.0];
    //[self clearAllGroups];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    //http://stackoverflow.com/questions/12497940/uirefreshcontrol-without-uitableviewcontroller
    /*UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(loadGroups) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];*/
    
    chosenHoot = [HootLobby new];
    //[self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    lobbies = [NSMutableArray new];
    hostImages = [NSMutableArray new];
    
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = _tableView;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(loadGroups) forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = self.refreshControl;
    self.refreshControl.tintColor = [UIColor colorWithRed:(254/255.0) green:(153/255.0) blue:(0/255.0) alpha:1];

    [self loadGroups];
}


-(void) loadGroups {
    [lobbies removeAllObjects];
    _coverView.hidden = NO;
    _tableView.allowsSelection = NO;
    [_coverIndicator startAnimating];
    [self.refreshControl endRefreshing];
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // Success! Include your code to handle the results here
            NSLog(@"user info: %@", result);
            facebookID = [NSString stringWithFormat:@"%@", result[@"id"]];
            [self getGroupsWithID:facebookID];
        } else {
            // An error occurred, we need to handle the error
            // See: https://developers.facebook.com/docs/ios/errors
        }
    }];
}



- (void)viewWillDisappear:(BOOL)animated{
    NSLog(@"BYEBYE");
    [_imageView removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated{
    self.navigationItem.title = @"Who's Hungry?";

    [self addImageOnTopOfTheNavigationBar];
}

-(void) clearAllGroups {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:[NSString stringWithFormat:@"%@apis/initialize_db", BaseURLString] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseData) {
        NSLog(@"cleared the data base: %@", responseData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

-(void) getGroupsWithID:(NSString *) fbid {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{@"user_id": fbid};
    [manager POST:[NSString stringWithFormat:@"%@apis/show_lobby_friend", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseData) {
        NSLog(@"JSON: %@", responseData);
        NSDictionary *data = responseData;
        if (data != nil) {
            NSArray *groups = data[@"lobbies"];
            NSLog(@"found sooooo many groups: %li", (unsigned long)groups.count);
            if (groups.count == 0) {
                [self.coverIndicator stopAnimating];
                self.coverView.hidden = YES;
            }
            for (int i = 0; i < groups.count; i++) {
                HootLobby *lobby = [[HootLobby alloc] init];
                NSLog(@"gorups object ids: %@", [groups objectAtIndex:i]);
                NSNumber *facebookId = [groups objectAtIndex:i][@"admin_user"];
                NSString *facebookName = [groups objectAtIndex:i][@"admin_name"];
                NSString *facebookPicture = [groups objectAtIndex:i][@"admin_picture"];
                
                NSString *expectedDateStr = [groups objectAtIndex:i][@"expiration_time"];
                NSDateFormatter *dateFormat = [NSDateFormatter new];
                [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.000Z"];
                NSDate *expectedDate = [dateFormat dateFromString:expectedDateStr];
                
                NSString *voteType = [groups objectAtIndex:i][@"vote_type"];
                NSNumber *voteid = [groups objectAtIndex:i][@"vote_id"];
                NSNumber *groupid = [groups objectAtIndex:i][@"group_id"];
                NSString *winnerRestID = [groups objectAtIndex:i][@"winner_restaurant_id"];
                
                UIImage *image;
                if (![facebookPicture isEqual:[NSNull null]]) {
                    NSURL *url = [NSURL URLWithString:facebookPicture];
                    NSData *data = [NSData dataWithContentsOfURL:url];
                    image = [UIImage imageWithData:data];
                }
                else
                    image = [UIImage imageNamed:@"bae2.jpg"];
                [hostImages addObject:image];
                
                lobby.facebookPic = facebookPicture;
                lobby.facebookId = [NSString stringWithFormat:@"%@",facebookId];
                lobby.facebookName = facebookName;
                lobby.winnerRestID = winnerRestID;
                lobby.expirationTime = expectedDate;
                lobby.voteType = voteType;
                lobby.voteid = voteid;
                lobby.groupid = groupid;
                [lobbies addObject:lobby];
                
                
                NSSortDescriptor *newestOnTop = [[NSSortDescriptor alloc] initWithKey:@"voteid" ascending:NO];
                [lobbies sortUsingDescriptors:[NSArray arrayWithObject:newestOnTop]];
                
                [self.tableView reloadData];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

#pragma mark - Table View methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return lobbies.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (lobbies) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        return 1;
        
    } else {
        // Display a message when the table is empty
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        
        messageLabel.text = @"No data is currently available. Please pull down to refresh.";
        messageLabel.textColor = [UIColor blackColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont fontWithName:@"Palatino-Italic" size:20];
        [messageLabel sizeToFit];
        
        self.tableView.backgroundView = messageLabel;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 200.0;
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"HootGroupCell";
    
    HootGroupCell *cell = (HootGroupCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"HootGroupCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    if (lobbies.count > 0){
        HootLobby *chosenLobby = (HootLobby *)lobbies[indexPath.row];
        NSLog(@"chosen lobby is :::::: %@", chosenLobby);
        //winner restaurant pic
        if ([chosenLobby.voteType isEqualToString:@"lunch"]){
            cell.backgroundImage.image = [UIImage imageNamed:@"01_lunch_photograph.jpg"];
        }
        else if ([chosenLobby.voteType isEqualToString:@"dinner"]){
            cell.backgroundImage.image = [UIImage imageNamed:@"01_dinner_photograph.jpg"];
        }
        else if ([chosenLobby.voteType isEqualToString:@"cafe"]){
            cell.backgroundImage.image = [UIImage imageNamed:@"01_coffee_photograph.jpg"];
        }
        else{
            cell.backgroundImage.image = [UIImage imageNamed:@"01_drinks_photograph.jpg"];
        }
        //when isn't working :(
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"hh:mm"];
        NSString *formattedWhenTime = [dateFormatter stringFromDate:chosenLobby.expirationTime];
        cell.whenLabel.text = [NSString stringWithFormat:@"%@", formattedWhenTime];
        
        cell.whereLabel.text = chosenLobby.winnerRestName;
        if (chosenLobby.voteType == nil)
            chosenLobby.voteType = @"";
        cell.titleLabel.text = [NSString stringWithFormat:@"%@", chosenLobby.voteType];
        
        //If user is the Admin then the subtitle will say something different
        if ([chosenLobby.facebookId isEqualToString:facebookID]) {
            cell.subtitleLabel.text = [NSString stringWithFormat:@"Your friends have been notified"];
        }
        else{
            cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ invited you", chosenLobby.facebookName];
            
        }
        cell.friendsImage.image = hostImages[indexPath.row];
        cell.friendsImage.layer.cornerRadius = cell.friendsImage.image.size.width / 2 - 5.0;
        cell.friendsImage.clipsToBounds = YES;
        cell.friendsImage.layer.borderWidth = 2.0f;
        cell.friendsImage.layer.borderColor = [UIColor colorWithRed:134.0/255.0 green:191.0/255.0 blue:163.0/255.0 alpha:1.0].CGColor;
        //cell.hostImage.image = hostImages[indexPath.row];
    }
 
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"index path is: %@", lobbies[indexPath.row]);
    chosenHoot = (HootLobby *)lobbies[indexPath.row];
    
    //checks if admin
    if ([chosenHoot.facebookId isEqualToString:facebookID]) {
        isAdmin = YES;
    }
    
    NSMutableArray *placesIdArray = [NSMutableArray new];
    NSMutableArray *placesNamesArray = [NSMutableArray new];
    NSMutableArray *placesPicsArray = [NSMutableArray new];
    NSMutableArray *placesXArray = [NSMutableArray new];
    NSMutableArray *placesYArray = [NSMutableArray new];
    NSMutableArray *placesCountArray = [NSMutableArray new];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{@"vote_id": chosenHoot.voteid};
    [manager POST:[NSString stringWithFormat:@"%@apis/show_single_vote", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSDictionary *results = (NSDictionary *)responseObject;
        id results = responseObject;
        NSArray *choices = results[@"choices"];
        for (int i = 0; i < choices.count; i++) {
            NSDictionary *currentRest = choices[i];
            [placesIdArray addObject:currentRest[@"restaurant_id"]];
            [placesNamesArray addObject:currentRest[@"restaurant_name"]];
            [placesPicsArray addObject:currentRest[@"restaurant_picture"]];
            if (![currentRest[@"restaurant_location_x"] isEqual:[NSNull null]])
                [placesXArray addObject:currentRest[@"restaurant_location_x"]];
            else
                [placesXArray addObject:@"NONE"];
            
            if (![currentRest[@"restaurant_location_y"] isEqual:[NSNull null]]) {
                [placesYArray addObject:currentRest[@"restaurant_location_y"]];
            } else {
                [placesYArray addObject:@"NONE"];
            }

            [placesCountArray addObject:currentRest[@"count"]];
        }
        
        chosenHoot.placesIdArray = placesIdArray;
        chosenHoot.placesNamesArray = placesNamesArray;
        chosenHoot.placesPicsArray = placesPicsArray;
        chosenHoot.placesXArray = placesXArray;
        chosenHoot.placesYArray = placesYArray;
        
        [self performSegueWithIdentifier:@"maintosummary" sender:self];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];

    
    NSLog(@"chosen hoot chosen is :  %@", chosenHoot);
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        NSLog(@"END OF LOADING");
        _tableView.allowsSelection = YES;
        [_coverIndicator stopAnimating];
        [UIView animateWithDuration:0.75 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            _coverView.alpha = 0.0;
        } completion:^(BOOL finished) {
            NSLog(@"DONE!");
            _coverView.hidden = YES;

        }];

        //end of loading
        //for example [activityIndicator stopAnimating];
    }
}

#pragma mark - Segue methods

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"maintosummary"])
    {
        SummaryViewController *vc = [segue destinationViewController];
        vc.loaded = YES;
        vc.isFromMain = YES;
        vc.currentLobby = chosenHoot;
        if (isAdmin) {
            vc.accessType = ADMIN_RETURNS;
        } else {
            NSArray *votedArr = [[NSUserDefaults standardUserDefaults] objectForKey:[chosenHoot.groupid stringValue]];
            if (votedArr) {
                vc.accessType = FRIEND_RETURNS;
            }
            else {
                vc.accessType = FRIEND_FIRST;
            }
        }
    }
}

- (void)panGesture:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        _startLocation = [sender locationInView:self.view];
    }
    else if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint stopLocation = [sender locationInView:self.view];
        CGFloat dx = stopLocation.x - _startLocation.x;
        CGFloat dy = stopLocation.y - _startLocation.y;
        CGFloat distance = sqrt(dx*dx + dy*dy );
        NSLog(@"Distance: %f", distance);
    }
}

@end
