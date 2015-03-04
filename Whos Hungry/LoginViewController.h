//
//  ViewController.h
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import <CoreLocation/CoreLocation.h>

@interface LoginViewController : UIViewController <FBLoginViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet FBLoginView *loginButton;


@property CLLocationManager *locationManager;
@property CLLocationCoordinate2D currentCoor;
@property CLLocation *currentLocation;
@property BOOL locationFound;

@end

