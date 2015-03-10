//
//  UpDownVoteView.h
//  Whos Hungry
//
//  Created by Gilad Oved on 11/13/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UpDownVoteView : UITableViewCell
@property (nonatomic, assign) int votes;
//@property (nonatomic, assign) BOOL voted;
@property (nonatomic, assign) int stateInt; //1, 0, -1
@property (nonatomic, assign) NSString* status; //+1, -1
@property (nonatomic, assign) NSString* state; //"1", "0", "-1"
@property(nonatomic, assign) int index;


@property (weak, nonatomic) IBOutlet UIButton *upBtn;
@property (weak, nonatomic) IBOutlet UIButton *downBtn;
@property (weak, nonatomic) IBOutlet UILabel *voteLbl;
@property (strong, nonatomic) IBOutlet UILabel *restaurantLabel;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
- (IBAction)voteUp:(id)sender;
- (IBAction)voteDown:(id)sender;
-(void) enableDisable;
@end
