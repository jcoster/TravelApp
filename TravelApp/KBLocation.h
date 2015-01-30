//
//  KBLocation.h
//  TravelApp
//
//  Created by Johnny Coster on 11/7/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

@interface KBLocation : NSObject

@property (readonly) int pk;
@property (nonatomic, readonly) NSString *city;
@property (nonatomic, readonly) NSString *country;
@property (nonatomic, readonly) NSString *countryCode;
@property (nonatomic, readonly) NSNumber *latitude;
@property (nonatomic, readonly) NSNumber *longitude;

-(id)initWithId:(int)pk andCity:(NSString *)city andCountry:(NSString *)country andCountryCode:(NSString *)countryCode andLatitude:(NSNumber *)latitute andLongitude:(NSNumber *)longitude;

@end
