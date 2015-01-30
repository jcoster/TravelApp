//
//  KBLocation.m
//  TravelApp
//
//  Created by Johnny Coster on 11/7/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import "KBLocation.h"

@interface KBLocation()

// redeclare as readwrite to initialize properties
@property (nonatomic, readwrite) int pk;
@property (nonatomic, readwrite) NSString *city;
@property (nonatomic, readwrite) NSString *country;
@property (nonatomic, readwrite) NSString *countryCode;
@property (nonatomic, readwrite) NSNumber *latitude;
@property (nonatomic, readwrite) NSNumber *longitude;

@end

@implementation KBLocation

-(id)initWithId:(int)pk andCity:(NSString *)city andCountry:(NSString *)country andCountryCode:(NSString *)countryCode andLatitude:(NSNumber *)latitude andLongitude:(NSNumber *)longitude {
    
    if (self = [super init]) {
        self.pk = pk;
        self.city = city;
        self.country = country;
        self.countryCode = countryCode;
        self.latitude = latitude;
        self.longitude = longitude;
    }
    
    return self;
}

@end
