//
//  KBDataManager.h
//  TravelApp
//
//  Created by Johnny Coster on 11/13/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KBPin.h"
#import "KBLocation.h"
#import <sqlite3.h>

@interface KBDataManager : NSObject {

    sqlite3 *database;

}

@property NSString *databaseName;
@property NSString *databasePath;

+(KBDataManager *)getSharedInstance;

-(void)initDatabase;
-(void)openDatabase;
-(void)closeDatabase;

-(NSMutableArray *)getAllPins:(PinType)env;
-(void)savePin:(KBPin *)pin;
-(void)deletePin:(KBPin *)pin;

-(KBLocation *)getLocationByCountry:(NSString *)country;
-(NSMutableArray *)getAllCountries;

@end