//
//  HootLobby.h
//  Whos Hungry
//
//  Created by administrator on 11/11/14.
//  Copyright (c) 2014 WHK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HootLobby : NSObject <NSCopying>

@property (strong, nonatomic) NSNumber* groupid;

@property (strong, nonatomic) NSString* facebookId;
@property (strong, nonatomic) NSString* facebookPic;
@property (strong, nonatomic) NSString* facebookName;

@property (strong, nonatomic) NSMutableArray* facebookbInvitatitions;

@property (strong, nonatomic) NSMutableArray* placesIdArray;
@property (strong, nonatomic) NSMutableArray* placesNamesArray;
@property (strong, nonatomic) NSMutableArray* placesPicsArray;
@property (strong, nonatomic) NSMutableArray* placesXArray;
@property (strong, nonatomic) NSMutableArray* placesYArray;
@property (strong, nonatomic) NSMutableArray* placesRankingArray;

@property (strong, nonatomic) NSDate* expirationTime;
@property (strong, nonatomic) NSDate* meetingTime;
@property (strong, nonatomic) NSString* voteType;
@property (strong, nonatomic) NSNumber* voteid;
@property (strong, nonatomic) NSNumber* goingCount;

@property (strong, nonatomic) NSString* winnerRestID;
@property (strong, nonatomic) NSString* winnerRestName;
@property (strong, nonatomic) NSString* winnerRestPic;
@property (strong, nonatomic) NSNumber* winnerRestX;
@property (strong, nonatomic) NSNumber* winnerRestY;

@property (strong, nonatomic) NSString* name;

@property (strong, nonatomic) NSMutableArray* rsvpArray;
@property (nonatomic, assign) BOOL didAdminCreate;

@end
