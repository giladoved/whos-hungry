//
//  SummaryViewController.h
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//



#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import <MapKit/MapKit.h>
#import "HootLobby.h"
#import <CoreLocation/CoreLocation.h>
#import "AFNetworking.h"
#import "AFHTTPRequestOperation.h"
#import "UpDownVoteView.h"
#import "SWTableViewCell.h"
#import "RSVPFriendsTableViewCell.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)


@interface SummaryViewController : UIViewController<CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate, SWTableViewCellDelegate> {
    CLLocationManager *locationManager;
}

@property __block NSString *facebookID;
@property BOOL imagesRemoved;
@property (nonatomic, retain) NSTimer *theTimer;
@property (weak, nonatomic) IBOutlet UILabel *winningRestaurantLabel;

@property (assign, nonatomic) BOOL active;
@property (assign, nonatomic) BOOL loaded;
@property (assign, nonatomic) BOOL isFromMain;
@property BOOL isSummary;

@property (weak, nonatomic) IBOutlet UILabel *whenTimeLbl;

@property (strong, nonatomic) RSVPFriendsTableViewCell* rsvpCell;
@property (weak, nonatomic) IBOutlet UILabel *summaryTitleLbl;
@property (strong, nonatomic) HootLobby* currentLobby;
@property (strong, nonatomic) NSMutableArray* allPlaces;
@property (strong, nonatomic) NSMutableArray* indexPathArray;
@property (strong, nonatomic) IBOutlet UITableView *restaurantTable;
@property (weak, nonatomic) IBOutlet UITableView *friendsGoingTable;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocation* currentLocation;
- (IBAction)goHome:(id)sender;
-(void)initWithHootLobby:(HootLobby *)hootlobby withOption:(int)accessType;
@property (strong, nonatomic) IBOutlet UIView *votingCompleteView;

@property (strong, nonatomic) IBOutlet UIView *votingIncompleteView;

@property BOOL isLobbyDone;
@property NSMutableArray* totalVoteArray;
@property NSMutableArray* voteStatusArray;

@property BOOL isInitWithHootLobby;
@property BOOL isExpirationUpdated;

@property BOOL isTimerReadyToBeActivated;
@property int accessType;
@property bool changetyepdewd;
@property (strong, nonatomic) NSString* groupid;
@property (strong, nonatomic) NSString* voteid;

-(void) updateVoteCount:(NSNotification *)noti;
- (IBAction)suggestAPlace:(id)sender;

@end
