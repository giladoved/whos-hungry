//
//  ViewController.m
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "LoginViewController.h"
#import "AFNetworking.h"
#import "AFHTTPRequestOperation.h"


static NSString * const BaseURLString = @"http://54.215.240.73:3000/";

@interface LoginViewController () {
    BOOL foundPushToken;
    id<FBGraphUser> foundUser;
    NSString *pushToken;
    BOOL registered;
}

@end

@implementation LoginViewController

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.loginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    self.loginButton.delegate = self;
    
    foundPushToken = YES;
    
    /*NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];*/
    
    //[self.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    
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
}

//fetched the facebook info
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    //NSString *firstTime = [[NSUserDefaults standardUserDefaults] stringForKey:@"firstTime"];
    //if (firstTime == nil) {
    NSLog(@"user: %@", user);
        NSLog(@"user id is :%@", user.objectID);
        NSLog(@"username is %@", user.name);
        pushToken = [[NSUserDefaults standardUserDefaults]
                                 stringForKey:@"pushToken"];
    
        NSLog(@"push token is %@", pushToken);

    if (pushToken != nil) {
        foundPushToken = YES;
        foundUser = user;
        
        [self.locationManager startUpdatingLocation];
    } else {
        [self performSegueWithIdentifier:@"mainScreenSegue" sender:self];
        [self.locationManager stopUpdatingLocation];
    }
    //}
}

-(void) registerUser:(id<FBGraphUser>)user andPushID:(NSString *)pushID{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSLog(@"username: %@", user.name);
    NSLog(@"object id: %@", user.objectID);
    NSLog(@"push ifddd: %@", pushID);
    NSLog(@"usergraph: %@", user);
    NSLog(@"pic is :%@", user.link);
   NSString *pic = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square", user.objectID];
    
    NSDictionary *params = @{
                             @"username": user.name,
                             @"picture":pic,
                             @"push_id":pushID,
                             @"facebook_id" : user.objectID,
                             @"location_x" : @(_currentCoor.latitude),
                             @"location_y" : @(_currentCoor.longitude),
                             @"os_type" : @"IOS"};
    [manager POST:[NSString stringWithFormat:@"%@apis/register", BaseURLString] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *results = (NSDictionary *)responseObject;
        NSLog(@"resultssS:S %@", results);
        [[NSUserDefaults standardUserDefaults] setObject:user forKey:@"fbuser"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        registered = YES;
        [self.locationManager stopUpdatingLocation];
        [self performSegueWithIdentifier:@"mainScreenSegue" sender:self];
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];

}

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
    [[NSUserDefaults standardUserDefaults] setObject:@"nah" forKey:@"firstTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (foundUser && foundPushToken && registered)
        [self performSegueWithIdentifier:@"mainScreenSegue" sender:self];
}

// Logged-out user experience
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    
}

// Handle possible errors that can occur during login
- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    NSString *alertMessage, *alertTitle;
    
    // If the user should perform an action outside of you app to recover,
    // the SDK will provide a message for the user, you just need to surface it.
    // This conveniently handles cases like Facebook password change or unverified Facebook accounts.
    if ([FBErrorUtility shouldNotifyUserForError:error]) {
        alertTitle = @"Facebook error";
        alertMessage = [FBErrorUtility userMessageForError:error];
        
        // This code will handle session closures that happen outside of the app
        // You can take a look at our error handling guide to know more about it
        // https://developers.facebook.com/docs/ios/errors
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
        
        // If the user has cancelled a login, we will do nothing.
        // You can also choose to show the user a message if cancelling login will result in
        // the user not being able to complete a task they had initiated in your app
        // (like accessing FB-stored information or posting to Facebook)
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
        NSLog(@"user cancelled login");
        
        // For simplicity, this sample handles other errors with a generic message
        // You can checkout our error handling guide for more detailed information
        // https://developers.facebook.com/docs/ios/errors
    } else {
        alertTitle  = @"Something went wrong";
        alertMessage = @"Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    
    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //Finds location for the first time only and ONLY if it is ADMIN
        _currentLocation = locations[0];
        _currentCoor = _currentLocation.coordinate;
        _locationFound = TRUE;
        NSLog(@"updated loc: %f, %f", _currentCoor.latitude, _currentCoor.longitude);
        if (foundUser != nil && foundPushToken) {
            NSLog(@"register user: %@", foundUser);
            [self registerUser:foundUser andPushID:pushToken];
        }
    
}

@end

