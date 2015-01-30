//
//  KBDetailViewController.h
//  TravelApp
//
//  Created by Johnny Coster on 11/11/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KBDataManager.h"
#import "Mapbox.h"
#import "KBPin.h"

@interface KBDetailViewController : UITableViewController

@property KBPin *pin;
@property RMAnnotation *annotation;
@property BOOL edited;

@end