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
    _isRestInfoCalled = FALSE;
    _secondPageLoaded = FALSE;
    _thirdPageLoaded = FALSE;
    _restaurantsTable.hidden = YES;
    _restaurantIdArray = [NSMutableArray new];
    _restaurantNameArray = [NSMutableArray new];
    _restaurantPicArray = [NSMutableArray new];
    _restaurantXArray = [NSMutableArray new];
    _restaurantYArray = [NSMutableArray new];
    _restaurantRatingArray = [NSMutableArray new];
    restImages = [NSMutableArray new];
    _allPlaces = [NSMutableArray new];

    UIBarButtonItem *searchBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Search" style:UIBarButtonItemStylePlain target:self action:@selector(searchForRestaurant)];
    self.navigationItem.leftBarButtonItem = searchBarButton;
    [self initRestaurants];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    CGPoint offset = _restaurantsTable.contentOffset;
    CGRect bounds = _restaurantsTable.bounds;
    CGSize size = _restaurantsTable.contentSize;
    UIEdgeInsets inset = _restaurantsTable.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    float reload_distance = 10;
    if(y > h + reload_distance) {
        if (_nextPageToken && (!_secondPageLoaded || !_thirdPageLoaded) && !_doneThisRound) {
            _doneThisRound = TRUE;
            if (_secondPageLoaded) {
                _thirdPageLoaded = TRUE;
            }
            else{
                _secondPageLoaded = TRUE;
            }
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            NSString* url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/nearbysearch/json?pagetoken=%@&key=%@",_nextPageToken,GOOGLE_API_KEY_TWO];
            [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSMutableDictionary* emptyVotingDict = [NSMutableDictionary new];
                NSDictionary *googlePlacesResults = (NSDictionary *)responseObject;
                if (googlePlacesResults[@"next_page_token"]) {
                    _nextPageToken = googlePlacesResults[@"next_page_token"];
                }
                NSArray *placesData = googlePlacesResults[@"results"];
                int amount = 20;
                if (placesData.count < 20)
                    amount = (int)placesData.count;
                for (int i = 0; i < amount; i++) {
                    NSDictionary *currentPlaceDict = placesData[i];
                    NSLog(@"curr place %@", currentPlaceDict);
                    GooglePlacesObject *currentPlace = [[GooglePlacesObject alloc] init];
                    
                    NSDictionary *geo = [currentPlaceDict objectForKey:@"geometry"];
                    NSDictionary *loc = [geo objectForKey:@"location"];
                    
                    //Figure out Distance from POI and User
                    CLLocation *poi = [[CLLocation alloc] initWithLatitude:[[loc objectForKey:@"lat"] doubleValue]  longitude:[[loc objectForKey:@"lng"] doubleValue]];
                    CLLocation *user = [[CLLocation alloc] initWithLatitude:self.currentCentre.latitude longitude:self.currentCentre.longitude];
                    CLLocationDistance inFeet = ([user distanceFromLocation:poi]) * 3.2808;
                    
                    CLLocationDistance inMiles = ([user distanceFromLocation:poi]) * 0.000621371192;
                    
                    NSString *distanceInFeet = [NSString stringWithFormat:@"%.f", round(2.0f * inFeet) / 2.0f];
                    NSString *distanceInMiles = [NSString stringWithFormat:@"%.2f", inMiles];
                    
                    currentPlace.name = currentPlaceDict[@"name"];
                    currentPlace.coordinate = poi.coordinate;
                    currentPlace.icon = currentPlaceDict[@"icon"];
                    currentPlace.placesId = currentPlaceDict[@"place_id"];
                    currentPlace.rating = currentPlaceDict[@"rating"];
                    currentPlace.vicinity = currentPlaceDict[@"vicinity"];
                    currentPlace.type = currentPlaceDict[@"types"];
                    currentPlace.reference = currentPlaceDict[@"reference"];
                    currentPlace.url = currentPlaceDict[@"url"];
                    currentPlace.addressComponents = currentPlaceDict[@"address_components"];
                    currentPlace.formattedAddress = currentPlaceDict[@"formatted_address"];
                    currentPlace.formattedPhoneNumber = currentPlaceDict[@"formatted_phone_number"];
                    currentPlace.website = currentPlaceDict[@"website"];
                    currentPlace.internationalPhoneNumber = currentPlaceDict[@"international_phone_number"];
                    currentPlace.searchTerms = currentPlaceDict[@""];
                    currentPlace.distanceInMilesString = distanceInMiles;
                    currentPlace.distanceInFeetString = distanceInFeet;
                    NSLog(@"currentplace: %@", currentPlace);
                    [_allPlaces addObject:currentPlace];
                    
                    [emptyVotingDict setObject:@(0) forKey:currentPlaceDict[@"name"]];
                    
                    NSString *urlStr;
                    if (currentPlaceDict[@"photos"] != nil) {
                        NSDictionary *photosDict = currentPlaceDict[@"photos"][0];
                        NSString *photoRef = photosDict[@"photo_reference"];
                        urlStr = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/photo?photoreference=%@&key=%@&sensor=false&maxwidth=320", photoRef, GOOGLE_API_KEY];
                    } else {
                        urlStr = currentPlaceDict[@"icon"];
                    }
                    
                    currentPlace.imageUrl = urlStr;
                    
                    NSURL * imageURL = [NSURL URLWithString:urlStr];
                    NSData * imageData = [NSData dataWithContentsOfURL:imageURL];
                    UIImage * image = [UIImage imageWithData:imageData];
                    if (image != nil) {
                        [restImages addObject:image];
                        currentPlace.image = image;
                    }
                    
                }
                _restaurantsTable.hidden = NO;
                _doneThisRound = FALSE;
                [self.restaurantsTable reloadData];

            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error: %@", error);
            }];
        }
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
        _nextPageToken = googlePlacesResults[@"next_page_token"];
        NSArray *placesData = googlePlacesResults[@"results"];
        int amount = 20;
            if (placesData.count < 20)
                amount = (int)placesData.count;
        _currentCellCount = amount;
        for (int i = 0; i < amount; i++) {
            NSDictionary *currentPlaceDict = placesData[i];
            NSLog(@"curr place %@", currentPlaceDict);
            GooglePlacesObject *currentPlace = [[GooglePlacesObject alloc] init];
            
            NSDictionary *geo = [currentPlaceDict objectForKey:@"geometry"];
            NSDictionary *loc = [geo objectForKey:@"location"];
            
            //Figure out Distance from POI and User
            CLLocation *poi = [[CLLocation alloc] initWithLatitude:[[loc objectForKey:@"lat"] doubleValue]  longitude:[[loc objectForKey:@"lng"] doubleValue]];
            CLLocation *user = [[CLLocation alloc] initWithLatitude:self.currentCentre.latitude longitude:self.currentCentre.longitude];
            CLLocationDistance inFeet = ([user distanceFromLocation:poi]) * 3.2808;
            
            CLLocationDistance inMiles = ([user distanceFromLocation:poi]) * 0.000621371192;
            
            NSString *distanceInFeet = [NSString stringWithFormat:@"%.f", round(2.0f * inFeet) / 2.0f];
            NSString *distanceInMiles = [NSString stringWithFormat:@"%.2f", inMiles];
            
            currentPlace.name = currentPlaceDict[@"name"];
            currentPlace.coordinate = poi.coordinate;
            currentPlace.icon = currentPlaceDict[@"icon"];
            currentPlace.placesId = currentPlaceDict[@"place_id"];
            currentPlace.rating = @"1";//currentPlaceDict[@"rating"];
            currentPlace.vicinity = currentPlaceDict[@"vicinity"];
            currentPlace.type = currentPlaceDict[@"types"];
            currentPlace.reference = currentPlaceDict[@"reference"];
            currentPlace.url = currentPlaceDict[@"url"];
            currentPlace.addressComponents = currentPlaceDict[@"address_components"];
            currentPlace.formattedAddress = currentPlaceDict[@"formatted_address"];
            currentPlace.formattedPhoneNumber = currentPlaceDict[@"formatted_phone_number"];
            currentPlace.website = currentPlaceDict[@"website"];
            currentPlace.internationalPhoneNumber = currentPlaceDict[@"international_phone_number"];
            currentPlace.searchTerms = currentPlaceDict[@""];
            currentPlace.distanceInMilesString = distanceInMiles;
            currentPlace.distanceInFeetString = distanceInFeet;
            NSLog(@"currentplace: %@", currentPlace);
            [_allPlaces addObject:currentPlace];
            
            [emptyVotingDict setObject:@(0) forKey:currentPlaceDict[@"name"]];
            
            NSString *urlStr;
            if (currentPlaceDict[@"photos"] != nil) {
                NSDictionary *photosDict = currentPlaceDict[@"photos"][0];
                NSString *photoRef = photosDict[@"photo_reference"];
                urlStr = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/photo?photoreference=%@&key=%@&sensor=false&maxwidth=320", photoRef, GOOGLE_API_KEY];
            } else {
                urlStr = currentPlaceDict[@"icon"];
            }
            
            currentPlace.imageUrl = urlStr;
            
            NSURL * imageURL = [NSURL URLWithString:urlStr];
            NSData * imageData = [NSData dataWithContentsOfURL:imageURL];
            UIImage * image = [UIImage imageWithData:imageData];
            if (image != nil) {
                [restImages addObject:image];
                currentPlace.image = image;
            }
            
        }
        _restaurantsTable.hidden = NO;
        [self.restaurantsTable reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //Finds location for the first time only and ONLY if it is ADMIN
    NSLog(@"going through it man %@", locations[0]);
    _currentLocation = locations[0];
    _currentCentre = _currentLocation.coordinate;
    _locationFound = TRUE;
    if (!_isRestInfoCalled) {
        if ([self.voteType isEqualToString:@"cafe"]) {
            _isRestInfoCalled = TRUE;
            [self getRestInfo:@"cafe"];
        }
        else {
            _isRestInfoCalled = TRUE;
            [self getRestInfo:@"food"];
        }
    }
    [locationManager stopUpdatingLocation];
}

-(void) searchForRestaurant {
    [self performSegueWithIdentifier:@"chooseaplace" sender:self];
}

-(void) addChosenRestaurant {
    if (self.customRestaurant != nil)
        [_allPlaces removeObjectAtIndex:0];

    [_allPlaces insertObject:self.customRestaurant atIndex:0];
    for (int i = 0; i < self.tickedIndexPaths.count; i++) {
        NSIndexPath *path = self.tickedIndexPaths[i];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:path.row+1 inSection:0];
        [self.tickedIndexPaths replaceObjectAtIndex:i withObject:indexPath];
    }
    [self.tickedIndexPaths addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
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
    
    GooglePlacesObject *chosenResponse = [_allPlaces objectAtIndex:indexPath.row];
    cell.backgroundColor = [UIColor clearColor];

    if (restImages.count > 0 && indexPath.row < restImages.count) {
        cell.image.image = restImages[indexPath.row];
    }
    cell.name.text = chosenResponse.name;
    
    /////////
    //Price level signs
    int priceLevel = [chosenResponse.rating intValue];
    if (!priceLevel) {
        priceLevel = 3;
    }
    NSString* priceString = @"";
    for (int i = 0; i < priceLevel; i++) {
        priceString = [priceString stringByAppendingString:@"$"];
    }
    cell.price.text = priceString;
    cell.distance.text = [NSString stringWithFormat:@"%@ mi.", chosenResponse.distanceInMilesString];
    cell.image.image = chosenResponse.image;
    
    ///////////
    //Add or remove checkmark
    if([self.tickedIndexPaths containsObject:indexPath])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [cell setBackgroundColor:[UIColor colorWithRed:255.0/255.0 green:228.0/255.0 blue:171.0/255.0 alpha:1.0]];
        /*[_restaurantIdArray addObject:chosenResponse.placesId];
        [_restaurantNameArray addObject:chosenResponse.name];
        [_restaurantPicArray addObject:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/photo?photoreference=%@&key=%@&sensor=false&maxwidth=320", chosenResponse.placesId, GOOGLE_API_KEY]];

        if (CLLocationCoordinate2DIsValid(chosenResponse.coordinate)) {
            [_restaurantXArray addObject:@(chosenResponse.coordinate.latitude)];
            [_restaurantYArray addObject:@(chosenResponse.coordinate.longitude)];
        } else {
            [_restaurantXArray addObject:@"NONE"];
            [_restaurantYArray addObject:@"NONE"];
        }
        //[_restaurantRatingArray addObject:chosenResponse[@"rating"]];*/
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
    
    _restaurantIdArray = [NSMutableArray new];
    _restaurantNameArray = [NSMutableArray new];
    _restaurantPicArray = [NSMutableArray new];
    _restaurantXArray = [NSMutableArray new];
    _restaurantYArray = [NSMutableArray new];
    _restaurantRatingArray = [NSMutableArray new];
    
    for (int i = 0; i < self.tickedIndexPaths.count; i++){
        int index = (int)[self.tickedIndexPaths[i] row];
        GooglePlacesObject *currentPlace = (GooglePlacesObject *) _allPlaces[index];
        [_restaurantIdArray addObject:currentPlace.placesId];
        [_restaurantNameArray addObject:currentPlace.name];
        [_restaurantPicArray addObject:currentPlace.reference];
        CLLocationCoordinate2D coor = currentPlace.coordinate;
        [_restaurantXArray addObject:@(coor.latitude)];
        [_restaurantYArray addObject:@(coor.longitude)];
        [_restaurantRatingArray addObject:@"1"];
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
