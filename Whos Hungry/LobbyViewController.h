//
//  LobbyViewController.h
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "HootLobby.h"

@interface LobbyViewController : UIViewController <FBFriendPickerDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *nameOfEvent;
@property (weak, nonatomic) IBOutlet UIButton *lunchBtn;
@property (weak, nonatomic) IBOutlet UIButton *dinnerBtn;
@property (weak, nonatomic) IBOutlet UIButton *coffeeBtn;
@property (weak, nonatomic) IBOutlet UIButton *drinksBtn;
- (IBAction)lunchBtnPressed:(id)sender;
- (IBAction)dinnerBtnPressed:(id)sender;
- (IBAction)coffeeBtnPressed:(id)sender;
- (IBAction)drinksBtnPressed:(id)sender;
- (IBAction)chooseWhenDate:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *whenButton;

@property (retain, nonatomic) FBFriendPickerViewController *friendPickerController;

@property (strong, nonatomic) NSString* voteType;
@property (strong, nonatomic) NSDate* whenDate;
@property UIColor* orangeColor;
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;

@property (strong, nonatomic) UIImageView* imageView;
@end
