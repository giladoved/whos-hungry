//
//  LobbyViewController.m
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "LobbyViewController.h"
#import "ActionSheetDatePicker.h"
#import "SummaryViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "RestaurantsViewController.h"

#define LOBBY_KEY  @"currentlobby"

@interface LobbyViewController () {
    int lobbylength;
    
    UIDatePicker *theDatePicker;
    UIView *pickerView;
    UIColor *greenColor;
}

@end

@implementation LobbyViewController

typedef enum accessType {
    ADMIN_FIRST,
    ADMIN_RETURNS,
    FRIEND_FIRST,
    FRIEND_RETURNS
} accessType;

-(void)addImageOnTopOfTheNavigationBar {
    //UIImage* tempImage = [UIImage imageNamed:@"logosquare.png"];
    _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logosquare_transparent.png"]];
    [_imageView sizeToFit];
    _imageView.frame = CGRectMake(self.navigationController.navigationBar.frame.size.width/2.0 - self.navigationController.navigationBar.frame.size.height/2.0, self.navigationController.navigationBar.frame.origin.y, self.navigationController.navigationBar.frame.size.height, self.navigationController.navigationBar.frame.size.height); //set the proper frame here
    [self.navigationController.view addSubview:_imageView];
    _imageView.alpha = 0.0f;
    [UIView animateWithDuration:0.3 delay:0.1 options:UIViewAnimationOptionCurveEaseIn animations:^{
        _imageView.alpha = 1.0f;
    } completion:^(BOOL finished) {
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _orangeColor = [UIColor colorWithRed:(232.0/255.0) green:(111.0/255.0) blue:(73.0/255.0) alpha:1.0];
    greenColor = [UIColor colorWithRed:(91.0/255.0) green:(186.0/255.0) blue:(71.0/255.0) alpha:1.0];
    
    NSDate *thirtyMinsLater = [[NSDate date] dateByAddingTimeInterval:60*30];
    _whenDate = thirtyMinsLater;
    UIBarButtonItem *inviteFriendsBtn = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Invite Friends"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(inviteFriends:)];
     
    self.navigationItem.rightBarButtonItem = inviteFriendsBtn;
    
    self.nameOfEvent.delegate = self;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addImageOnTopOfTheNavigationBar];
    //if (_voteType == nil)
        //[self lunchBtnPressed:nil];
}

- (void) viewWillDisappear:(BOOL)animated{
    [_imageView removeFromSuperview];
}

-(NSDate*)dateByAddingMinutes:(NSInteger)minutes toDate:(NSDate*)date
{
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setMinute:minutes];
    
    return [[NSCalendar currentCalendar]
            dateByAddingComponents:components toDate:date options:0];
}

-(IBAction)inviteFriends:(id)sender {
    //Transfer WhenTime to HootLobby
    //Transfer voteType to HootLobby
    HootLobby* tempLobby = [self loadCustomObjectWithKey:LOBBY_KEY];

    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    //[dateComponents setDay:-1];
    NSDate *realWhenDate = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:_whenDate options:0];
    //double secondsInAMinute = 60;
    tempLobby.expirationTime = _whenDate;
    NSLog(@"time before is %@",tempLobby.expirationTime);
    /*
    if ([realWhenDate timeIntervalSinceDate:[NSDate date]] / secondsInAMinute > 40) {
        NSDate *newDate = [tempLobby.expirationTime dateByAddingTimeInterval:-60*20];
        tempLobby.expirationTime = newDate;
        NSLog(@"time is %@",tempLobby.expirationTime);

    }
    else{
        NSDate *newDate = [tempLobby.expirationTime dateByAddingTimeInterval:(-60*([realWhenDate timeIntervalSinceDate:[NSDate date]] / secondsInAMinute) / 2)];
        tempLobby.expirationTime = newDate;
        NSLog(@"time is %@",tempLobby.expirationTime);
    }
    */
    if (!tempLobby) {
        tempLobby = [HootLobby new];
        NSLog(@"Current Lobby is empty");
        tempLobby.meetingTime = realWhenDate;
        tempLobby.voteType = _voteType;
        tempLobby.name = self.nameOfEvent.text;
        [self saveCustomObject:tempLobby];
    }
    else{
        NSLog(@"Current Lobby has DATA!");
        tempLobby.meetingTime = realWhenDate;
        tempLobby.voteType = _voteType;
        tempLobby.name = self.nameOfEvent.text;
        [self saveCustomObject:tempLobby];
    }
    
    
    if (!FBSession.activeSession.isOpen) {
        // if the session is closed, then we open it here, and establish a handler for state changes
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"user_friends"]
                                           allowLoginUI:YES
                                      completionHandler:^(FBSession *session,
                                                          FBSessionState state,
                                                          NSError *error) {
                                          
                                          NSLog(@"session: %@", session.accessTokenData.accessToken);
                                          
                                          if (error) {
                                              UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                                  message:error.localizedDescription
                                                                                                 delegate:nil
                                                                                        cancelButtonTitle:@"OK"
                                                                                        otherButtonTitles:nil];
                                              [alertView show];
                                          } else if (session.isOpen) {
                                              [self inviteFriends:sender];
                                          }
                                      }];
        return;
    }
    
    if (self.friendPickerController == nil) {
        // Create friend picker, and get data loaded into it.
        self.friendPickerController = [[FBFriendPickerViewController alloc] init];
        self.friendPickerController.title = @"Pick Friends";
        self.friendPickerController.delegate = self;
    }
    
    [self.friendPickerController loadData];
    [self.friendPickerController clearSelection];
    
    [self presentViewController:self.friendPickerController animated:YES completion:nil];
}

- (void)facebookViewControllerDoneWasPressed:(id)sender {
    //NSMutableString *text = [[NSMutableString alloc] init];
    
    // we pick up the users from the selection, and create a string that we use to update the text view
    // at the bottom of the display; note that self.selection is a property inherited from our base class
    NSMutableArray *chosenFriends = [NSMutableArray new];
    
    for (id<FBGraphUser> user in self.friendPickerController.selection) {
        [chosenFriends addObject:user.objectID];
    }
    
    HootLobby* tempLobby = [self loadCustomObjectWithKey:LOBBY_KEY];
    if (!tempLobby) {
        NSLog(@"Current Lobby is empty");
        tempLobby = [HootLobby new];
        tempLobby.facebookbInvitatitions = chosenFriends;
        [self saveCustomObject:tempLobby];
    }
    else{
        NSLog(@"Current Lobby has DATA!");
        tempLobby.facebookbInvitatitions = chosenFriends;
        [self saveCustomObject:tempLobby];
    }
    
    if (chosenFriends.count > 0) {
        [self presentSummaryVC];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Select Friends!" message:@"You have to select some friends first!" delegate:nil cancelButtonTitle: @"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)facebookViewControllerCancelWasPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)presentSummaryVC {
    SummaryViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SummaryViewController"];
    vc.accessType = ADMIN_FIRST;
    [self.friendPickerController presentViewController:vc animated:YES completion:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return YES;
}

- (IBAction)chooseWhenDate:(id)sender {
    [ActionSheetDatePicker showPickerWithTitle:@"" datePickerMode:UIDatePickerModeDateAndTime selectedDate:_whenDate doneBlock:^(ActionSheetDatePicker *picker, id selectionDate, id origin) {
        picker.minimumDate = [NSDate new];
        NSLog(@"when date is %@", selectionDate);
        _whenDate = (NSDate *)selectionDate;
        if([_whenDate timeIntervalSinceDate:[NSDate new]] > 0) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"hh:mm"];
            NSString *formattedDateString = [dateFormatter stringFromDate:_whenDate];
            NSLog(@"formattedDateString: %@", formattedDateString);
            [_whenButton setTitle:[NSString stringWithFormat:@"When: %@", formattedDateString] forState:UIControlStateNormal];
        } else {
            [_whenButton setTitle:@"When: Invalid time..." forState:UIControlStateNormal];
        }
    } cancelBlock:nil origin:sender];
    
    
    /*NSInteger minuteInterval = 5;
    //clamp date
    NSInteger referenceTimeInterval = (NSInteger)[self.whenDate timeIntervalSinceReferenceDate];
    NSInteger remainingSeconds = referenceTimeInterval % (minuteInterval *60);
    NSInteger timeRoundedTo5Minutes = referenceTimeInterval - remainingSeconds;
    if(remainingSeconds>((minuteInterval*60)/2)) {/// round up
        timeRoundedTo5Minutes = referenceTimeInterval +((minuteInterval*60)-remainingSeconds);
    }
    
    self.whenDate = [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)timeRoundedTo5Minutes];
    
    ActionSheetDatePicker *datePicker = [[ActionSheetDatePicker alloc] initWithTitle:@"Select a time" datePickerMode:UIDatePickerModeTime selectedDate:self.whenDate target:self action:@selector(timeWasSelected:element:) origin:sender];
    datePicker.minuteInterval = minuteInterval;
    //[datePicker addCustomButtonWithTitle:@"value" value:[NSDate date]];
    //  [datePicker addCustomButtonWithTitle:@"sel" target:self selector:@selector(dateSelector:)];
    //  [datePicker addCustomButtonWithTitle:@"Block" actionBlock:^{
    //      NSLog(@"Block invoked");
    //  }];
    [datePicker showActionSheetPicker];*/
}

-(void)timeWasSelected:(NSDate *)selectedTime element:(id)element {
    _whenDate = selectedTime;
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"hh:mm"];
    [self.whenButton setTitle:[dateFormatter stringFromDate:selectedTime] forState:UIControlStateNormal];
}

- (IBAction)lunchBtnPressed:(id)sender {
    self.lunchBtn.layer.borderColor = _orangeColor.CGColor;
    self.lunchBtn.layer.borderWidth = 3.0f;
    self.dinnerBtn.layer.borderColor = _orangeColor.CGColor;
    self.dinnerBtn.layer.borderWidth = 0.0f;
    self.coffeeBtn.layer.borderColor = _orangeColor.CGColor;
    self.coffeeBtn.layer.borderWidth = 0.0f;
    self.drinksBtn.layer.borderColor = _orangeColor.CGColor;
    self.drinksBtn.layer.borderWidth = 0.0f;
    _voteType = @"lunch";
}

- (IBAction)dinnerBtnPressed:(id)sender {
    self.lunchBtn.layer.borderColor = _orangeColor.CGColor;
    self.lunchBtn.layer.borderWidth = 0.0f;
    self.dinnerBtn.layer.borderColor = _orangeColor.CGColor;
    self.dinnerBtn.layer.borderWidth = 3.0f;
    self.coffeeBtn.layer.borderColor = _orangeColor.CGColor;
    self.coffeeBtn.layer.borderWidth = 0.0f;
    self.drinksBtn.layer.borderColor = _orangeColor.CGColor;
    self.drinksBtn.layer.borderWidth = 0.0f;
    _voteType = @"dinner";
}

- (IBAction)coffeeBtnPressed:(id)sender {
    self.lunchBtn.layer.borderColor = _orangeColor.CGColor;
    self.lunchBtn.layer.borderWidth = 0.0f;
    self.dinnerBtn.layer.borderColor = _orangeColor.CGColor;
    self.dinnerBtn.layer.borderWidth = 0.0f;
    self.coffeeBtn.layer.borderColor = _orangeColor.CGColor;
    self.coffeeBtn.layer.borderWidth = 3.0f;
    self.drinksBtn.layer.borderColor = _orangeColor.CGColor;
    self.drinksBtn.layer.borderWidth = 0.0f;
    _voteType = @"cafe";
}

- (IBAction)drinksBtnPressed:(id)sender {
    self.lunchBtn.layer.borderColor = _orangeColor.CGColor;
    self.lunchBtn.layer.borderWidth = 0.0f;
    self.dinnerBtn.layer.borderColor = _orangeColor.CGColor;
    self.dinnerBtn.layer.borderWidth = 0.0f;
    self.coffeeBtn.layer.borderColor = _orangeColor.CGColor;
    self.coffeeBtn.layer.borderWidth = 0.0f;
    self.drinksBtn.layer.borderColor = _orangeColor.CGColor;
    self.drinksBtn.layer.borderWidth = 3.0f;
    _voteType = @"drinks";
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"WhereSegue"]) {
        UINavigationController *nav = [segue destinationViewController];
        RestaurantsViewController *restVC = (RestaurantsViewController *)nav.topViewController;
        if (_voteType == nil) {
            _voteType = @"lunch";
        }
        restVC.voteType = _voteType;
    }
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
