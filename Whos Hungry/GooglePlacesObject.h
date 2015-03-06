//
//  GooglePlacesObject.h
// 
// Copyright 2011 Joshua Drew
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define kGOOGLE_API_KEY @"AIzaSyAdB2MtdRCGDZNfIcd-uR22hkmCmniA6Oc"

@interface GooglePlacesObject : NSObject
{
    /*
    NSString    *placesId;
    NSString    *reference;
    NSString    *name;
    NSString    *icon;
    NSString    *rating;
    NSString    *vicinity;
    NSArray     *type; //array
    NSString    *url;
    NSArray     *addressComponents; //array
    NSString    *formattedAddress;
    NSString    *formattedPhoneNumber;
    NSString    *website;
    NSString    *internationalPhoneNumber;
    NSString    *searchTerms;
    CLLocationCoordinate2D coordinate;
    //NEW
    NSString    *distanceInFeetString;
    NSString    *distanceInMilesString;
    */
}

@property (nonatomic, retain) NSString    *placesId;
@property (nonatomic, retain) NSString    *reference;
@property (nonatomic, retain) NSString    *name;
@property (nonatomic, retain) NSString    *icon;
@property (nonatomic, retain) NSString    *rating;
@property (nonatomic, retain) NSString    *vicinity;
@property (nonatomic, retain) NSArray     *type; //array
@property (nonatomic, retain) NSString    *url;
@property (nonatomic, retain) NSArray     *addressComponents; //array
@property (nonatomic, retain) NSString    *formattedAddress;
@property (nonatomic, retain) NSString    *formattedPhoneNumber;
@property (nonatomic, retain) NSString    *website;
@property (nonatomic, retain) NSString    *internationalPhoneNumber;
@property (nonatomic, retain) NSString      *searchTerms;
@property (nonatomic, assign) CLLocationCoordinate2D    coordinate;
//NEW
@property (nonatomic, retain) NSString    *distanceInFeetString;
@property (nonatomic, retain) NSString    *distanceInMilesString;


- (id)initWithJsonResultDict:(NSDictionary *)jsonResultDict andUserCoordinates:(CLLocationCoordinate2D)userCoords;
- (id)initWithJsonResultDict:(NSDictionary *)jsonResultDict searchTerms:(NSString *)terms andUserCoordinates:(CLLocationCoordinate2D)userCoords;

- (id)initWithName:(NSString *)name
          latitude:(double)lt
         longitude:(double)lg
         placeIcon:(NSString *)icn
            rating:(NSString *)rate
          vicinity:(NSString *)vic
              type:(NSString *)typ
         reference:(NSString *)ref
               url:(NSString *)www
 addressComponents:(NSString *)addComp
  formattedAddress:(NSArray *)fAddrss
formattedPhoneNumber:(NSString *)fPhone
           website:(NSString *)web
internationalPhone:(NSString *)intPhone
       searchTerms:(NSString *)search
    distanceInFeet:(NSString *)distanceFeet
   distanceInMiles:(NSString *)distanceMiles;



@end