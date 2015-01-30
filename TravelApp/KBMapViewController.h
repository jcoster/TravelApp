//
//  KBPastMapViewController.h
//  TravelApp
//
//  Created by Johnny Coster on 11/5/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KBDataManager.h"
#import "Mapbox.h"

@interface KBMapViewController : UIViewController <RMMapViewDelegate>

@property KBDataManager *dataController;
@property NSMutableArray *countryArray;

@property RMMapView *mapView;
@property RMMBTilesSource *tileSource;

@property NSMutableArray *pins;

-(void)updateMapPin:(KBPin *)updatedPin;

-(void)layDownMarkers:(BOOL)reset;

// "abstract" methods to be overridden by subclasses
-(KBPin *)createPinWithLocation:(KBLocation *)location;
-(NSString *)getDetailViewIdentifier;

@end