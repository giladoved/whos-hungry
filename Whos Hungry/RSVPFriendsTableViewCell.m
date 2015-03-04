//
//  RSVPFriendsTableViewCell.m
//  Whos Hungry
//
//  Created by Gilad Oved on 11/22/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "RSVPFriendsTableViewCell.h"

@implementation RSVPFriendsTableViewCell

- (void)awakeFromNib {
    _firstImage.layer.cornerRadius = 25.0;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)openOptions:(id)sender {
    if (_isOpen) {
        [super hideUtilityButtonsAnimated:TRUE];
        _isOpen = FALSE;
        NSLog(@"It is closed");
    }
    else{
        [super showRightUtilityButtonsAnimated:TRUE];
        _isOpen = TRUE;
        NSLog(@"It is open");
    }
}


@end
