//
//  KBFutureDetailViewController.m
//  TravelApp
//
//  Created by Johnny Coster on 3/17/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import "KBFutureDetailViewController.h"
#import "KBFutureMapViewController.h"

@interface KBFutureDetailViewController ()

@end

@implementation KBFutureDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillDisappear:(BOOL)animated {
    if (self.edited) {
        // persist changes to the pin
        [[KBDataManager getSharedInstance] savePin:self.pin];
        // update the pin in the map view
        KBFutureMapViewController *mapController = [self getMapController];
        if (mapController) {
            [mapController updateMapPin:self.pin];
            NSLog(@"Updated future map annotation after detail page change");
        }
    }
}

-(KBFutureMapViewController *)getMapController {
    for (UIViewController *controller in [self.navigationController viewControllers]) {
        if ([controller isKindOfClass:[KBFutureMapViewController class]]) {
            return (KBFutureMapViewController *) controller;
        }
    }
    return nil;
}

@end