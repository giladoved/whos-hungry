//
//  PlaceObject.m
//  Whos Hungry
//
//  Created by Gilad Oved on 3/5/15.
//  Copyright (c) 2015 WHK. All rights reserved.
//

#import "GooglePlacesObject.h"

@implementation GooglePlacesObject

- (id)init {
    self = [super init];
    if (self) {
        self.name = @"restaurant";
        self.icon = @"";
        self.rating = @"1";
        self.placesId = @"";
        self.vicinity = @"";
        self.type = @[@"food"];
        self.reference = @"";
        self.url = @"";
        self.addressComponents = @[@""];
        self.formattedAddress = @"";
        self.formattedPhoneNumber = @"";
        self.website = @"";
        self.internationalPhoneNumber = @"";
        self.searchTerms = @"";
        double lat = 0.0;
        double lng = 0.0;
        self.coordinate = CLLocationCoordinate2DMake(lat, lng);
        self.distanceInFeetString = @" ft.";
        self.distanceInMilesString = @" mi.";
        self.image = [UIImage new];
        self.imageUrl = @"";
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.icon forKey:@"icon"];
    [encoder encodeObject:self.rating forKey:@"rating"];
    [encoder encodeObject:self.placesId forKey:@"placeid"];
    [encoder encodeObject:self.vicinity forKey:@"vicinity"];
    [encoder encodeObject:self.type forKey:@"types"];
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
    [encoder encodeObject:self.image forKey:@"image"];
    [encoder encodeObject:self.imageUrl forKey:@"imageUrl"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        self.name = [decoder decodeObjectForKey:@"name"];
        self.icon = [decoder decodeObjectForKey:@"icon"];
        self.rating = [decoder decodeObjectForKey:@"rating"];
        self.placesId = [decoder decodeObjectForKey:@"placeid"];
        self.vicinity = [decoder decodeObjectForKey:@"vicinity"];
        self.type = [decoder decodeObjectForKey:@"types"];
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
        self.image = [decoder decodeObjectForKey:@"image"];
        self.imageUrl = [decoder decodeObjectForKey:@"imageUrl"];
    }
    return self;
}


@end
