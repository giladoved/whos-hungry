//
//  UpDownVoteView.m
//  Whos Hungry
//
//  Created by Gilad Oved on 11/13/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import "UpDownVoteView.h"

@implementation UpDownVoteView

- (IBAction)voteUp:(id)sender {
    self.upBtn.userInteractionEnabled = NO;
    self.downBtn.userInteractionEnabled = NO;
    self.upBtn.enabled = NO;
    self.downBtn.enabled = NO;
    NSLog(@"STILL UP!!!");
    [self disableVoting];
    self.stateInt++;

    self.stateInt = MIN(self.stateInt, 1);
    if (self.stateInt == 0) {
        self.votes++;
        self.upBtn.enabled = YES;
        self.downBtn.enabled = YES;
    } else if (self.stateInt == 1) {
        self.upBtn.enabled = NO;
        self.downBtn.enabled = YES;
        self.votes++;
    }
    self.status = @"+1";
    self.voteLbl.text = [NSString stringWithFormat:@"%i", self.votes];
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:self
                                                         forKey:@"sender"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"makeVote" object:nil userInfo:dataDict];
}

- (IBAction)voteDown:(id)sender {
    self.upBtn.userInteractionEnabled = NO;
    self.downBtn.userInteractionEnabled = NO;
    self.upBtn.enabled = NO;
    self.downBtn.enabled = NO;
    [self disableVoting];
    self.stateInt--;
    self.stateInt = MAX(self.stateInt, -1);
    if (self.stateInt == -1) {
        self.upBtn.enabled = YES;
        self.downBtn.enabled = NO;
        self.votes--;
    } else if (self.stateInt == 0) {
        self.upBtn.enabled = YES;
        self.downBtn.enabled = YES;
        self.votes--;
        self.upBtn.enabled = YES;
        self.downBtn.enabled = YES;
    }
    
    
    self.status = @"-1";
    self.voteLbl.text = [NSString stringWithFormat:@"%i", self.votes];
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:self
                                                         forKey:@"sender"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"makeVote" object:nil userInfo:dataDict];
}

-(void) disableVoting {
    NSLog(@"DISABLED");
    self.upBtn.userInteractionEnabled = NO;
    self.downBtn.userInteractionEnabled = NO;
}

-(void) enableDisable {
    self.upBtn.userInteractionEnabled = YES;
    self.downBtn.userInteractionEnabled = YES;
    self.downBtn.enabled = YES;
    self.upBtn.enabled = YES;
    if (self.stateInt == -1) {
        self.upBtn.enabled = YES;
        self.downBtn.enabled = NO;
    } else if (self.stateInt == 0) {
        self.upBtn.enabled = YES;
        self.downBtn.enabled = YES;
    } else if (self.stateInt == 1) {
        self.upBtn.enabled = NO;
        self.downBtn.enabled = YES;
    }
}




@end
