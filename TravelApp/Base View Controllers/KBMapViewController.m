//
//  KBMapViewController.m
//  TravelApp
//
//  Created by Johnny Coster on 11/5/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import "KBMapViewController.h"
#import "KBListViewController.h"
#import "KBDetailViewController.h"
#import "KBPin.h"

@interface KBMapViewController ()

@property (strong, nonatomic) RMAnnotation *potentialAnnotation;
@property NSArray *searchResults;
@property bool inEditMode;
@property bool justAdded;

@end

@implementation KBMapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // initializations
    self.potentialAnnotation = nil;
    self.inEditMode = NO;
    self.justAdded = NO;
    
    // initialize search bar location
    [self.searchDisplayController.searchBar setFrame:CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height - self.searchDisplayController.searchBar.frame.size.height, self.searchDisplayController.searchBar.frame.size.width, self.searchDisplayController.searchBar.frame.size.height)];
}

// resize map when device rotates
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    // TODO resize search bar
    [self rotateStuff:self.mapView];
}

-(void)rotateStuff:(RMMapView *)mapView {
    [mapView setFrame:CGRectMake(self.mapView.frame.origin.x, self.mapView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height)];
}

/*
 MAP VIEW DELEGATE METHODS
*/

-(void)tapOnAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map {
    if (self.potentialAnnotation && ![self.potentialAnnotation isEqual:annotation]) {
        [self.mapView removeAnnotation:self.potentialAnnotation];
        self.potentialAnnotation = nil;
    }
}

// format the annotations according to whether they've been persisted yet or not
-(RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation {
    RMMarker *marker;
    NSString *pinColor = [self getAnnotationColor:annotation];
    if (pinColor) {
        marker = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:[pinColor stringByAppendingString:@"-pin.png"]]];
        [marker setRightCalloutAccessoryView:[UIButton buttonWithType:UIButtonTypeDetailDisclosure]];
    } else { // pin hasn't been saved
        marker = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:[DEFAULT_PIN_COLOR stringByAppendingString:@"-pin.png"]]];
        [marker setRightCalloutAccessoryView:[UIButton buttonWithType:UIButtonTypeContactAdd]];
    }
    [marker setCanShowCallout:YES];
    return marker;
}

-(void)tapOnCalloutAccessoryControl:(UIControl *)control forAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map {
    
    UIButton *pinButton = (UIButton *)annotation.layer.rightCalloutAccessoryView;
    // check whether adding pin or show details
    if (pinButton.buttonType == UIButtonTypeContactAdd){
        KBPin *newPin = [self createPinWithLocation:[[KBDataManager getSharedInstance] getLocationByCountry:annotation.title]];
        // persist pin to the DB
        [[KBDataManager getSharedInstance] savePin:newPin];
        // create new pin and add to array
        [self.pins addObject:newPin];
        // remove temporary annotation and add new one as saved pin
        [self.mapView removeAnnotation:annotation];
        RMAnnotation *savedAnnotation = [[RMAnnotation alloc] initWithMapView:self.mapView coordinate:annotation.coordinate andTitle:annotation.title];
        [self.mapView addAnnotation:savedAnnotation];
        [self.mapView selectAnnotation:savedAnnotation animated:YES];
        self.potentialAnnotation = nil;       
    } else {
        // go to pin's detail view
        NSLog(@"Going to detail view from map for country '%s'", [annotation.title UTF8String]);
        KBDetailViewController *detailController = [self.storyboard instantiateViewControllerWithIdentifier:[self getDetailViewIdentifier]];
        detailController.pin = [self getPinByAnnotation:annotation];
        [self.navigationController pushViewController:detailController animated:YES];
        [self.mapView deselectAnnotation:annotation animated:NO];
    }

}

// if a 'potential' pin exists, this will remove it
-(void)singleTapOnMap:(RMMapView *)map at:(CGPoint)point {
    NSLog(@"Tapped on point: %f, %f", point.x, point.y);
    if (self.potentialAnnotation) {
        [self.mapView removeAnnotation:self.potentialAnnotation];
        self.potentialAnnotation = nil;
    }
}

// this is done to drop a new 'potential' pin that needs to be confirmed
-(void)longPressOnMap:(RMMapView *)map at:(CGPoint)point {
    
    RMMBTilesSource *source = (RMMBTilesSource *) self.mapView.tileSource;
    if ([source conformsToProtocol:@protocol(RMInteractiveSource)] && [source supportsInteractivity]) {
        
        NSString *formattedOutput = [source formattedOutputOfType:RMInteractiveSourceOutputTypeTeaser forPoint:point inMapView:self.mapView];

        if (formattedOutput && [formattedOutput length]) {
            // parse the country name out of the content
            NSUInteger startOfCountryName = [formattedOutput rangeOfString:@"<strong>"].location + [@"<strong>" length];
            NSUInteger endOfCountryName   = [formattedOutput rangeOfString:@"</strong>"].location;
            NSString *countryName = [formattedOutput substringWithRange:NSMakeRange(startOfCountryName, endOfCountryName - startOfCountryName)];
            NSLog(@"Country selected: '%s'", [countryName UTF8String]);
            
            RMAnnotation *currentAnnotation = [self getAnnotationByCountry:countryName];
            if (currentAnnotation) {
                NSLog(@"Already a pin");
                // select that current pin
                [self.mapView selectAnnotation:currentAnnotation animated:YES];
            } else {
                // convert to location
                // TODO - CHANGE ME TO USE LOCATION WHERE TOUCHED?
                KBLocation *defaultLocation = [[KBDataManager getSharedInstance] getLocationByCountry:countryName];
                // remove previous new annotation that's not saved (if exists)
                if (self.potentialAnnotation) {
                    [self.mapView removeAnnotation:self.potentialAnnotation];
                }
                // create and add annotation to map
                self.potentialAnnotation = [[RMAnnotation alloc] initWithMapView:self.mapView coordinate:CLLocationCoordinate2DMake((CLLocationDegrees)[defaultLocation.latitude doubleValue], (CLLocationDegrees)[defaultLocation.longitude doubleValue]) andTitle:countryName];
                [self.mapView addAnnotation:self.potentialAnnotation];
                [self.mapView setZoom:self.mapView.zoom atCoordinate:self.potentialAnnotation.coordinate animated:YES];
                // center map on annotation (https://github.com/mapbox/mapbox-ios-sdk/issues/451)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.mapView selectAnnotation:self.potentialAnnotation animated:YES];
                });
                
                self.justAdded = YES;
            }
        } else {
            if (self.potentialAnnotation) {
                [self.mapView removeAnnotation:self.potentialAnnotation];
                self.potentialAnnotation = nil;
            }
        }
    }
}

-(RMAnnotation *) getAnnotationByCountry:(NSString *)country {
    for (RMAnnotation *annotation in self.mapView.annotations) {
        if ([annotation.title isEqualToString:country]) {
            return annotation;
        }
    }
    return nil;
}

-(KBPin *) getPinByAnnotation:(RMAnnotation *)annotation {
    for (KBPin *pin in self.pins) {
        if (pin.location.country == annotation.title) {
            return pin;
        }
    }
    NSLog(@"No pin found for annotation of country '%s'", [annotation.title UTF8String]);
    return nil;
}

-(void)layDownMarkers:(BOOL)reset {
    if (reset) {
        [self.mapView removeAllAnnotations];
    }
    NSMutableArray *markers = [[NSMutableArray alloc] initWithCapacity:[self.pins count]];
    for (KBPin *pin in self.pins) {
        RMAnnotation *marker = [[RMAnnotation alloc] initWithMapView:self.mapView coordinate:CLLocationCoordinate2DMake([pin.location.latitude doubleValue], [pin.location.longitude doubleValue]) andTitle:pin.location.country];
        [markers addObject:marker];
    }
    [self.mapView addAnnotations:markers];
}

// fetch the annotation's image name from it's associated pin
// returning nil if annotation hasn't been persisted yet
-(NSString *)getAnnotationColor:(RMAnnotation *)annotation {
    NSString *color = nil;
    for (KBPin *pin in self.pins) {
        if ([pin.location.country isEqualToString:annotation.title]) {
            color = pin.color;
        }
    }
    return color;
}

// called by detail page after pin has been updated (mainly for pin color)
-(void)updateMapPin:(KBPin *)updatedPin {
    // update pin in pastPins array
    KBPin *oldPin = nil;
    for (KBPin *pin in self.pins) {
        if (pin.pk == updatedPin.pk) {
            oldPin = pin;
            break;
        }
    }
    
    if (!oldPin) {
        // pin doesn't exist in the map (must have been created in the list)
        // nothing to do
        return;
    }
    
    [self.pins replaceObjectAtIndex:[self.pins indexOfObject:oldPin] withObject:updatedPin];
    
    // update annotation in map (i.e. call layerForAnnotation)
    RMAnnotation *annotation = [self getAnnotationByCountry:updatedPin.location.country];
    [self.mapView removeAnnotation:annotation];
    [self.mapView addAnnotation:annotation];
}

/*
 SEARCH BAR DELEGATE METHODS
*/

// search bar was selected
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self.searchDisplayController.searchBar setFrame:CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height - self.searchDisplayController.searchBar.frame.size.height, self.searchDisplayController.searchBar.frame.size.width, self.searchDisplayController.searchBar.frame.size.height)];
    if (!self.countryArray) {
        // load list of all countries from the DB
        self.countryArray = [[NSMutableArray alloc] initWithArray:[[KBDataManager getSharedInstance] getAllCountries]];
        // exclude countries from current pins
        if ([self.pins count]) {
            NSMutableArray *currentCountries = [[NSMutableArray alloc] init];
            for (KBPin *pin in self.pins) {
                [currentCountries addObject:pin.location.country];
            }
            [self.countryArray removeObjectsInArray:[NSArray arrayWithArray:currentCountries]];
        }
    }
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    [self toggleEditMode:nil];
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.searchResults count];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
    self.searchResults = [self.countryArray filteredArrayUsingPredicate:resultPredicate];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"SearchPinCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:cellIdentifier];
    }
    
    // Configure the cell...
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.textLabel.text = [self.searchResults objectAtIndex:indexPath.row];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        NSString *selectedCountry = [self.searchResults objectAtIndex:indexPath.row];
        KBDataManager *dataManger = [KBDataManager getSharedInstance];
        KBLocation *newCountry = [dataManger getLocationByCountry:selectedCountry];
        KBPin *newPin = [self createPinWithLocation:newCountry];
        if (![self.pins containsObject:newPin]) {
            // persist the pin
            [dataManger savePin:newPin];
            // add pin to list
            [self.pins addObject:newPin];
            // remove country name from possible ones to search
            [self.countryArray removeObject:selectedCountry];
            // remove potential annotation that's not saved (if exists)
            if (self.potentialAnnotation) {
                [self.mapView removeAnnotation:self.potentialAnnotation];
                self.potentialAnnotation = nil;
            }
            // create and add an annotation to map
            RMAnnotation *newAnnotation = [[RMAnnotation alloc] initWithMapView:self.mapView coordinate:CLLocationCoordinate2DMake((CLLocationDegrees)[newPin.location.latitude doubleValue], (CLLocationDegrees)[newPin.location.longitude doubleValue]) andTitle:newPin.location.country];
            [self.mapView addAnnotation:newAnnotation];
            [self.mapView selectAnnotation:newAnnotation animated:YES];
            // go back to pin list
            [self.searchDisplayController setActive:NO animated:YES];
        } else {
            NSLog(@"Tried adding pin that already exists");
        }
    }
}

-(IBAction)toggleEditMode:(id)sender {
    if (self.inEditMode) {
        self.inEditMode = NO;
        [UIView animateWithDuration:0.4 animations:^{
            [self.searchDisplayController.searchBar setFrame:CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height - self.searchDisplayController.searchBar.frame.size.height, self.searchDisplayController.searchBar.frame.size.width, self.searchDisplayController.searchBar.frame.size.height)];
        }];
        [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"plus-sign.png"]];
    } else {
        self.inEditMode = YES;
        [UIView animateWithDuration:0.4 animations:^{
            [self.searchDisplayController.searchBar setFrame:CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.searchDisplayController.searchBar.frame.size.width, self.searchDisplayController.searchBar.frame.size.height)];
        }];
        [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"checkmark.png"]];
    }
}

/*
 MISC
*/

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showPinList"]) {
        KBListViewController *listViewController = segue.destinationViewController;
        listViewController.pins = [NSMutableArray arrayWithArray:self.pins];
        if (self.inEditMode) {
            [self toggleEditMode:nil];
        }
    }
}

- (IBAction)unwindToMap:(UIStoryboardSegue *)segue {
    if ([segue.sourceViewController isKindOfClass:[KBListViewController class]]) {
        KBListViewController *listViewController = segue.sourceViewController;
        if (![self.pins isEqualToArray:listViewController.pins]) {
            self.pins = listViewController.pins;
            [self layDownMarkers:YES];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 "Abstract" methods
*/

-(KBPin *)createPinWithLocation:(KBLocation *)location { return nil; }
-(NSString *)getDetailViewIdentifier { return nil; }

@end
