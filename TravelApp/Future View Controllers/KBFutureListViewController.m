//
//  KBFutureListViewController.m
//  TravelApp
//
//  Created by Johnny Coster on 11/6/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import "KBFutureListViewController.h"

@interface KBFutureListViewController ()

@end

@implementation KBFutureListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(KBPin *)createPinWithLocation:(KBLocation *)location {
    return [[KBPin alloc] initWithLocation:location andDate:nil andPlaces:nil andNotes:nil andColor:DEFAULT_PIN_COLOR andType:Future];
}

-(NSString *)getCellIdentifier {
    return @"FuturePinCell";
}

-(NSString *)getDetailViewIdentifier {
    return @"FutureDetail";
}

@end
