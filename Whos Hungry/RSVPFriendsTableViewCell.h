//
//  RSVPFriendsTableViewCell.h
//  Whos Hungry
//
//  Created by Gilad Oved on 11/22/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

@interface RSVPFriendsTableViewCell : SWTableViewCell
@property (strong, nonatomic) IBOutlet UIButton *rsvpButton;
- (IBAction)openOptions:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *arrowButton;
@property int isGoing;
@property (strong, nonatomic) IBOutlet UIImageView *firstImage;
@property (strong, nonatomic) IBOutlet UIImageView *secondImage;
@property (strong, nonatomic) IBOutlet UIImageView *thirdImage;
@property (strong, nonatomic) IBOutlet UIImageView *fourthImage;
@property (strong, nonatomic) IBOutlet UILabel *extraLabel;
@property BOOL isOpen;
@end
