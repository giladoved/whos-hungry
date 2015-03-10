//
//  RestaurantsViewController.m
//  Who's Hungry
//
//  Created by administrator on 10/19/14.
//  Copyright (c) 2014 Who's Hungry. All rights reserved.
//

#import "RestaurantsViewControllerGeneric.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFNetworking.h"

#define GOOGLE_API_KEY @"AIzaSyAdB2MtdRCGDZNfIcd-uR22hkmCmniA6Oc"
#define GOOGLE_API_KEY_TWO @"AIzaSyBBQSs-ALwZ3Za7nioFPYXsByMDsMFq-68"
#define GOOGLE_API_KEY_THREE @"AIzaSyA6gixyCg9D-9nEJ8q7PQJiJ9Nk5LzcltI"
#define GOOGLE_API_KEY_FOUR @"AIzaSyDF0gj_1xGofM8BriMNH-uHbNYBVjI3g70"
#define LOBBY_KEY  @"currentlobby"

@interface RestaurantsViewControllerGeneric () {
    NSMutableArray *restaurantImages;
    NSDictionary *queryResult;
}

@end

@implementation RestaurantsViewControllerGeneric

@synthesize locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    _allPlaces = [NSMutableArray new];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search for a place...";
    self.restaurantsTable.backgroundColor = [UIColor clearColor];
    self.restaurantsTable.opaque = NO;
    self.restaurantsTable.backgroundView = nil;
    _locationFound = NO;
    _tickedIndexPaths = [[NSMutableArray alloc] init];
    
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
    
    if (!self.voteTypes || self.voteTypes.count == 0) {
        self.voteTypes = @[@"food", @"cafe"];
    }
    
    self.loader.hidesWhenStopped = YES;
    self.loader.hidden = YES;
    [self.searchBar becomeFirstResponder];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGPoint contentOffset = self.restaurantsTable.contentOffset;
    contentOffset.y += CGRectGetHeight(self.restaurantsTable.tableHeaderView.frame);
    self.restaurantsTable.contentOffset = contentOffset;
}

-(void)queryPlacesWithKeywords:(NSString *)keywords andTypes:(NSArray *)googleTypes {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters =
                                @{@"location": [NSString stringWithFormat:@"%f,%f", self.currentCoordinate.latitude, self.currentCoordinate.longitude],
                                 @"types":googleTypes,
                                 @"key":GOOGLE_API_KEY_FOUR,
                                  @"query":keywords,
                                  @"radius":@5000
                                 };
    [manager GET:@"https://maps.googleapis.com/maps/api/place/textsearch/json" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *googlePlacesResults = (NSDictionary *)responseObject;
        NSArray *placesData = googlePlacesResults[@"results"];
        int amount = 20;
            if (placesData.count < 20)
                amount = (int)placesData.count;
        for (int i = 0; i < amount; i++) {
            NSDictionary *currentPlaceDict = placesData[i];
            GooglePlacesObject *currentPlace = [[GooglePlacesObject alloc] init];
            
            NSDictionary *geo = [currentPlaceDict objectForKey:@"geometry"];
            NSDictionary *loc = [geo objectForKey:@"location"];
            
            //Figure out Distance from POI and User
            CLLocation *poi = [[CLLocation alloc] initWithLatitude:[[loc objectForKey:@"lat"] doubleValue]  longitude:[[loc objectForKey:@"lng"] doubleValue]];
            CLLocation *user = [[CLLocation alloc] initWithLatitude:self.currentCoordinate.latitude longitude:self.currentCoordinate.longitude];
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
                [restaurantImages addObject:image];
                currentPlace.image = image;
            }
            
            [_allPlaces addObject:currentPlace];
            
        }
        [self.restaurantsTable reloadData];
        [self.loader stopAnimating];
        self.loader.hidden = YES;
        NSLog(@"allplaces: %@", _allPlaces);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [self.loader stopAnimating];
        self.loader.hidden = YES;
    }];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    if (!_locationFound) {
        self.currentLocation = locations[0];
        self.currentCoordinate = self.currentLocation.coordinate;
        _locationFound = YES;
        [locationManager stopUpdatingLocation];
    }
}

# pragma mark - tableView methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    UILabel *messageLabel;
    if (self.allPlaces.count == 0) {
        messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        messageLabel.text = @"No places...";
        messageLabel.textColor = [UIColor blackColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont fontWithName:@"Palatino-Italic" size:20];
        [messageLabel sizeToFit];
        
        self.restaurantsTable.backgroundView = messageLabel;
        self.restaurantsTable.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        return 0;
    }
    else{
        self.restaurantsTable.backgroundView = nil;
        return _allPlaces.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"mainCell";
    RestaurantCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    GooglePlacesObject *chosenPlace = [_allPlaces objectAtIndex:indexPath.row];
    cell.backgroundColor = [UIColor clearColor];
    
    if (restaurantImages.count > 0 && indexPath.row < restaurantImages.count) {
        cell.image.image = restaurantImages[indexPath.row];
    }
    cell.name.text = chosenPlace.name;
    
    /////////
    //Price level signs
    int priceLevel = [chosenPlace.rating intValue];
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
    /*NSDictionary* loc  = [[NSDictionary alloc] init];
    loc = chosenResponse[@"geometry"][@"location"];
    CLLocation* placeLocation = [[CLLocation alloc] initWithLatitude:(CLLocationDegrees)[loc[@"lat"] doubleValue] longitude:(CLLocationDegrees)[loc[@"lng"] doubleValue]];
    NSLog(@"Latitude %@ and Longitude %@", loc[@"lat"], loc[@"lng"]);
    
    CLLocation* userLocation = [[CLLocation alloc] initWithLatitude:self.currentCoordinate.latitude longitude:self.currentCoordinate.longitude];
    float distance = [placeLocation distanceFromLocation:userLocation] / 1609.0;
    cell.distance.text = [NSString stringWithFormat:@"%1.2f mi.", distance];*/
    cell.distance.text = [NSString stringWithFormat:@"%@ mi.", chosenPlace.distanceInMilesString];
    //cell.image.image = chosenPlace.image;
    
    
    ///////////
    //Add or remove checkmark
    if([self.tickedIndexPaths containsObject:indexPath])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [cell setBackgroundColor:[UIColor colorWithRed:243.0/255.0 green:111.0/255.0 blue:69.0/255.0 alpha:1.0]];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    _allPlaces = [NSMutableArray new];
    restaurantImages = [NSMutableArray new];
    self.tickedIndexPaths = [NSMutableArray new];
    [self.loader startAnimating];
    self.loader.hidden = NO;
    [searchBar resignFirstResponder];
    [self queryPlacesWithKeywords:searchBar.text andTypes:self.voteTypes];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //If cell is not already in list of checkmark
    if(![self.tickedIndexPaths containsObject:indexPath]){
        //only one choosable restaurant
        self.tickedIndexPaths = [NSMutableArray new];
        [self.tickedIndexPaths addObject:indexPath];
    }
    
    //If cell is already selected, deselect it.
    else{
        [self.tickedIndexPaths removeObject:indexPath];
    }

    [self doneTapped:nil];
    //reload data again to display checkmarks
    //[self.restaurantsTable reloadData];
}

- (void)saveCustomObject:(GooglePlacesObject *)object key:(NSString *)key {
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:encodedObject forKey:key];
    [defaults synchronize];
}

- (IBAction)doneTapped:(id)sender {
    [self.locationManager stopUpdatingLocation];
    
    /*NSDictionary *chosenPlaceJSON = (NSDictionary *) [self.allPlaces objectAtIndex:[[self.tickedIndexPaths objectAtIndex:0] row]];
    GooglePlacesObject *chosenRestaurant = [GooglePlacesObject new];
    
    NSDictionary *geo = [chosenPlaceJSON objectForKey:@"geometry"];
    NSDictionary *loc = [geo objectForKey:@"location"];
    CLLocation *poi = [[CLLocation alloc] initWithLatitude:[[loc objectForKey:@"lat"] doubleValue]  longitude:[[loc objectForKey:@"lng"] doubleValue]];
    CLLocation *user = [[CLLocation alloc] initWithLatitude:self.currentCoordinate.latitude longitude:self.currentCoordinate.longitude];
    CLLocationDistance inFeet = ([user distanceFromLocation:poi]) * 3.2808;
    CLLocationDistance inMiles = ([user distanceFromLocation:poi]) * 0.000621371192;
    NSString *distanceInFeet = [NSString stringWithFormat:@"%.f", round(2.0f * inFeet) / 2.0f];
    NSString *distanceInMiles = [NSString stringWithFormat:@"%.2f", inMiles];
    
    chosenRestaurant.name = chosenPlaceJSON[@"name"];
    chosenRestaurant.coordinate = poi.coordinate;
    chosenRestaurant.icon = chosenPlaceJSON[@"icon"];
    chosenRestaurant.placesId = chosenPlaceJSON[@"place_id"];
    chosenRestaurant.rating = chosenPlaceJSON[@"rating"];
    chosenRestaurant.vicinity = chosenPlaceJSON[@"vicinity"];
    chosenRestaurant.type = chosenPlaceJSON[@"types"];
    chosenRestaurant.reference = chosenPlaceJSON[@"reference"];
    chosenRestaurant.url = chosenPlaceJSON[@"url"];
    chosenRestaurant.addressComponents = chosenPlaceJSON[@"address_components"];
    chosenRestaurant.formattedAddress = chosenPlaceJSON[@"formatted_address"];
    chosenRestaurant.formattedPhoneNumber = chosenPlaceJSON[@"formatted_phone_number"];
    chosenRestaurant.website = chosenPlaceJSON[@"website"];
    chosenRestaurant.internationalPhoneNumber = chosenPlaceJSON[@"international_phone_number"];
    chosenRestaurant.searchTerms = chosenPlaceJSON[@""];
    chosenRestaurant.distanceInFeetString = distanceInFeet;
    chosenRestaurant.distanceInMilesString = distanceInMiles;*/
    
    self.chosenRestaurant = (GooglePlacesObject *)[self.allPlaces objectAtIndex:[[self.tickedIndexPaths objectAtIndex:0] row]];
    
    [self saveCustomObject:self.chosenRestaurant key:@"chosenRestaurant"];
    
    [self dismissViewControllerAnimated:YES completion:self.onCompletion];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Chosen Restaurant"
                                                    message:[NSString stringWithFormat:@"You chose %@", self.chosenRestaurant.name]
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}


@end
