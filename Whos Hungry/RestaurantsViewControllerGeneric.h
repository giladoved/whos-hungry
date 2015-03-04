//
//  RestaurantsViewController.h
//  Who's Hungry
//
//  Created by administrator on 10/19/14.
//  Copyright (c) 2014 Who's Hungry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "RestaurantCell.h"
#import "HootLobby.h"
#import <FacebookSDK/FacebookSDK.h>
#import "GooglePlacesObject.h"


#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@interface RestaurantsViewControllerGeneric : UIViewController <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property CLLocationManager *locationManager;
@property CLLocation *currentLocation;
@property CLLocationCoordinate2D currentCoordinate;
@property BOOL locationFound;
@property (strong, nonatomic) NSArray* voteTypes;

@property (weak, nonatomic) IBOutlet UITableView *restaurantsTable;
@property NSMutableArray* allPlaces;
@property NSMutableArray* tickedIndexPaths;
@property (nonatomic, strong) GooglePlacesObject *chosenRestaurant;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

- (IBAction)doneTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loader;

@property (copy)void (^onCompletion)(void);


@end
