
//
//  SummaryViewController.m
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "SummaryViewController.h"
#import "UIImageView+AFNetworking.h"
#import "UIImage+Resize.h"
#import "AFNetworking.h"
#import "AFHTTPRequestOperation.h"
#import "RestaurantsViewControllerGeneric.h"

#define LOBBY_KEY  @"currentlobby"
static NSString * const BaseURLString = @"http://54.215.240.73:3000/";
#define GOOGLE_API_KEY @"AIzaSyAdB2MtdRCGDZNfIcd-uR22hkmCmniA6Oc"
#define GOOGLE_API_KEY_TWO @"AIzaSyBBQSs-ALwZ3Za7nioFPYXsByMDsMFq-68"
#define GOOGLE_API_KEY_THREE @"AIzaSyA6gixyCg9D-9nEJ8q7PQJiJ9Nk5LzcltI"
#define GOOGLE_API_KEY_FOUR @"AIzaSyDF0gj_1xGofM8BriMNH-uHbNYBVjI3g70"


@interface SummaryViewController () {
    CLLocationCoordinate2D restaurantCoor;
    CLLocationCoordinate2D userCoor;
    int votedIndex;
    //NSString *groupid;
    NSNumber *voteid;
    UIImage *selfImage;
    NSMutableArray *placesCountArray;
    MKPointAnnotation *restaurantPin;
    MKPointAnnotation *selfPin;
    BOOL viewload;
    BOOL votingDone;
    
    HootLobby *lobby;
    BOOL isAdmin;
    
    NSMutableArray *friendsGoingID;
    NSMutableArray *friendsPins;

    CLLocationDirection distanceSinceLastUpdate;
}

@end

@implementation SummaryViewController

typedef enum accessType
{
    ADMIN_FIRST,
    ADMIN_RETURNS,
    FRIEND_FIRST,
    FRIEND_RETURNS
} accessType;

/*
 Need to check for 4 different access
 1. Initial access from ADMIN when when/where/who is first selected
 2. Access from the ADMIN after going HOME and trying to modify vote or, if done, check map
 3. Access from FRIENDS to initially vote.
 4. Access from FRIENDS after already voting to modify vote or, if done, check map.
 */


/*
//THINGS TO FIX
1. Tell Sungwon to fix repeated names when reloading names from Server
2. enum is not working as it should
3. Fix timer issues

 
*/

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {

    }
    return self;
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(makeVote:)
     name:@"makeVote"
     object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateVoteCount:)
                                                 name:@"updateVoteCount"
                                               object:nil];
    
    NSLog(@"currnet loggy: %@", _currentLobby);
    
    _totalVoteArray = [[NSMutableArray alloc] initWithObjects:@0,@0,@0,nil]; //max number of restaurants able to be chosen (3 places)
    _voteStatusArray = [[NSMutableArray alloc] initWithObjects:@"0",@"0",@"0",nil];
    friendsGoingID = [NSMutableArray new];
    friendsPins = [NSMutableArray new];
    
    if (_accessType == ADMIN_FIRST) {
        //Initialize all the groups and create vote
        
        _currentLobby = [self loadCustomObjectWithKey:LOBBY_KEY];
        [self createAPIGroup];
        _isTimerReadyToBeActivated = TRUE;
        //_isExpirationUpdated = TRUE;
        
        
    }
    else if (_accessType == ADMIN_RETURNS){
        
    }
    
    //This is accessed by ADMIN_RETURNS
    else if (_accessType == FRIEND_FIRST){
        
    }
    else if (_accessType == FRIEND_RETURNS){
        
    }
    
    if (_accessType != ADMIN_FIRST) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:_currentLobby.voteid forKey:@"voteid"];
        [defaults synchronize];
        
        NSString *strFromInt = [NSString stringWithFormat:@"%d",_currentLobby.groupid.intValue];
        _voteStatusArray = [defaults mutableArrayValueForKey:strFromInt];
        
        [self updateVoteCount:nil];
    }
    
    _loaded = NO;
    
    [self setSummaryTitle];
    
    if (_voteStatusArray == nil)
        _voteStatusArray = [[NSMutableArray alloc] initWithObjects:@"0",@"0",@"0",nil];
    
    //Get picture of user
    /***************************************************************************************/
    if (FBSession.activeSession.isOpen)
    {
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me/picture?type=large&return_ssl_resources=1"]];
            // Success! Include your code to handle the results here
            NSLog(@"user info: %@", result);
            _facebookID = [NSString stringWithFormat:@"%@", result[@"id"]];
            selfImage = [UIImage imageWithImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:pictureURL]] scaledToSize:CGSizeMake(30.0, 30.0)];
        }];
    }
    
    //Loads RSVP of users
    /***************************************************************************************/
    if (_currentLobby.voteid){
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSDictionary *params = @{
                                 @"vote_id": _currentLobby.voteid};
        [manager POST:[NSString stringWithFormat:@"%@apis/show_rsvp", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
            NSDictionary *results = (NSDictionary *) responseObject;
            _currentLobby.rsvpArray = results[@"rsvps"];
            [_friendsGoingTable reloadData];
            NSLog(@"Dictionary %@",results);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
        
    }
    
    //Map initialization and authorization
    /***************************************************************************************/
    self.mapView.delegate = self;

    
    //Initializes and creates table
    /***************************************************************************************/
    [self.friendsGoingTable registerNib:[UINib nibWithNibName:@"RSVPFriendsTableViewCell" bundle:nil] forCellReuseIdentifier:@"MyCustomCell"];
    self.friendsGoingTable.delegate = self;
    self.friendsGoingTable.dataSource = self;
    self.friendsGoingTable.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.friendsGoingTable.allowsSelection = NO;


        NSLog(@"TIMER ACTIVATED!!!!");
        //Set the timer
        self.theTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                         target:self
                                                       selector:@selector(updateTime:)
                                                       userInfo:nil
                                                        repeats:YES];
    
    
    NSLog(@"currnet lobby:%@", _currentLobby);
    
    _indexPathArray = [NSMutableArray new];
    self.votingCompleteView.hidden = YES;
    self.votingIncompleteView.hidden = NO;
    
    self.restaurantTable.delegate = self;
    self.restaurantTable.dataSource = self;
    
    viewload = YES;
}

/*-(void) loadVotes {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSLog(@"vote id of show single vote is %@", _currentLobby.voteid);
    NSDictionary *params = @{@"vote_id": _currentLobby.voteid};
    [manager POST:[NSString stringWithFormat:@"%@apis/show_single_vote", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *results = (NSDictionary *)responseObject;
        NSLog(@"results from FINISHED THING: %@", results);
        
        for (int i = 0; i < [results[@"choices"] count]; i++) {
            [_totalVoteArray addObject:results[@"choices"][i][@"count"]];
        }
        
        if (_totalVoteArray.count == 0) {
            NSArray *arr = @[@(0), @(0), @(0)];
            _totalVoteArray = [arr copy];
            _voteStatusArray = [arr copy];
        }

        [_restaurantTable reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        {
            NSLog(@"FUCK DIS SHIT!");
        }
    }];
}*/

-(void) makeVote:(NSNotification *)note {
    NSLog(@"making vote!!" );
    
    UpDownVoteView *sender;
    NSDictionary *theData = [note userInfo];
    if (theData != nil) {
        sender = (UpDownVoteView *)[theData objectForKey:@"sender"];
    }
    
    for (int i = 0; i < _voteStatusArray.count; i++) {
        NSLog(@"before status %d is %@", i, _voteStatusArray[i]);
    }
    _voteStatusArray[sender.index] = sender.state;
    _totalVoteArray[sender.index] = @(sender.votes);
    [sender enableDisable];
    
    for (int i = 0; i < _voteStatusArray.count; i++) {
        NSLog(@"after status %d is %@", i, _voteStatusArray[i]);
    }
    
    NSLog(@"restaurant list ids: %@", _currentLobby.placesIdArray);
    NSLog(@"voted restaurant id : %@", _currentLobby.placesIdArray[sender.index]);
    
    voteid = _currentLobby.voteid;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{
                             @"user_id": _currentLobby.facebookId,
                             @"group_id":_currentLobby.groupid,
                             @"choice" : _currentLobby.placesIdArray[sender.index],
                             @"status" : sender.status};
    [manager POST:[NSString stringWithFormat:@"%@apis/make_vote", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        [sender enableDisable];
        [self saveVotingPrefs];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}


-(NSArray *)cellsForTableView:(UITableView *)tableView
{
    if ([tableView isEqual:self.restaurantTable]) {
        NSInteger sections = tableView.numberOfSections;
        NSMutableArray *cells = [[NSMutableArray alloc]  init];
        for (int section = 0; section < sections; section++) {
            NSInteger rows =  [tableView numberOfRowsInSection:section];
            for (int row = 0; row < rows; row++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                UpDownVoteView *cell = (UpDownVoteView*)[self.restaurantTable cellForRowAtIndexPath:indexPath];//**here, for those cells not in current screen, cell is nil**
                if (cell != nil)
                    [cells addObject:cell];
            }
        }
        return cells;
    }
    return nil;
}

- (IBAction)goHome:(id)sender {
    [locationManager stopUpdatingLocation];
    [self.theTimer invalidate];
    self.theTimer = nil;

    if (_currentLobby.rsvpArray.count < 1) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        if (_currentLobby.voteid != nil) {
        NSDictionary *params = @{
                                 @"user_id": _facebookID,
                                 @"vote_id": _currentLobby.voteid,
                                 @"go": [NSNumber numberWithInt:_rsvpCell.isGoing]};
        [manager POST:[NSString stringWithFormat:@"%@apis/make_rsvp", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
            NSDictionary *results = (NSDictionary *) responseObject;
            NSLog(@"Dictionary %@",results);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
        }
    }
    if (![_currentLobby.rsvpArray containsObject:_facebookID]) {
       
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self saveVotingPrefs];
}

-(void) saveVotingPrefs {
    /*_voteStatusArray = [NSMutableArray new];
    _totalVoteArray = [NSMutableArray new];
    
    NSArray* tableCellArray = [self cellsForTableView:_restaurantTable];
    for (int i = 0; i < tableCellArray.count; i++) {
        [_totalVoteArray addObject:@([tableCellArray[i] votes])];
        [_voteStatusArray addObject:@([tableCellArray[i] stateInt])];
    }*/
    
    //Update array with group ID key
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if (_voteStatusArray) {
        [prefs setObject:_voteStatusArray forKey:[NSString stringWithFormat:@"%d",_currentLobby.groupid.intValue]];
        [prefs setObject:@-1 forKey:@"voteid"];
        [prefs synchronize];
    }
}

#pragma mark - Location methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    _currentLocation = [locations lastObject];
    if (locations.count == 1) {
        distanceSinceLastUpdate = 0;
    } else if (locations.count > 1) {
        distanceSinceLastUpdate = [self.currentLocation distanceFromLocation:locations[locations.count-2]];
    }
    
    [_restaurantTable reloadData];
    [locationManager stopUpdatingLocation];
}

/*- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"Annotation";
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        
        MKAnnotationView *annotationView = (MKAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.image = [UIImage imageWithImage:[UIImage imageNamed:@"chiptole.png"] scaledToSize:CGSizeMake(30.0, 30.0)];
        } else {
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    
    return nil;
}*/

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([[annotation title] isEqualToString:@"Current Location"]) {
        return nil;
    }
    
    static NSString* AnnotationIdentifier = @"Annotation";
    MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
    
    if (!pinView) {
        MKPinAnnotationView *customPinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
        if (annotation == mapView.userLocation){
            //customPinView.image = [UIImage imageWithImage:selfImage scaledToSize:CGSizeMake(28.0, 28.0)];
        }
        else{
            customPinView.image = [UIImage imageWithImage:[UIImage imageNamed:@"circled_owl.png"] scaledToSize:CGSizeMake(30.0, 30.0)];
        }
        customPinView.animatesDrop = NO;
        customPinView.canShowCallout = YES;
        return customPinView;
    } else {
        pinView.annotation = annotation;
    }
    
    return pinView;
}



/*- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    static NSString* AnnotationIdentifier = @"Annotation";
    MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
    
    if (!pinView) {
        MKPinAnnotationView *customPinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier];
        if (annotation == mapView.userLocation){
            if (selfImage != nil) {
                customPinView.image = [UIImage imageWithImage:selfImage scaledToSize:CGSizeMake(25.0, 25.0)];
            } else {
                customPinView.image = [UIImage imageWithImage:[UIImage imageNamed:@"chiptole.png"] scaledToSize:CGSizeMake(30.0, 30.0)];
            }
        }
        else{
            //customPinView.image = [UIImage imageWithImage:[UIImage imageNamed:@"chipotle.png"] scaledToSize:CGSizeMake(25.0, 25.0)];
            //customPinView.image = [UIImage imageNamed:@"mySomeOtherImage.png"];
        }
        customPinView.animatesDrop = NO;
        customPinView.canShowCallout = YES;
        return customPinView;
    } else {
        pinView.annotation = annotation;
    }
    
    return pinView;
}*/

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    NSLog(@"distance::::: %f", distanceSinceLastUpdate);
    if (distanceSinceLastUpdate > 200 || distanceSinceLastUpdate == 0) {
        NSLog(@"updated! %@", userLocation);
        
        for (int i = 0; i < friendsGoingID.count; i++) {
            //get every user's location
            //update the location of the user's pin
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            NSDictionary *params = @{
                                     @"user_id": _currentLobby.facebookId};
            [manager POST:[NSString stringWithFormat:@"%@apis/retrieve_location", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Updated Location! %@", responseObject);
                NSDictionary *results = (NSDictionary *) responseObject;
                MKPointAnnotation *pin = (MKPointAnnotation *)friendsPins[i];
                //CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(results[@"location_x"],results[@"location_y"]);
                //pin.coordinate = coord;
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error: %@", error);
            }];
        }
        
        selfPin.coordinate = self.currentLocation.coordinate;
        CLLocation *locale = [[CLLocation alloc] initWithLatitude:restaurantCoor.latitude longitude:restaurantCoor.longitude];
        CLLocationDistance distance = [self.currentLocation distanceFromLocation:locale];
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(restaurantCoor, distance*2, distance*2);
        MKCoordinateRegion mapRegion = [self.mapView regionThatFits:region];
        [self.mapView setRegion:mapRegion animated:YES];
        
        
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSDictionary *params = @{
                                 @"user_id": _currentLobby.facebookId,
                                 @"location_x":@(self.currentLocation.coordinate.latitude),
                                 @"location_y":@(self.currentLocation.coordinate.longitude)};
        [manager POST:[NSString stringWithFormat:@"%@apis/update_location", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Updated Location! %@", responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
        distanceSinceLastUpdate = 1;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"didFailWithError: %@", error);
}


#pragma mark - NSUserDefaults methods

-(void)saveCustomObject:(HootLobby *)object{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    [prefs setObject:myEncodedObject forKey:LOBBY_KEY];
}

-(HootLobby *)loadCustomObjectWithKey:(NSString*)key{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [prefs objectForKey:key];
    HootLobby *obj = (HootLobby *)[NSKeyedUnarchiver unarchiveObjectWithData: myEncodedObject];
    return obj;
}

#pragma mark - AWS API methods

-(void) createAPIGroup {
    isAdmin = YES;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString* facebookString = @"";
    for (int i = 0; i < _currentLobby.facebookbInvitatitions.count; i++) {
        if (i != _currentLobby.facebookbInvitatitions.count - 1) {
            facebookString = [facebookString stringByAppendingString:_currentLobby.facebookbInvitatitions[i]];
            facebookString = [facebookString stringByAppendingString:@","];
        }
        else{
            facebookString = [facebookString stringByAppendingString:_currentLobby.facebookbInvitatitions[i]];
        }
    }
    NSLog(@"user_id is %@", _currentLobby.facebookId);
    NSLog(@"invitations is %@", facebookString);
    //NSLog(@"current lobby is is is is %@", _currentLobby);
    
    NSDictionary *params = @{@"user_id": _currentLobby.facebookId,
                             @"invitations" : facebookString};
    
    [manager POST:[NSString stringWithFormat:@"%@apis/create_group", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *results = (NSDictionary *)responseObject;
        _currentLobby.groupid = results[@"group_id"];
        NSLog(@"group id is :%@", _currentLobby.groupid);
        NSLog(@"create group is :%@", responseObject);
        if (_currentLobby.groupid != nil)
        [self createAPIVoteWithGroupId:_currentLobby.groupid];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

-(void) createAPIVoteWithGroupId:(NSNumber*)groupId{
    NSString* restaurantIds = @"";
    NSString* restaurantNames = @"";
    NSString* restaurantPics = @"";
    NSString* restaurantX = @"";
    NSString* restaurantY = @"";

    for (int i = 0; i < _currentLobby.placesIdArray.count; i++) {
            restaurantIds = [restaurantIds stringByAppendingString:_currentLobby.placesIdArray[i]];
        
            restaurantNames = [restaurantNames stringByAppendingString:_currentLobby.placesNamesArray[i]];
        
            restaurantPics = [restaurantPics stringByAppendingString:_currentLobby.placesPicsArray[i]];
        
            NSString *xstr = _currentLobby.placesXArray[i];
            NSNumber *xnum = [NSNumber numberWithFloat:[xstr floatValue]];
            restaurantX = [restaurantX stringByAppendingString:[xnum stringValue]];
        
            NSString *ystr = _currentLobby.placesYArray[i];
            NSNumber *ynum = [NSNumber numberWithFloat:[ystr floatValue]];
            restaurantY = [restaurantY stringByAppendingString:[ynum stringValue]];

        if (i != _currentLobby.placesIdArray.count-1) {
            restaurantIds = [restaurantIds stringByAppendingString:@","];
            restaurantNames = [restaurantNames stringByAppendingString:@","];
            restaurantPics = [restaurantPics stringByAppendingString:@","];
            restaurantX = [restaurantX stringByAppendingString:@","];
            restaurantY = [restaurantY stringByAppendingString:@","];
        }
    }
    
    NSLog(@"rest ids: %@", restaurantIds);
    NSLog(@"rest names: %@", restaurantNames);
    NSLog(@"rest pics: %@", restaurantPics);
    NSLog(@"rest x: %@", restaurantX);
    NSLog(@"rest y: %@", restaurantY);
    
    NSDate *startDate = [NSDate new];
    NSDate *endDate = _currentLobby.expirationTime;
    NSCalendar *gregorian = [[NSCalendar alloc]initWithCalendarIdentifier:NSGregorianCalendar];
    unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit;
    
    if (endDate == nil) {
        endDate = [NSDate new];
    }
      NSDateComponents *components = [gregorian components:unitFlags fromDate:startDate
                                                  toDate:endDate options:0];
    NSInteger minsLeft = [components minute];
    
    NSLog(@"facebook id: %@",_currentLobby.facebookId);
    NSLog(@"group id: %@", groupId);
    NSLog(@"expiratation time: %@",_currentLobby.expirationTime);
    
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSDictionary *params = @{@"user_id": _currentLobby.facebookId,
                             @"group_id": groupId,
                             @"vote_type": _currentLobby.voteType,
                             @"expiration_time_number": @(minsLeft),
                             @"expiration_time": _currentLobby.expirationTime,
                             @"restaurant_ids": restaurantIds,
                             @"restaurant_names": restaurantNames,
                             @"restaurant_pictures":restaurantPics,
                             @"restaurant_locations_x":restaurantX,
                             @"restaurant_locations_y":restaurantY,
                             @"restaurant_stars":@"3, 4, 5",
                             @"name_of_vote":_currentLobby.name
                             };
    NSLog(@"params for create vote :%@", params);
    NSLog(@"EXPIRATION TIME IS %@",_currentLobby.expirationTime);

    [manager POST:[NSString stringWithFormat:@"%@apis/create_vote", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"create vote is :%@", responseObject);
        NSDictionary *results = (NSDictionary *) responseObject;
        _currentLobby.voteid = results[@"vote_id"];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:_currentLobby.voteid forKey:@"voteid"];
        [defaults synchronize];
        NSLog(@"vote id assigned is :%@", _currentLobby.voteid);
        [self setSummaryTitle];
        [self.restaurantTable reloadData];
        //[self loadSummary];
        [self loadRSVPisGoing:TRUE];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

-(void)loadRSVPisGoing:(BOOL)rsvp{
    _imagesRemoved = FALSE;
    int goingValue;
    if (rsvp) {
        goingValue = 1;
    }
    else{
        goingValue = -1;
    }
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{
                             @"user_id": _facebookID,
                             @"vote_id": _currentLobby.voteid,
                             @"go": @(goingValue)};
    [manager POST:[NSString stringWithFormat:@"%@apis/make_rsvp", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        NSDictionary *results = (NSDictionary *) responseObject;
        NSLog(@"Dictionary %@",results);
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSDictionary *params = @{
                                 @"vote_id": _currentLobby.voteid};
        [manager POST:[NSString stringWithFormat:@"%@apis/show_rsvp", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
            NSDictionary *results = (NSDictionary *) responseObject;
            _currentLobby.rsvpArray = results[@"rsvps"];
            friendsGoingID = results[@"rsvps"];
            [_friendsGoingTable reloadData];
            NSLog(@"Dictionary %@",results);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    if (rsvp) {
        _rsvpCell.isGoing = 1;
        [_rsvpCell.rsvpButton setImage:[UIImage imageNamed:@"GoingIcon(who'shungry).png"] forState:UIControlStateNormal];
        [_rsvpCell.rsvpButton setBackgroundColor:[UIColor whiteColor]];
        [_rsvpCell.arrowButton setBackgroundColor:[UIColor colorWithRed:(121.0/255.0) green:(231.0/255.0) blue:(175.0/255.0) alpha:1.0]];
        _rsvpCell.isOpen = FALSE;
    }
    else{
        _rsvpCell.isGoing = -1;
        [_rsvpCell.rsvpButton setImage:[UIImage imageNamed:@"06_notgoingwithtext_icon-19.png"] forState:UIControlStateNormal];
        [_rsvpCell.rsvpButton setBackgroundColor:[UIColor whiteColor]];
        [_rsvpCell.arrowButton setBackgroundColor:[UIColor colorWithRed:(240.0/255.0) green:(110.0/255.0) blue:(52.0/255.0) alpha:1.0]];
        _rsvpCell.isOpen = FALSE;
    }

}


-(void)setSummaryTitle {
    NSString *englishVoteType;
    if ([@"cafe" isEqualToString:_currentLobby.voteType]) {
        englishVoteType = @"grab coffee";
    } else if ([@"drinks" isEqualToString:_currentLobby.voteType]) {
        englishVoteType = @"get some drinks";
    } else {
        englishVoteType = [NSString stringWithFormat:@"eat %@", _currentLobby.voteType];
    }
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"hh:mm"];
    NSString *normalAtTime = [dateFormatter stringFromDate:_currentLobby.expirationTime];
    
    self.summaryTitleLbl.text = [NSString stringWithFormat:@"%@ wants to %@ today at %@", _currentLobby.facebookName, englishVoteType, normalAtTime];
}

- (IBAction)updateTime:(id)sender {
    //NSLog(@"currnet lobby:%@", _currentLobby);
    //if (_isTimerReadyToBeActivated && _isExpirationUpdated) {
    NSDate* newDate;
    double secondsInAMinute = 60;
    if ([_currentLobby.expirationTime timeIntervalSinceDate:[NSDate date]] / secondsInAMinute > 40) {
        newDate = [_currentLobby.expirationTime dateByAddingTimeInterval:-60*20];
    }
    else{
        newDate = [_currentLobby.expirationTime dateByAddingTimeInterval:(-60*([_currentLobby.expirationTime timeIntervalSinceDate:[NSDate date]] / secondsInAMinute) / 2)];
    }
        NSInteger hoursLeft = 0;
        NSInteger minutesLeft = 0;
        NSInteger secondsLeft = 0;
        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSUInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
        NSDateComponents *components = [gregorianCalendar components:unitFlags
                                                            fromDate:[NSDate new]
                                                              toDate:newDate
                                                             options:0];
        hoursLeft = components.hour;
        minutesLeft = components.minute; //plus 1 to include the chosen time, plus 0 not t0
        secondsLeft = components.second;
        //NSLog(@"time left is :%ld hrs and %ld mins", (long)hoursLeft, (long)minutesLeft);
        
        self.whenTimeLbl.text = [NSString stringWithFormat:@"%ldhr %ld min left %ld secs", (long)hoursLeft, (long)minutesLeft, (long)secondsLeft];
        
        //check if over...
        if (hoursLeft == 0 && minutesLeft <= 0 && secondsLeft <= 0) {
            NSLog(@"donnnneee!!");
            votingDone = YES;
            self.votingIncompleteView.hidden = YES;
            self.votingCompleteView.hidden = NO;
            [self lobbyFinished];
        } else {
            //[self performSelector:@selector(updateTime:) withObject:nil afterDelay:1.0];
        }
   // }

}

-(void) lobbyFinished {
   [self.theTimer invalidate];
    self.theTimer = nil;
    
    self.active = NO;
    self.mapView.hidden = NO;
    self.restaurantTable.hidden = YES;
    self.votingCompleteView.hidden = NO;
    self.votingIncompleteView.hidden = YES;
    
    _rsvpCell.arrowButton.enabled = NO;
    
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [locationManager requestWhenInUseAuthorization];
        [locationManager requestAlwaysAuthorization];
    }
    
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways ||
        authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [locationManager startUpdatingLocation];
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSLog(@"vote id of show single vote is %@", _currentLobby.voteid);
    NSDictionary *params = @{@"vote_id": _currentLobby.voteid};
    [manager POST:[NSString stringWithFormat:@"%@apis/show_single_vote", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *results = (NSDictionary *)responseObject;
        NSLog(@"results from FINISHED THING: %@", results);
        
        NSNumberFormatter * f = [NSNumberFormatter new];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        
        _currentLobby.winnerRestID = results[@"winner_restaurant_id"];
        if ( _currentLobby.winnerRestID == nil || [_currentLobby.winnerRestID isEqual:[NSNull null]]) {
            NSLog(@"calculate byhand...");
            int winnerChoice = 0;
            int highestVote = 0;
            for (int i = 0; i < [results[@"choices"] count]; i++) {
                if ((int)results[@"choices"][i][@"count"] > highestVote){
                    highestVote = (int)results[@"choices"][i][@"count"];
                    winnerChoice = i;
                }
            }
            _currentLobby.winnerRestID = results[@"choices"][winnerChoice][@"restaurant_id"];
            _currentLobby.winnerRestName = results[@"choices"][winnerChoice][@"restaurant_name"];
            _currentLobby.winnerRestPic = results[@"choices"][winnerChoice][@"restaurant_picture"];
            _currentLobby.winnerRestX = results[@"choices"][winnerChoice][@"restaurant_location_x"];
            _currentLobby.winnerRestY = results[@"choices"][winnerChoice][@"restaurant_location_y"];
        } else {
            _currentLobby.winnerRestName = results[@"winner_restaurant_name"];
            _currentLobby.winnerRestPic = results[@"winner_restaurant_picture"];
            _currentLobby.winnerRestX = [f numberFromString:(NSString *)results[@"winner_restaurant_location_x"]];
            _currentLobby.winnerRestY = [f numberFromString:(NSString *)results[@"winner_restaurant_location_y"]];
        }

        NSLog(@"current lobby ids rrrr: %@", _currentLobby.winnerRestID);
        NSLog(@"current lobby names rrrr: %@", _currentLobby.winnerRestName);
        NSLog(@"current lobby pics rrrr: %@", _currentLobby.winnerRestPic);
        NSLog(@"current lobby x rrrr: %@", _currentLobby.winnerRestX);
        NSLog(@"current lobby y rrrr: %@", _currentLobby.winnerRestY);
        
        restaurantCoor = CLLocationCoordinate2DMake([_currentLobby.winnerRestX floatValue], [_currentLobby.winnerRestY floatValue]);
        restaurantPin = [[MKPointAnnotation alloc] init];
        restaurantPin.coordinate = restaurantCoor;
        NSLog(@"restaurant coordinates %f, %f", restaurantCoor.latitude, restaurantCoor.longitude);
        restaurantPin.title = _currentLobby.winnerRestName;
        [self.mapView addAnnotation:restaurantPin];
        
        selfPin = [[MKPointAnnotation alloc] init];
        selfPin.coordinate = self.currentLocation.coordinate;
        [self.mapView addAnnotation:selfPin];
        
        for (int i = 0; i < friendsGoingID.count; i++) {
            MKPointAnnotation *pin = [MKPointAnnotation new];
            pin.coordinate = self.currentLocation.coordinate;
            [self.mapView addAnnotation:pin];
        }
        
        CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
        if (authorizationStatus == kCLAuthorizationStatusAuthorized ||
            authorizationStatus == kCLAuthorizationStatusAuthorizedAlways ||
            authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
            
            self.mapView.showsUserLocation = YES;
            [locationManager startUpdatingLocation];
            
        } else {
            NSLog(@"or nah");
        }
        
        self.winningRestaurantLabel.text = _currentLobby.winnerRestName;
        
        [_restaurantTable reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"FUCK DIS SHIT!");
    }];
    
}

-(void) updateVoteCount:(NSNotification *)noti {
    NSString *strFromInt = [NSString stringWithFormat:@"%d",_currentLobby.groupid.intValue];
    //_voteStatusArray = [defaults mutableArrayValueForKey:strFromInt];
    
    NSLog(@"noti :%@", noti);
    NSNumber *vid = _currentLobby.voteid;
    
    if (_currentLobby.voteid == nil)
        vid = [[NSUserDefaults standardUserDefaults] objectForKey:@"voteid"];
    if (vid == nil)
        vid = [noti userInfo][@"vote_id"];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *params = @{@"vote_id": vid};
    [manager POST:[NSString stringWithFormat:@"%@apis/show_single_vote", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *results = (NSDictionary *)responseObject;
        NSArray *choices = results[@"choices"];
        for (int i  = 0; i < choices.count; i++) {
            _totalVoteArray[i] = choices[i][@"count"];
        }
        [_restaurantTable reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"FUCK DIS SHIT!");
    }];
}

- (IBAction)suggestAPlace:(id)sender {
    if (self.chosenPlace == nil) {
        [self performSegueWithIdentifier:@"suggestaplace" sender:self];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Again?"
                                                                     message:@"You've already suggested a place..."
                                                                    delegate:self
                                                           cancelButtonTitle:@"Ok"
                                                           otherButtonTitles:nil];
         [alert show];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"suggestaplace"]) {
        RestaurantsViewControllerGeneric *restVC = (RestaurantsViewControllerGeneric *)segue.destinationViewController;
        restVC.voteTypes = @[_currentLobby.voteType];
        restVC.onCompletion = ^{
            if (self.chosenPlace == nil) {
                self.chosenPlace = [self loadRestaurantObjectWithKey:@"chosenRestaurant"];
                [self addChosenRestaurant];
            } else {
                NSLog(@"COME ON MAN< YOU ALREADY SUGGESTED A PLACE!!!");
            }
        };
    }
}

-(void) addChosenRestaurant  {
    NSLog(@"here's the chosen place: %@", self.chosenPlace.name);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    if (_currentLobby.voteid != nil) {
        NSLog(@"cuurnetlobby: %@", self.currentLobby.voteid);
        NSLog(@"name: %@", self.chosenPlace);
        NSLog(@"name: %@", self.chosenPlace.name);
        NSLog(@"id: %@", self.chosenPlace.placesId);
        NSLog(@"imagestr: %@", self.chosenPlace.imageUrl);
        NSLog(@"ratnig: %@", self.chosenPlace.rating);
        
        if (self.chosenPlace.rating == nil)
            self.chosenPlace.rating = @"1";
        
        if (self.chosenPlace.imageUrl == nil)
            self.chosenPlace.imageUrl = @"";
        
        NSDictionary *params = @{
                                 @"vote_id": _currentLobby.voteid,
                                 @"restaurant_id":self.chosenPlace.placesId,
                                 @"restaurant_name":self.chosenPlace.name,
                                 @"restaurant_picture":self.chosenPlace.imageUrl,
                                 @"restaurant_location_x":[NSString stringWithFormat:@"%f", self.chosenPlace.coordinate.latitude],
                                 @"restaurant_location_y":[NSString stringWithFormat:@"%f", self.chosenPlace.coordinate.longitude],
                                 @"restaurant_stars":self.chosenPlace.rating};
        [manager POST:[NSString stringWithFormat:@"%@apis/add_restaurant_to_vote", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary *results = (NSDictionary *) responseObject;
            NSLog(@"Dictionary %@",results);
            //[self loadVotes];
            [self updateVoteCount:nil];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
    }
}

- (GooglePlacesObject *)loadRestaurantObjectWithKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedObject = [defaults objectForKey:key];
    GooglePlacesObject *object = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
    return object;
}

#pragma mark - Table View methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([tableView isEqual:self.restaurantTable]) {
        return _currentLobby.placesIdArray.count;
    }
    
    else {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([tableView isEqual:self.restaurantTable]) {
        return 100;
    } else {
        return 75;
    }
}


#pragma mark - UIScrollViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Cell is from Restaurant's Table
    if ([tableView isEqual:self.restaurantTable]) {
        static NSString *simpleTableIdentifier = @"UpDownVoteView";
        UpDownVoteView *cell = (UpDownVoteView *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"updownvote" owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        [cell layoutIfNeeded];
        cell.contentView.userInteractionEnabled = NO;

        [_indexPathArray addObject:indexPath];
        if (_currentLobby && _currentLobby.placesIdArray.count > 0) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.index = (int)indexPath.row;
        }
        
        //NSLog(@"ALL PLACES: %@", _allPlaces);
        //NSLog(@"places %@", _currentLobby);
        
        if (!_loaded) {
            if (![_currentLobby.placesXArray[indexPath.row] isEqual:[NSNull null]]) {
                CLLocation *placeLocation = [[CLLocation alloc] initWithLatitude:(CLLocationDegrees)[_currentLobby.placesXArray[indexPath.row] doubleValue] longitude:(CLLocationDegrees)[_currentLobby.placesYArray[indexPath.row] doubleValue]];
                //CLLocation* placeLocation = [[CLLocation alloc] initWithLatitude:(CLLocationDegrees)[_allPlaces[indexPath.row][@"geometry"][@"location"][@"lat"] doubleValue] longitude:(CLLocationDegrees)[_allPlaces[indexPath.row][@"geometry"][@"location"][@"lng"] doubleValue]];
                float distance = [placeLocation distanceFromLocation:_currentLocation] / 1609.0;
                //float distance = 50.0f;
                //  NSLog(@"Current row is %d", (int)indexPath.row);
                cell.distanceLabel.text = [NSString stringWithFormat:@"%1.2f mi.",distance];
                cell.restaurantLabel.text = _currentLobby.placesNamesArray[indexPath.row];
                
                if (_voteStatusArray && _totalVoteArray && indexPath.row < _voteStatusArray.count && indexPath.row < _totalVoteArray.count) {
                    cell.votes = [_totalVoteArray[indexPath.row] intValue];
                    cell.voteLbl.text = [NSString stringWithFormat:@"%i", cell.votes];
                    cell.stateInt = [_voteStatusArray[indexPath.row] intValue];
                    cell.state = _voteStatusArray[indexPath.row];
                    NSLog(@"status: %d", cell.stateInt);
                    [cell enableDisable];
                }
            }
        } else {
            CLLocation* placeLocation = [[CLLocation alloc] initWithLatitude:(CLLocationDegrees)[_currentLobby.placesXArray[indexPath.row] doubleValue] longitude:(CLLocationDegrees)[_currentLobby.placesYArray[indexPath.row] doubleValue]];
            float distance = [placeLocation distanceFromLocation:_currentLocation] / 1609.0;
            cell.distanceLabel.text = [NSString stringWithFormat:@"%1.2f mi.",distance];
            cell.restaurantLabel.text = _currentLobby.placesNamesArray[indexPath.row];
            if (_voteStatusArray && _totalVoteArray && indexPath.row < _voteStatusArray.count && indexPath.row < _totalVoteArray.count) {
                cell.votes = [_totalVoteArray[indexPath.row] intValue];
                cell.voteLbl.text = [NSString stringWithFormat:@"%i", cell.votes];
                cell.stateInt = [_voteStatusArray[indexPath.row] intValue];
                cell.state = _voteStatusArray[indexPath.row];
                [cell enableDisable];
            }
        }
        
        return cell;
    }
    
    //Cell is from Friends Table
    if([tableView isEqual:self.friendsGoingTable]) {
        static NSString *cellIdentifier = @"MyCustomCell";
        RSVPFriendsTableViewCell *cell = (RSVPFriendsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.leftUtilityButtons = [self leftButtons];
        cell.rightUtilityButtons = [self rightButtons];
        
        cell.extraLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFriendsGoing)];
        [cell.extraLabel addGestureRecognizer:recognizer];
        
        if (!_imagesRemoved) {
            [cell.firstImage setImage:nil];
            [cell.secondImage setImage:nil];
            [cell.thirdImage setImage:nil];
            [cell.fourthImage setImage:nil];
            _imagesRemoved = TRUE;
        }
        cell.delegate = self;
        cell.isGoing = 0;
        if (_currentLobby.rsvpArray.count > 0) {
            int extraCount = 0;
            int imageIndex = 0;
            for (int i = 0; i < _currentLobby.rsvpArray.count; i++) {
                if ([(NSString*)_currentLobby.rsvpArray[i][@"facebook_id"] isEqualToString:_facebookID]){
                    if ([_currentLobby.rsvpArray[i][@"go"]  isEqual: @1]) {
                        [_rsvpCell.rsvpButton setImage:[UIImage imageNamed:@"GoingIcon(who'shungry).png"] forState:UIControlStateNormal];
                        [_rsvpCell.rsvpButton setBackgroundColor:[UIColor whiteColor]];
                        [_rsvpCell.arrowButton setBackgroundColor:[UIColor colorWithRed:(121.0/255.0) green:(231.0/255.0) blue:(175.0/255.0) alpha:1.0]];
                        _rsvpCell.isOpen = FALSE;
                    }
                    else{
                        _rsvpCell.isGoing = -1;
                        [_rsvpCell.rsvpButton setImage:[UIImage imageNamed:@"06_notgoingwithtext_icon-19.png"] forState:UIControlStateNormal];
                        [_rsvpCell.rsvpButton setBackgroundColor:[UIColor whiteColor]];
                        [_rsvpCell.arrowButton setBackgroundColor:[UIColor colorWithRed:(240.0/255.0) green:(110.0/255.0) blue:(52.0/255.0) alpha:1.0]];
                        _rsvpCell.isOpen = FALSE;
                    }

                }
                NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:_currentLobby.rsvpArray[i][@"picture"]]];
                UIImage* tempImage = [UIImage new];
                tempImage = [self resizeImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:pictureURL]] newSize:CGSizeMake(50.0, 50.0)];
                if ([_currentLobby.rsvpArray[i][@"go"] integerValue] == 1) {
                    if (imageIndex == 0){
                        [cell.firstImage setImage:tempImage];
                        [cell.firstImage.layer setCornerRadius:cell.firstImage.image.size.width / 2.0];
                    }
                    if (imageIndex == 1) {
                        cell.secondImage.layer.cornerRadius = cell.secondImage.image.size.width / 2.0;
                        [cell.secondImage setImage:tempImage];
                    }
                    if (imageIndex == 2) {
                        cell.thirdImage.layer.cornerRadius = cell.thirdImage.image.size.width / 2.0;
                        [cell.thirdImage setImage:tempImage];
                    }
                    if (imageIndex > 2) {
                        cell.extraLabel.text = [NSString stringWithFormat:@"+%d",imageIndex];
                    }
                    imageIndex++;
                }
                
            }
        }
        _rsvpCell = cell;
        return cell;
    }
    
    return 0;
}

-(void) showFriendsGoing {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Friends Going" message:@"Here are all the people that are coming! \n\n\n\n "delegate:self  cancelButtonTitle:@"Okay"
                                          otherButtonTitles:nil];
    
    UILabel *labelOfGoing = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, 264, 120)];
    labelOfGoing.text = @"Who's Going?";
    NSMutableString *goingStr = [NSMutableString new];
    for (int i = 0; i < friendsGoingID.count; i++) {
         [goingStr appendFormat:@"%@\n", friendsGoingID[i]];
    }
    labelOfGoing.text = [goingStr copy];
    [alert addSubview:labelOfGoing];
    
    [alert show];
}

- (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (NSArray *)rightButtons{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0]
                                                 icon:[UIImage imageNamed:@"GoingIcon(who'shungry).png"]];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0]
                                                 icon:[UIImage imageNamed:@"06_notgoingwithtext_icon-19.png"]];
    return rightUtilityButtons;
}

- (NSArray *)leftButtons{
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.07 green:0.75f blue:0.16f alpha:1.0]
                                                icon:[UIImage imageNamed:@"check.png"]];
    [leftUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188f alpha:1.0]
                                                icon:[UIImage imageNamed:@"cross.png"]];
    
    return leftUtilityButtons;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Set background color of cell here if you don't want default white
}

#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state{
    switch (state) {
        case 0:
            NSLog(@"utility buttons closed");
            [self.friendsGoingTable setEditing:NO animated:NO];
            break;
        case 1:
            NSLog(@"left utility buttons open");
            break;
        case 2:
            NSLog(@"right utility buttons open");
            break;
        default:
            break;
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index{
    RSVPFriendsTableViewCell *theCell = (RSVPFriendsTableViewCell *)cell;
    NSIndexPath *path = [NSIndexPath indexPathWithIndex:index];
    switch (index) {
        case 0:
            NSLog(@"RVSP YES was pressed");
            break;
        case 1:
            NSLog(@"RSVP NO was pressed");
            break;
        default:
            break;
    }
    [theCell setNeedsDisplay];
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index{
    [cell hideUtilityButtonsAnimated:YES];
    switch (index) {
        case 0:
        {
            [self loadRSVPisGoing:TRUE];
             break;
        }
        case 1:
        {
            [self loadRSVPisGoing:FALSE];
            break;
        }
        default:
            break;
    }
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell{
    // allow just one cell's utility button to be open at once
    return YES;
}

- (BOOL)swipeableTableViewCell:(SWTableViewCell *)cell canSwipeToState:(SWCellState)state{
    switch (state) {
        case 1:
            // set to NO to disable all left utility buttons appearing
            return NO;
            break;
        case 2:
            // set to NO to disable all right utility buttons appearing
            return YES;
            break;
        default:
            break;
    }
    
    return YES;
}

@end