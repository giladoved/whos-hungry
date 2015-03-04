//
//  RestaurantCell.h
//  Who's Hungry
//
//  Created by administrator on 10/19/14.
//  Copyright (c) 2014 Who's Hungry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RestaurantCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet UILabel *price;
@property (weak, nonatomic) IBOutlet UIView *cellView;



@end
