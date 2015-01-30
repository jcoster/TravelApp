//
//  KBPastDetailViewController.m
//  TravelApp
//
//  Created by Johnny Coster on 3/17/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import "KBPastDetailViewController.h"
#import "KBPastMapViewController.h"

@interface KBPastDetailViewController ()

@end

@implementation KBPastDetailViewController

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
        KBPastMapViewController *mapController = [self getMapController];
        if (mapController) {
            [mapController updateMapPin:self.pin];
            NSLog(@"Updated past map annotation after detail page change");
        }
    }
}

-(KBPastMapViewController *) getMapController {
    for (UIViewController *controller in [self.navigationController viewControllers]) {
        if ([controller isKindOfClass:[KBPastMapViewController class]]) {
            return (KBPastMapViewController *) controller;
        }
    }
    return nil;
}

@end
