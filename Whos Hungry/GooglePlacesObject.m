//
//  GooglePlacesObject.m
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


/*
***************
 https://github.com/jdruid/Google-Places-for-iOS-5
***************
*/

#import "GooglePlacesObject.h"

@implementation GooglePlacesObject

-(id)initWithName:(NSString *)theName 
         latitude:(double)lt 
        longitude:(double)lg 
        placeIcon:(NSString *)icn 
           rating:(NSString *)rate 
         vicinity:(NSString *)vic 
            types:(NSArray *)typ
        reference:(NSString *)ref
              url:(NSString *)www 
addressComponents:(NSArray *)addComp 
 formattedAddress:(NSString *)fAddrss 
formattedPhoneNumber:(NSString *)fPhone
website:(NSString *)web 
internationalPhone:(NSString *)intPhone
      searchTerms:(NSString *)search
distanceInFeet:(NSString *)distanceFeet 
  distanceInMiles:(NSString *)distanceMiles
{
    
    if (self = [super init])
    {
        [self setName:theName];
        [self setIcon:icn];
        [self setRating:rate];
        [self setVicinity:vic];
        [self setTypes:typ];
        [self setReference:ref];
        [self setUrl:www];
        [self setAddressComponents:addComp];
        [self setFormattedAddress:fAddrss];
        [self setFormattedPhoneNumber:fPhone];
        [self setWebsite:web];
        [self setInternationalPhoneNumber:intPhone];
        [self setSearchTerms:search];
        
        [self setCoordinate:CLLocationCoordinate2DMake(lt, lg)];
        
        [self setDistanceInFeetString:distanceFeet];
        [self setDistanceInMilesString:distanceMiles];
    }
    return self;
    
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.icon forKey:@"icon"];
    [encoder encodeObject:self.rating forKey:@"rating"];
    [encoder encodeObject:self.vicinity forKey:@"vicinity"];
    [encoder encodeObject:self.types forKey:@"types"];
    [encoder encodeObject:self.reference forKey:@"reference"];
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.addressComponents forKey:@"addressComponents"];
    [encoder encodeObject:self.formattedAddress forKey:@"formattedAddress"];
    [encoder encodeObject:self.formattedPhoneNumber forKey:@"formattedPhoneNumber"];
    [encoder encodeObject:self.website forKey:@"website"];
    [encoder encodeObject:self.internationalPhoneNumber forKey:@"internationalPhoneNumber"];
    [encoder encodeObject:self.searchTerms forKey:@"searchTerms"];
    [encoder encodeDouble:self.coordinate.latitude forKey:@"coordinateLat"];
    [encoder encodeDouble:self.coordinate.longitude forKey:@"coordinateLong"];
    [encoder encodeObject:self.distanceInFeetString forKey:@"distanceInFeetString"];
    [encoder encodeObject:self.distanceInMilesString forKey:@"distanceInMilesString"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        //decode properties, other class vars
        self.name = [decoder decodeObjectForKey:@"name"];
        self.icon = [decoder decodeObjectForKey:@"icon"];
        self.rating = [decoder decodeObjectForKey:@"rating"];
        self.vicinity = [decoder decodeObjectForKey:@"vicinity"];
        self.types = [decoder decodeObjectForKey:@"types"];
        self.reference = [decoder decodeObjectForKey:@"reference"];
        self.url = [decoder decodeObjectForKey:@"url"];
        self.addressComponents = [decoder decodeObjectForKey:@"addressComponents"];
        self.formattedAddress = [decoder decodeObjectForKey:@"formattedAddress"];
        self.formattedPhoneNumber = [decoder decodeObjectForKey:@"formattedPhoneNumber"];
        self.website = [decoder decodeObjectForKey:@"website"];
        self.internationalPhoneNumber = [decoder decodeObjectForKey:@"internationalPhoneNumber"];
        self.searchTerms = [decoder decodeObjectForKey:@"searchTerms"];
        double lat = [decoder decodeDoubleForKey:@"coordinateLat"];
        double lng = [decoder decodeDoubleForKey:@"coordinateLong"];
        self.coordinate = CLLocationCoordinate2DMake(lat, lng);
        self.distanceInFeetString = [decoder decodeObjectForKey:@"distanceInFeetString"];
        self.distanceInMilesString = [decoder decodeObjectForKey:@"distanceInMilesString"];
    }
    return self;
}

//UPDATED
-(id)initWithJsonResultDict:(NSDictionary *)jsonResultDict searchTerms:(NSString *)terms andUserCoordinates:(CLLocationCoordinate2D)userCoords
{
    
    NSDictionary *geo = [jsonResultDict objectForKey:@"geometry"];
    NSDictionary *loc = [geo objectForKey:@"location"];
    
    //Figure out Distance from POI and User
    CLLocation *poi = [[CLLocation alloc] initWithLatitude:[[loc objectForKey:@"lat"] doubleValue]  longitude:[[loc objectForKey:@"lng"] doubleValue]];
    CLLocation *user = [[CLLocation alloc] initWithLatitude:userCoords.latitude longitude:userCoords.longitude];
    CLLocationDistance inFeet = ([user distanceFromLocation:poi]) * 3.2808;
    
    CLLocationDistance inMiles = ([user distanceFromLocation:poi]) * 0.000621371192;
    
    NSString *distanceInFeet = [NSString stringWithFormat:@"%.f", round(2.0f * inFeet) / 2.0f];
    NSString *distanceInMiles = [NSString stringWithFormat:@"%.2f", inMiles];
    
	return [self initWithName:[jsonResultDict objectForKey:@"name"] 
              latitude:[[loc objectForKey:@"lat"] doubleValue] 
             longitude:[[loc objectForKey:@"lng"] doubleValue]
             placeIcon:[jsonResultDict objectForKey:@"icon"] 
                rating:[jsonResultDict objectForKey:@"rating"]
              vicinity:[jsonResultDict objectForKey:@"vicinity"]
                  types:[jsonResultDict objectForKey:@"types"]
             reference:[jsonResultDict objectForKey:@"reference"]
                   url:[jsonResultDict objectForKey:@"url"]
     addressComponents:[jsonResultDict objectForKey:@"address_components"]
      formattedAddress:[jsonResultDict objectForKey:@"formatted_address"]
  formattedPhoneNumber:[jsonResultDict objectForKey:@"formatted_phone_number"]
            website:[jsonResultDict objectForKey:@"website"]
           internationalPhone:[jsonResultDict objectForKey:@"international_phone_number"] 
     searchTerms:[jsonResultDict objectForKey:terms]
               distanceInFeet:distanceInFeet
distanceInMiles:distanceInMiles     
            ];

}

//Updated
-(id) initWithJsonResultDict:(NSDictionary *)jsonResultDict andUserCoordinates:(CLLocationCoordinate2D)userCoords
{
    return [self initWithJsonResultDict:jsonResultDict searchTerms:@"" andUserCoordinates:userCoords];

}
@end
