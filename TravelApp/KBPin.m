//
//  KBPin.m
//  TravelApp
//
//  Created by Johnny Coster on 11/7/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import "KBPin.h"

@implementation KBPin

-(id)initWithLocation:(KBLocation *)location andDate:(NSString *)date andPlaces:(NSString *)places andNotes:(NSString *)notes andColor:(NSString *)color andType:(PinType)type {
   
    if (self = [super init]) {
        self.location = location;
        self.date = date;
        self.places = places;
        self.notes = notes;
        self.color = color;
        self.type = type;
    }
    
    return self;
}

-(id)initWithId:(int)pk andLocation:(KBLocation *)location andDate:(NSString *)date andPlaces:(NSString *)places andNotes:(NSString *)notes andColor:(NSString *)color andType:(PinType)type {
    
    if (self = [self initWithLocation:location andDate:date andPlaces:places andNotes:notes andColor:color andType:type]) {
        self.pk = pk;
    }
    
    return self;
}

@end