//
//  KBListViewController.m
//  TravelApp
//
//  Created by Johnny Coster on 11/5/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import "KBListViewController.h"
#import "KBDetailViewController.h"
#import "KBDataManager.h"

@interface KBListViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property NSArray *searchResults;

@end

@implementation KBListViewController

const int ESOTERIC_ROW_THRESHOLD = 10;

- (void)viewDidLoad {

    [super viewDidLoad];

    // hide search bar
    // source: http://stackoverflow.com/a/18264203/1700540
    [self.tableView scrollRectToVisible:CGRectMake(0,self.tableView.contentSize.height - self.tableView.bounds.size.height,self.tableView.bounds.size.width,self.tableView.bounds.size.height) animated:NO];
    
}

/*
 TABLE VIEW DELEGATE METHODS
*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.searchResults count];
    }
    return [self.pins count];
}

// All rows are editable
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// All rows are movable
-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be movable
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self getCellIdentifier];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:cellIdentifier];
    }
    
    // Configure the cell...
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.textLabel.text = [self.searchResults objectAtIndex:indexPath.row];
    } else {
        KBPin *pin = [self.pins objectAtIndex:indexPath.row];
        cell.textLabel.text = pin.location.country;
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
            // reload pin list
            [self.tableView reloadData];
            // go back to pin list
            [self.searchDisplayController setActive:NO animated:YES];
        } else {
            NSLog(@"Tried adding pin that already exists");
        }
    } else {
        // we're in the normal list view...behave like we touched the accessory button
        [self tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    }
}

-(IBAction)toggleEditMode:(id)sender {
    if ([self.tableView isEditing]) {
        [self.tableView setEditing:NO animated:YES];
        [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"edit-pencil.png"]];
        // hide search bar...in a semi-convoluted way
        if ([self.tableView numberOfRowsInSection:0] > ESOTERIC_ROW_THRESHOLD) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else {
            [self.tableView scrollRectToVisible:CGRectMake(0,self.tableView.contentSize.height - self.tableView.bounds.size.height,self.tableView.bounds.size.width,self.tableView.bounds.size.height) animated:YES];
        }
    } else {
        [self.tableView setEditing:YES animated:YES];
        [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"checkmark.png"]];
        // show search bar
        [self.tableView scrollRectToVisible:CGRectMake(0,0,1,1) animated:YES];
    }
}

// Action taken when edit it performed (currently just deletion is supported)
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the table, the database, and the pins array
        KBDataManager *dataManger = [KBDataManager getSharedInstance];
        KBPin *pinToDelete = [self.pins objectAtIndex:indexPath.row];
        [dataManger deletePin:pinToDelete];
        [self.pins removeObjectAtIndex:indexPath.row];
        // Add the pin's country back to searchable countryArray
        [self.countryArray addObject:pinToDelete.location.country];
        
        [tableView reloadData];
    }
}

// Do the actual movement of cells in edit mode
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    KBPin *pinToMove = [self.pins objectAtIndex:sourceIndexPath.row];
    [self.pins removeObjectAtIndex:sourceIndexPath.row];
    [self.pins insertObject:pinToMove atIndex:destinationIndexPath.row];
}

/*
 SEARCH BAR DELEGATE METHODS
 */

// search bar was selected
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
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

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
    self.searchResults = [self.countryArray filteredArrayUsingPredicate:resultPredicate];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}

/*
 MISC
*/

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    KBDetailViewController *detailController = [self.storyboard instantiateViewControllerWithIdentifier:[self getDetailViewIdentifier]];
    detailController.pin = [self.pins objectAtIndex:indexPath.row];
    [self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleBordered target:nil action:nil]];

    [self.navigationController pushViewController:detailController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 "Abstract" methods
 */

-(KBPin *)createPinWithLocation:(KBLocation *)location { return nil; }
-(NSString *)getCellIdentifier { return nil; }
-(NSString *)getDetailViewIdentifier { return nil; }

@end