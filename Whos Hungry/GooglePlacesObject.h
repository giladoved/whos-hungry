//
//  PlaceObject.h
//  Whos Hungry
//
//  Created by Gilad Oved on 3/5/15.
//  Copyright (c) 2015 WHK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface GooglePlacesObject : NSObject

@property (nonatomic, strong) NSString    *placesId;
@property (nonatomic, strong) NSString    *reference;
@property (nonatomic, strong) NSString    *name;
@property (nonatomic, strong) NSString    *icon;
@property (nonatomic, strong) NSString    *rating;
@property (nonatomic, strong) NSString    *vicinity;
@property (nonatomic, strong) NSArray     *type;
@property (nonatomic, strong) NSString    *url;
@property (nonatomic, strong) NSArray     *addressComponents;
@property (nonatomic, strong) NSString    *formattedAddress;
@property (nonatomic, strong) NSString    *formattedPhoneNumber;
@property (nonatomic, strong) NSString    *website;
@property (nonatomic, strong) NSString    *internationalPhoneNumber;
@property (nonatomic, strong) NSString      *searchTerms;
@property (nonatomic, assign) CLLocationCoordinate2D    coordinate;
@property (nonatomic, strong) NSString    *distanceInFeetString;
@property (nonatomic, strong) NSString    *distanceInMilesString;
@property (nonatomic, strong) UIImage    *image;
@property (nonatomic, strong) NSString    *imageUrl;


@end
