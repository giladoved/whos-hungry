//
//  RestaurantsViewController.m
//  Who's Hungry
//
//  Created by administrator on 10/19/14.
//  Copyright (c) 2014 Who's Hungry. All rights reserved.
//

#import "RestaurantsViewController.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFNetworking.h"
#import "RestaurantsViewControllerGeneric.h"

#define GOOGLE_API_KEY @"AIzaSyAdB2MtdRCGDZNfIcd-uR22hkmCmniA6Oc"
#define GOOGLE_API_KEY_TWO @"AIzaSyBBQSs-ALwZ3Za7nioFPYXsByMDsMFq-68"
#define GOOGLE_API_KEY_THREE @"AIzaSyA6gixyCg9D-9nEJ8q7PQJiJ9Nk5LzcltI"
#define GOOGLE_API_KEY_FOUR @"AIzaSyDF0gj_1xGofM8BriMNH-uHbNYBVjI3g70"
#define LOBBY_KEY  @"currentlobby"

@interface RestaurantsViewController () {
    NSMutableArray *restImages;
}

@end

@implementation RestaurantsViewController

@synthesize locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    _restaurantIdArray = [NSMutableArray new];
    _restaurantNameArray = [NSMutableArray new];
    _restaurantPicArray = [NSMutableArray new];
    _restaurantXArray = [NSMutableArray new];
    _restaurantYArray = [NSMutableArray new];
    _restaurantRatingArray = [NSMutableArray new];
    restImages = [NSMutableArray new];
    _allPlaces = [NSMutableArray new];

    UIBarButtonItem *searchBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Search" style:UIBarButtonItemStylePlain target:self action:@selector(searchForRestaurant)];
    self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem, searchBarButton];
    
    [self initRestaurants];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGPoint contentOffset = self.restaurantsTable.contentOffset;
    contentOffset.y += CGRectGetHeight(self.restaurantsTable.tableHeaderView.frame);
    self.restaurantsTable.contentOffset = contentOffset;
}

- (void)initRestaurants{
    _isAdmin = TRUE;   //THIS IS A TEST CASE
    NSLog(@"initing restuarants");
    _tickedIndexPaths = [[NSMutableArray alloc] init];
    _locationFound = FALSE;
    _selectionCount = 0;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager requestAlwaysAuthorization];
    }
    
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways ||
        authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
    }
    
    // Do any additional setup after loading the view.
    self.restaurantsTable.backgroundColor = [UIColor clearColor];
    self.restaurantsTable.opaque = NO;
    self.restaurantsTable.backgroundView = nil;
    _allPlaces = [NSMutableArray new];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (([scrollView contentOffset].y + scrollView.frame.size.height) >= [scrollView contentSize].height){
        NSLog(@"Load more!!");
    }
}

-(void)getRestInfo:(NSString *)googleType {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters =
                                @{@"location": [NSString stringWithFormat:@"%f,%f", _currentCentre.latitude,                     _currentCentre.longitude],
                                 @"types":googleType,
                                 @"key":GOOGLE_API_KEY_TWO,
                                  @"rankby":@"distance",
                                 };
    [manager GET:@"https://maps.googleapis.com/maps/api/place/nearbysearch/json" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSMutableDictionary* emptyVotingDict = [NSMutableDictionary new];
        NSDictionary *googlePlacesResults = (NSDictionary *)responseObject;
        NSArray *placesData = googlePlacesResults[@"results"];
        int amount = 20;
            if (placesData.count < 20)
                amount = (int)placesData.count;
        for (int i = 0; i < amount; i++) {
            NSDictionary *currentPlace = placesData[i];
            [_allPlaces addObject:currentPlace];
            NSLog(@"current place is %@:", currentPlace);
            
            [emptyVotingDict setObject:@(0) forKey:currentPlace[@"name"]];
            
            NSString *urlStr;
            if (currentPlace[@"photos"] != nil) {
                NSDictionary *photosDict = currentPlace[@"photos"][0];
                NSString *photoRef = photosDict[@"photo_reference"];
                urlStr = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/photo?photoreference=%@&key=%@&sensor=false&maxwidth=320", photoRef, GOOGLE_API_KEY_TWO];
            } else {
                urlStr = currentPlace[@"icon"];
            }
            
            NSURL * imageURL = [NSURL URLWithString:urlStr];
            NSData * imageData = [NSData dataWithContentsOfURL:imageURL];
            UIImage * image = [UIImage imageWithData:imageData];
            if (image != nil)
                [restImages addObject:image];
            
        }
        [self.restaurantsTable reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //Finds location for the first time only and ONLY if it is ADMIN
    //if (!_locationFound) {
        NSLog(@"going through it man %@", locations[0]);
        _currentLocation = locations[0];
        _currentCentre = _currentLocation.coordinate;
        _locationFound = TRUE;
        if ([self.voteType isEqualToString:@"cafe"]) {
            [self getRestInfo:@"cafe"];
        }
        else {
            [self getRestInfo:@"food"];
        }
        [locationManager stopUpdatingLocation];
    //}

}

-(void) searchForRestaurant {
    [self performSegueWithIdentifier:@"chooseaplace" sender:self];
}

-(void) addChosenRestaurant {
    [_allPlaces insertObject:self.customRestaurant atIndex:0];
    [self.restaurantsTable reloadData];
}

- (GooglePlacesObject *)loadRestaurantObjectWithKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedObject = [defaults objectForKey:key];
    GooglePlacesObject *object = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
    return object;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"chooseaplace"])
    {
        RestaurantsViewControllerGeneric *restVC = [segue destinationViewController];
        restVC.onCompletion = ^{
            self.customRestaurant = [self loadRestaurantObjectWithKey:@"chosenRestaurant"];
            [self addChosenRestaurant];
        };
    }
}

# pragma mark - tableView methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.allPlaces.count == 0) {
        return  0;
    }
    else{
        return _allPlaces.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"mainCell";
    RestaurantCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSDictionary *chosenResponse = [_allPlaces objectAtIndex:indexPath.row];
    cell.backgroundColor = [UIColor clearColor];
    

    
    //////////
    //Load image into the cell
    /*
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(concurrentQueue, ^{
        NSDictionary *photoDict = [[response objectForKey:@"photos"] objectAtIndex:0];
        NSString *photoRef = [photoDict objectForKey:@"photo_reference"];
        NSString *urlStr = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/photo?photoreference=%@&key=%@&sensor=false&maxwidth=320", photoRef, GOOGLE_API_KEY_THREE];
        NSURL * imageURL = [NSURL URLWithString:urlStr];
        
        NSData * imageData = [NSData dataWithContentsOfURL:imageURL];
        UIImage * image = [UIImage imageWithData:imageData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.image.image = image;
        });
    });
    */
    if (restImages.count > 0 && indexPath.row < restImages.count) {
        cell.image.image = restImages[indexPath.row];
    }
    cell.name.text = chosenResponse[@"name"];
    
    /////////
    //Price level signs
    int priceLevel = [chosenResponse[@"price_level"]intValue];
    if (!priceLevel) {
        priceLevel = 3;
    }
    NSString* priceString = @"";
    for (int i = 0; i < priceLevel; i++) {
        priceString = [priceString stringByAppendingString:@"$"];
    }
    cell.price.text = priceString;
    
    ///////////
    //Loading distance from current location
    NSDictionary* loc  = [[NSDictionary alloc] init];
    loc = chosenResponse[@"geometry"][@"location"];
    CLLocation* placeLocation = [[CLLocation alloc] initWithLatitude:(CLLocationDegrees)[loc[@"lat"] doubleValue] longitude:(CLLocationDegrees)[loc[@"lng"] doubleValue]];
    NSLog(@"Latitude %@ and Longitude %@", loc[@"lat"], loc[@"lng"]);
    
    CLLocation* userLocation = [[CLLocation alloc] initWithLatitude:_currentCentre.latitude longitude:_currentCentre.longitude];
    float distance = [placeLocation distanceFromLocation:userLocation] / 1609.0;
    cell.distance.text = [NSString stringWithFormat:@"%1.2f mi.", distance];
    
    ///////////
    //Add or remove checkmark
    if([self.tickedIndexPaths containsObject:indexPath])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [cell setBackgroundColor:[UIColor colorWithRed:255.0/255.0 green:228.0/255.0 blue:171.0/255.0 alpha:1.0]];
        [_restaurantIdArray addObject:chosenResponse[@"place_id"]];
        [_restaurantNameArray addObject:chosenResponse[@"name"]];
        [_restaurantPicArray addObject:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/photo?photoreference=%@&key=%@&sensor=false&maxwidth=320", chosenResponse[@"place_id"], GOOGLE_API_KEY]];
        
        if (chosenResponse[@"geometry"][@"location"]) {
            [_restaurantXArray addObject:chosenResponse[@"geometry"][@"location"][@"lat"]];
            [_restaurantYArray addObject:chosenResponse[@"geometry"][@"location"][@"lng"]];
        } else {
            [_restaurantXArray addObject:@"NONE"];
            [_restaurantYArray addObject:@"NONE"];
        }
        //[_restaurantRatingArray addObject:chosenResponse[@"rating"]];
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //If cell is not already in list of checkmark
    if(![self.tickedIndexPaths containsObject:indexPath]){
        
        //If it is an there is less than 3 selected, just add it to the array
        if (_selectionCount < 3) {
            [self.tickedIndexPaths addObject:indexPath];
            _selectionCount++;
        }
        
        //If it is the 4th to be selected, remove the first from the array and shift the rest and add this one in first location
        else if (_selectionCount == 3){
            id object = [self.tickedIndexPaths objectAtIndex:1];
            [self.tickedIndexPaths removeObjectAtIndex:0];
            [self.tickedIndexPaths insertObject:object atIndex:0];
            object = [self.tickedIndexPaths objectAtIndex:2];
            [self.tickedIndexPaths removeObjectAtIndex:1];
            [self.tickedIndexPaths insertObject:object atIndex:1];
            [self.tickedIndexPaths removeObjectAtIndex:2];
            [self.tickedIndexPaths insertObject:indexPath atIndex:2];
        }
    }
    
    //If cell is already selected, deselect it.
    else{
        [self.tickedIndexPaths removeObject:indexPath];
        _selectionCount--;
    }
    
    //////////
    //Reset array of restaurant id's
    [_restaurantIdArray removeAllObjects];
    [_restaurantNameArray removeAllObjects];
    [_restaurantPicArray removeAllObjects];
    [_restaurantXArray removeAllObjects];
    [_restaurantYArray removeAllObjects];
    [_restaurantRatingArray removeAllObjects];
    
    //reload data again to display checkmarks
    [self.restaurantsTable reloadData];
}

- (IBAction)doneTapped:(id)sender {
    [self.locationManager stopUpdatingLocation];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    ///////////
    //Retrieving FB user Id
    if (FBSession.activeSession.isOpen)
    {
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            _facebookId = result[@"id"];
            _facebookName = result[@"name"];
            
            NSLog(@"FB ID is: %@", _facebookId);
            
            HootLobby* tempLobby = [self loadCustomObjectWithKey:LOBBY_KEY];
            if (!tempLobby) {
                NSLog(@"Current Lobby is empty");
                tempLobby = [HootLobby new];
            }
            else{
                NSLog(@"Current Lobby has DATA!");
            }
            tempLobby.facebookId = _facebookId;
            tempLobby.facebookName = _facebookName;
            [self saveCustomObject:tempLobby];
        }];
        
    }
    
    //transfer restaurantsIdArray to hootLobby
    //transfer facebookId to HootLobby
    
    HootLobby* tempLobby = [self loadCustomObjectWithKey:LOBBY_KEY];
    if (!tempLobby) {
        NSLog(@"Current Lobby is empty");
        tempLobby = [HootLobby new];
    }
    tempLobby.placesIdArray = _restaurantIdArray;
    tempLobby.placesNamesArray = _restaurantNameArray;
    tempLobby.placesPicsArray = _restaurantPicArray;
    tempLobby.placesXArray = _restaurantXArray;
    tempLobby.placesYArray = _restaurantYArray;
    tempLobby.placesRankingArray = _restaurantRatingArray;
    tempLobby.didAdminCreate = YES;
    [self saveCustomObject:tempLobby];
}

-(void)saveCustomObject:(HootLobby *)object
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    [prefs setObject:myEncodedObject forKey:LOBBY_KEY];
}

-(HootLobby *)loadCustomObjectWithKey:(NSString*)key
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSData *myEncodedObject = [prefs objectForKey:key ];
    HootLobby *obj = (HootLobby *)[NSKeyedUnarchiver unarchiveObjectWithData: myEncodedObject];
    return obj;
}



@end
