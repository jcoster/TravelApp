//
//  KBDataManager.m
//  TravelApp
//
//  Created by Johnny Coster on 11/13/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import "KBDataManager.h"

static KBDataManager *dataManger = nil;

@implementation KBDataManager

+(KBDataManager *)getSharedInstance {
    if (!dataManger) {
        dataManger = [[super allocWithZone:nil]	init];
    }
    return dataManger;
}

-(void)initDatabase {
    self.databaseName = @"TravelApp.db";
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [documentPaths objectAtIndex:0];
    self.databasePath = [documentDir stringByAppendingPathComponent:self.databaseName];
    
    // store database in Documents directory (if doesn't already exist)
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.databasePath]) {
        NSError *error;
        NSString *databasePathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:self.databaseName];
        [fileManager copyItemAtPath:databasePathFromApp toPath:self.databasePath error:&error];
        
        if (error) {
            NSLog(@"[ERROR] DB: failed to copy database from app bundle to local filesystem");
        }
    }
}

-(void)openDatabase {
    if (!sqlite3_open([self.databasePath UTF8String], &database) == SQLITE_OK) {
        NSLog(@"[ERROR] DB: failed to open database. Message: '%s'", sqlite3_errmsg(database));
    } else {
        NSLog(@"DB: opened database");
    }
}

-(void)closeDatabase {
    if (sqlite3_close(database) == SQLITE_OK) {
        database = nil;
        NSLog(@"DB: closed database");
    } else {
        NSLog(@"[ERROR] DB: failed to close database. Message: '%s'", sqlite3_errmsg(database));
    }
}

-(NSMutableArray *)getAllPins:(PinType)type {
    
    sqlite3_stmt *statement;
    
    NSString *selectStmt = @"SELECT id, locationid, date, places, notes, color FROM kb_pin where type = '";
    selectStmt = [selectStmt stringByAppendingString:[[self pinTypeToString:type] stringByAppendingString:@"'"]];
    
    if (sqlite3_prepare_v2(database, [selectStmt UTF8String], -1, &statement, nil) != SQLITE_OK) {
        NSLog(@"[ERROR] DB: failed to prepare getAllPins statement. Message: '%s'", sqlite3_errmsg(database));
        return nil;
    }
    
    NSMutableArray *pins = [[NSMutableArray alloc] init];
    while(sqlite3_step(statement) == SQLITE_ROW) {
        int pk = sqlite3_column_int(statement, 0);
        NSNumber *locationId = [NSNumber numberWithInt:sqlite3_column_int(statement, 1)];
        KBLocation *location = [self getLocationById:locationId];
        char *dateString = (char *)sqlite3_column_text(statement, 2);
        NSString *date = dateString ? [[NSString stringWithUTF8String:dateString] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"]: nil;
        char *placesString = (char *)sqlite3_column_text(statement, 3);
        NSString *places = placesString ? [[NSString stringWithUTF8String:placesString] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"]: nil;
        char *notesString = (char *)sqlite3_column_text(statement, 4);
        NSString *notes = notesString ? [[NSString stringWithUTF8String:notesString] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"]: nil;
        char *colorString = (char *)sqlite3_column_text(statement, 5);
        NSString *color = colorString ? [NSString stringWithUTF8String:colorString] : nil;
        
        KBPin *pin = [[KBPin alloc] initWithId:pk andLocation:location andDate:date andPlaces:places andNotes:notes andColor:color andType:type];
        [pins addObject:pin];
    }
    
    if (![pins count]) {
        NSLog(@"DB: no KBPins found");
    }
    
    sqlite3_finalize(statement);
    
    return pins;
}

-(void)savePin:(KBPin *)pin {
    
    if (!database) {
        NSLog(@"[ERROR] DB: database is not available - savePin");
    }
    
    sqlite3_stmt *updateStatement;
    char *updateQuery = "UPDATE kb_pin set date = ?, places = ?, notes = ?, color = ?, type = ? where locationId = ?";
    if (sqlite3_prepare_v2(database, updateQuery, -1, &updateStatement, nil) != SQLITE_OK) {
        NSLog(@"[ERROR] DB: failed to prepare savePin statement. Message: '%s'", sqlite3_errmsg(database));
        return;
    }
    
    sqlite3_bind_text(updateStatement, 1, [[pin.date stringByReplacingOccurrencesOfString:@"\n"  withString:@"\\n"] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(updateStatement, 2, [[pin.places stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(updateStatement, 3, [[pin.notes stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(updateStatement, 4, [pin.color UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(updateStatement, 5, [[self pinTypeToString:pin.type] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(updateStatement, 6, pin.location.pk);
    
    if (sqlite3_step(updateStatement) == SQLITE_ERROR) {
        NSLog(@"[ERROR] DB: failed to update pin in the DB. Message: '%s'", sqlite3_errmsg(database));
        return;
    }
    
    sqlite3_finalize(updateStatement);
    
    // if we updated anything then our job is done
    if (sqlite3_changes(database) > 0) {
        NSLog(@"[SUCCESS] DB: updated pin in DB");
        return;
    }
    
    // nothing was updated so insert new row
    
    sqlite3_stmt *insertStatement;
    char *insertQuery = "INSERT INTO kb_pin (locationId, date, places, notes, color, type) values (?,?,?,?,?,?)";
    if (sqlite3_prepare_v2(database, insertQuery, -1, &insertStatement, nil) != SQLITE_OK) {
        NSLog(@"[ERROR] DB: failed to prepare savePin statement. Message: '%s'", sqlite3_errmsg(database));
        return;
    }

    sqlite3_bind_int(insertStatement, 1, pin.location.pk);
    sqlite3_bind_text(insertStatement, 2, [[pin.date stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insertStatement, 3, [[pin.places stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insertStatement, 4, [[pin.notes stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insertStatement, 5, [pin.color UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(insertStatement, 6, [[self pinTypeToString:pin.type] UTF8String], -1, SQLITE_TRANSIENT);
    
    if (sqlite3_step(insertStatement) == SQLITE_ERROR) {
        NSLog(@"[ERROR] DB: failed to insert pin into DB. Message: '%s'", sqlite3_errmsg(database));
        return;
    }
    
    sqlite3_finalize(insertStatement);
    
    pin.pk = (int) sqlite3_last_insert_rowid(database); // update pin with new generated id
    
    NSLog(@"[SUCCESS] DB: inserted pin into DB");
}

-(void)deletePin:(KBPin *)pin {
    
    if (!database) {
        NSLog(@"[ERROR] DB: database is not available - deletePin");
    }
    
    sqlite3_stmt *statement;
    char *deleteQuery = "DELETE FROM kb_pin where id = ?";
    if (sqlite3_prepare_v2(database, deleteQuery, -1, &statement, nil) != SQLITE_OK) {
        NSLog(@"[ERROR] DB: failed to prepare deletePin statement. Message: '%s'", sqlite3_errmsg(database));
        return;
    }
    sqlite3_bind_int(statement, 1, pin.pk);
    
    if (sqlite3_step(statement) == SQLITE_ERROR) {
        NSLog(@"[ERROR] DB: failed to delete pin from DB. Message: '%s'", sqlite3_errmsg(database));
        return;
    }
    
    sqlite3_finalize(statement);
    
    NSLog(@"[SUCCESS] DB: deleted pin [%d:'%s'] from DB", pin.pk, [pin.location.country UTF8String]);
}

-(NSString *)pinTypeToString:(PinType)type {
    switch (type) {
        case Past:
            return @"Past";
        case Future:
            return @"Future";
    }
    return @"";
}

-(PinType)stringToPinType:(NSString *)string {
    if ([string isEqualToString:@"Past"]) {
        return Past;
    } else if ([string isEqualToString:@"Future"]) {
        return Future;
    }
    return (PinType) nil;
}

-(KBLocation *)getLocationById:(NSNumber *)locationId {
    sqlite3_stmt *statement;
    NSString *query = [NSString stringWithFormat:@"SELECT city, country, countryCode, latitude, longitude FROM kb_location where id  = %d", [locationId intValue]];
    
    if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) != SQLITE_OK) {
        NSLog(@"[ERROR] DB: failed to prepare getLocationById statement. Message: '%s'", sqlite3_errmsg(database));
        return nil;
    }
    KBLocation *location = nil;
    if (sqlite3_step(statement) == SQLITE_ROW) {
        char * cityString = (char *)sqlite3_column_text(statement, 0);
        NSString *city = cityString ? [NSString stringWithUTF8String:cityString] : @"";
        NSString *country = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
        char * codeString = (char *)sqlite3_column_text(statement, 2);
        NSString *code = codeString ? [NSString stringWithUTF8String:codeString] : @"";
        NSNumber *latitude = [NSNumber numberWithDouble:sqlite3_column_double(statement, 3)];
        NSNumber *longitude = [NSNumber numberWithDouble:sqlite3_column_double(statement, 4)];
        
        location = [[KBLocation alloc] initWithId:[locationId intValue] andCity:city andCountry:country andCountryCode:code andLatitude:latitude andLongitude:longitude];
    }
    
    if (!location) {
        NSLog(@"[WARN] DB: no KBLocation found with id: %d", [locationId intValue]);
    }
    
    sqlite3_finalize(statement);
    
    return location;
}

-(KBLocation *)getLocationByCountry:(NSString *)country {
    sqlite3_stmt *statement;
    NSString *query = [NSString stringWithFormat:@"SELECT id, city, countryCode, latitude, longitude FROM kb_location where country  = '%s'", [country UTF8String]];
    
    if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) != SQLITE_OK) {
        NSLog(@"[ERROR] DB: failed to prepare getLocationByCountry statement. Message: '%s'", sqlite3_errmsg(database));
        return nil;
    }
    KBLocation *location = nil;
    if (sqlite3_step(statement) == SQLITE_ROW) {
        int pk = sqlite3_column_int(statement, 0);
        char *cityString = (char *)sqlite3_column_text(statement, 1);
        NSString *city = cityString ? [NSString stringWithUTF8String:cityString] : @"";
        char *codeString = (char *)sqlite3_column_text(statement, 2);
        NSString *code = codeString ? [NSString stringWithUTF8String:codeString] : @"";
        NSNumber *latitude = [NSNumber numberWithDouble:sqlite3_column_double(statement, 3)];
        NSNumber *longitude = [NSNumber numberWithDouble:sqlite3_column_double(statement, 4)];
        
        location = [[KBLocation alloc] initWithId:pk andCity:city andCountry:country andCountryCode:code andLatitude:latitude andLongitude:longitude];
    }
    
    if (!location) {
        NSLog(@"[WARN] DB: no KBLocation found with country: '%s'", [country UTF8String]);
    }
    
    sqlite3_finalize(statement);
    
    return location;
}

-(NSMutableArray *)getAllCountries {
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare_v2(database, "SELECT country FROM kb_location", -1, &statement, nil) != SQLITE_OK) {
        NSLog(@"[ERROR] DB: failed to prepare getAllCountries statement. Message: '%s'", sqlite3_errmsg(database));
        return nil;
    }
    
    NSMutableArray *countries = [[NSMutableArray alloc] init];
    while(sqlite3_step(statement) == SQLITE_ROW) {
        NSString *country = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
        [countries addObject:country];
    }
    
    if (![countries count]) {
        NSLog(@"[WARN] DB: no countries found");
    }
    
    sqlite3_finalize(statement);
    
    return countries;
}

@end
