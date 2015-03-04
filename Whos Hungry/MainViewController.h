//
//  MainViewController.h
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *friendsBtn;
@property (weak, nonatomic) IBOutlet UIButton *publicBtn;

@property (strong, nonatomic) UIImageView* imageView;
@property (strong, nonatomic) UIRefreshControl* refreshControl;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *coverIndicator;
@property (strong, nonatomic) IBOutlet UIView *coverView;
- (IBAction)friendsBtnPressed:(id)sender;
- (IBAction)publicBtnPressed:(id)sender;

@property CGPoint startLocation;

@end
  