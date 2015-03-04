//
//  HootGroupCell.h
//  Whos Hungry
//
//  Created by administrator on 11/5/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HootGroupCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *whereLabel;
@property (strong, nonatomic) IBOutlet UILabel *whenLabel;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (strong, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (strong, nonatomic) IBOutlet UIImageView *friendsImage;
@property (strong, nonatomic) IBOutlet UIImageView *hostImage;

@end
