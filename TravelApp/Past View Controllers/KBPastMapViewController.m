//
//  KBPastMapViewController.m
//  TravelApp
//
//  Created by Johnny Coster on 3/16/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import "KBPastMapViewController.h"

@interface KBPastMapViewController ()

@property (weak, nonatomic) IBOutlet UIView *baseView;

@end

@implementation KBPastMapViewController

- (void)viewDidLoad {
    
    // initialize map and pins
    self.tileSource = [[RMMBTilesSource alloc] initWithTileSetResource:@"travelapp-map" ofType:@"mbtiles"];
    self.mapView = [[RMMapView alloc] initWithFrame:self.baseView.bounds andTilesource:self.tileSource];
    self.mapView.zoom = 1;
    self.mapView.delegate = self;
    self.mapView.bounds = CGRectMake(self.mapView.bounds.origin.x, self.mapView.bounds.origin.y, self.mapView.bounds.size.width,self.mapView.bounds.size.height - 95);
    [self.baseView addSubview:self.mapView];
    self.pins = [NSMutableArray arrayWithArray:[[KBDataManager getSharedInstance] getAllPins:Past]];
    [self layDownMarkers:NO];
    
    [super viewDidLoad];
}

// resize list when device rotates
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    // TODO resize search bar
    // TODO move all this to a global method
}

-(KBPin *)createPinWithLocation:(KBLocation *)location {
    return [[KBPin alloc] initWithLocation:location andDate:nil andPlaces:nil andNotes:nil andColor:DEFAULT_PIN_COLOR andType:Past];
}

-(NSString *)getDetailViewIdentifier {
    return @"PastDetail";
}

@end
