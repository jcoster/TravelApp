//
//  KBPin.h
//  TravelApp
//
//  Created by Johnny Coster on 11/7/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import "KBLocation.h"

@interface KBPin : NSObject

typedef enum PinType {
    Past,
    Future
} PinType;

@property int pk;
@property (retain, nonatomic) KBLocation *location;
@property (retain, nonatomic) NSString *date;
@property (retain, nonatomic) NSString *places;
@property (retain, nonatomic) NSString *notes;
@property (retain, nonatomic) NSString *color;
@property (assign, nonatomic) PinType type;

-(id)initWithLocation:(KBLocation *)location andDate:(NSString *)date andPlaces:(NSString *)places andNotes:(NSString *)notes andColor:(NSString *)color andType:(PinType)type;
-(id)initWithId:(int)pk andLocation:(KBLocation *)location andDate:(NSString *)date andPlaces:(NSString *)places andNotes:(NSString *)notes andColor:(NSString *)color andType:(PinType)type;

@end