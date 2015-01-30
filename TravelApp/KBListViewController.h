//
//  KBListViewController.h
//  TravelApp
//
//  Created by Johnny Coster on 11/5/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KBPin.h"
#import "KBLocation.h"

@interface KBListViewController : UITableViewController

@property NSMutableArray *countryArray;
@property NSMutableArray *pins;

// "abstract" methods to be overridden by subclasses
-(KBPin *)createPinWithLocation:(KBLocation *)location;
-(NSString *)getCellIdentifier;
-(NSString *)getDetailViewIdentifier;

@end