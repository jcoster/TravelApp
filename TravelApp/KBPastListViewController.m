//
//  KBPastListViewController.m
//  TravelApp
//
//  Created by Johnny Coster on 3/17/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import "KBPastListViewController.h"

@interface KBPastListViewController ()

@end

@implementation KBPastListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(KBPin *)createPinWithLocation:(KBLocation *)location {
    return [[KBPin alloc] initWithLocation:location andDate:nil andPlaces:nil andNotes:nil andColor:DEFAULT_PIN_COLOR andType:Past];
}

-(NSString *)getCellIdentifier {
    return @"PastPinCell";
}

-(NSString *)getDetailViewIdentifier {
    return @"PastDetail";
}

@end
