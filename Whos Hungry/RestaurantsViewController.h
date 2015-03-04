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
#import "GooglePlacesObject.h"
#import <FacebookSDK/FacebookSDK.h>


#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@interface RestaurantsViewController : UIViewController <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>

@property CLLocationManager *locationManager;
@property CLLocationCoordinate2D currentCentre;
@property CLLocation *currentLocation;
@property BOOL locationFound;
@property int currenDist;
@property NSMutableArray* tickedIndexPaths;
@property (strong, nonatomic) NSString* voteType;

@property (weak, nonatomic) IBOutlet UITableView *restaurantsTable;
@property NSMutableArray* allPlaces;

- (IBAction)doneTapped:(id)sender;

@property int selectionCount;
@property BOOL isSelected;
@property BOOL isAdmin;

@property (nonatomic, strong) GooglePlacesObject *customRestaurant;

@property NSMutableArray* restaurantIdArray;
@property NSMutableArray* restaurantNameArray;
@property NSMutableArray* restaurantPicArray;
@property NSMutableArray* restaurantXArray;
@property NSMutableArray* restaurantYArray;
@property NSMutableArray* restaurantRatingArray;
@property NSString* facebookId;
@property NSString* facebookName;

@end
