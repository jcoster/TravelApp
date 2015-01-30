//
//  KBDetailViewController.m
//  TravelApp
//
//  Created by Johnny Coster on 11/11/14.
//  Copyright (c) 2014 KaBliss. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "KBDetailViewController.h"
#import "KBMapViewController.h"
#import "AutomaticBulletAndNumberLists.h"

@interface KBDetailViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *flagCell;

@property (weak, nonatomic) IBOutlet UITextView *dateTextView;
@property (weak, nonatomic) IBOutlet UITextView *placesTextView;
@property (weak, nonatomic) IBOutlet UITextView *notesTextView;

@property (weak, nonatomic) IBOutlet UIButton *blueButton;
@property (weak, nonatomic) IBOutlet UIButton *greenButton;
@property (weak, nonatomic) IBOutlet UIButton *redButton;
@property (weak, nonatomic) IBOutlet UIButton *purpleButton;
@property (weak, nonatomic) IBOutlet UIButton *yellowButton;
@property NSArray *colorButtons;

@property (strong, nonatomic) UITextView *selectedTextView;

@end

@implementation KBDetailViewController

const float FLAG_HEIGHT = 50;
const float FLAG_PADDING = 10;

const float COLOR_BUTTON_INSET_NORMAL = 10;
const float COLOR_BUTTON_INSET_SELECTED = 15;
const float COLOR_BUTTON_VERTICAL_OFFSET = 90;

const float MAX_TEXT_LENGTH = 250;  // max # characters to allow in the text views

bool flagExists;

- (void)viewDidLoad {
    
    [super viewDidLoad];
	
    NSAssert(self.pin, @"pin is nil, sup with that?");
    
    self.edited = NO;
    self.selectedTextView = nil;
    
    // set navigation bar title to country name
    // and customize back button
    [self.navigationItem setTitle:self.pin.location.country];
    self.navigationItem.hidesBackButton = YES;
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-button.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)]];
    
    // set first cell to flag image
    UIImage *flagImage = [self getFlagForCountry:self.pin.location];
    if (flagImage) {
        CGFloat flagWidth = FLAG_HEIGHT * flagImage.size.width / flagImage.size.height;
        UIImageView *flagView = [[UIImageView alloc] initWithFrame:CGRectMake(self.flagCell.frame.origin.x + self.flagCell.frame.size.width/2 - flagWidth/2, FLAG_PADDING, flagWidth, FLAG_HEIGHT)];
        [flagView setImage:flagImage];
        [self.flagCell addSubview:flagView];
        flagExists = YES;
    } else {
        flagExists = NO;
    }
    
    // set date, places, and notes text and views
    self.dateTextView.text = self.pin.date;
    [self.dateTextView setFont:[UIFont fontWithName:self.placesTextView.font.familyName size:15]];
    self.placesTextView.text = self.pin.places;
    [self.placesTextView setFont:[UIFont fontWithName:self.placesTextView.font.familyName size:15]];
    self.notesTextView.text = self.pin.notes;
    [self.notesTextView setFont:[UIFont fontWithName:self.notesTextView.font.familyName size:15]];
   
    // lay out colors buttons (with selected one bigger)
    self.colorButtons = @[self.blueButton, self.greenButton, self.redButton, self.purpleButton, self.yellowButton];
    UIButton *selectedButton = [self getCurrentColorButton];
    for (UIButton *button in self.colorButtons) {
        if (button != selectedButton) {
            [button setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
        }
    }
    
    // initialize tap gesture recognizer to support dismissing keyboard
    // by tapping outside area
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    [self.view addGestureRecognizer:tap];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (flagExists) {
            return FLAG_HEIGHT + FLAG_PADDING;
        }
        return 0.0;
    } else {
        // return height from the storyboard
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 1.0;
    }
    return 20.0;
}

-(UIImage *)getFlagForCountry:(KBLocation *)location {
    KBMapViewController *controller = (KBMapViewController *)[self.navigationController.viewControllers firstObject];
    
    // set map to max zoom to make sure we get the flag correct
    // (flag needs accurate point from map which is tough when zoomed out)
    float initialZoom = controller.mapView.zoom;
    [controller.mapView setZoom:5];
    
    RMMBTilesSource *source = (RMMBTilesSource *) controller.mapView.tileSource;
    
    if ([source conformsToProtocol:@protocol(RMInteractiveSource)] && [source supportsInteractivity]) {
        
        NSString *formattedOutput = [source formattedOutputOfType:RMInteractiveSourceOutputTypeTeaser forPoint:[controller.mapView coordinateToPixel:CLLocationCoordinate2DMake([location.latitude floatValue], [location.longitude floatValue])] inMapView:controller.mapView];
        
        if (formattedOutput && [formattedOutput length]) {
            // parse the flag url out of the content
            NSUInteger startOfFlagImage = [formattedOutput rangeOfString:@"base64,"].location + [@"base64," length];
            NSUInteger endOfFlagImage = [formattedOutput rangeOfString:@"\" style"].location;
            
            // restore map to original zoom
            [controller.mapView setZoom:initialZoom];
            
            return [UIImage imageWithData:[[NSData alloc] initWithBase64EncodedString:[formattedOutput substringWithRange:NSMakeRange(startOfFlagImage, endOfFlagImage - startOfFlagImage)] options:NSDataBase64DecodingIgnoreUnknownCharacters]];
        }
    }
    
    // restore map to original zoom
    [controller.mapView setZoom:initialZoom];
    
    return nil;
}

- (IBAction)changePinColor:(id)sender {
    UIButton *pressedButton = (UIButton *) sender;
    UIButton *previousButton = [self getCurrentColorButton];
    
    if (pressedButton == previousButton) {
        return;
    }
    
    // adjust button sizes appropriately
    [pressedButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [previousButton setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];

    self.pin.color = pressedButton.restorationIdentifier ;
    NSLog(@"Pin color for %@ changed to %@", self.pin.location.country, self.pin.color);

    self.edited = YES;
}

-(UIButton *)getCurrentColorButton {
    for (UIButton *button in self.colorButtons) {
        if ([button.restorationIdentifier isEqualToString:self.pin.color]) {
            return button;
        }
    }
    NSLog(@"Couldn't find currently selected pin color button");
    return nil;
}

// add 'Done' button to keyboard when editing
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView {

    // check if we're currently editing another text view, and therefore
    // should dismiss that one instead of starting to edit this one
    if (self.selectedTextView != nil) {
        if (self.selectedTextView == textView && textView == self.placesTextView) {
            // placesTextView calls this method a couple times when adding new
            // bullet point up pressing 'Enter', so just cut to the chase and return YES
            NSLog(@"Adding new bullet point for places view");
            return YES;
        } else {
            [self dismissKeyboard:nil];
            return NO;
        }
    }
    
    // do stuff before places or notes can be edited
    UIToolbar *inputAccessoryView = [[UIToolbar alloc] init];
    [inputAccessoryView sizeToFit];
    
    // mark this text view at 'selectedTextView' for dismissing later
    self.selectedTextView = textView;
    NSLog(@"Editing text view '%s'", [textView.restorationIdentifier UTF8String]);
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyboard:)];
    [inputAccessoryView setItems:@[doneButton]];
    
    [textView setInputAccessoryView:inputAccessoryView];
    
    if (textView == self.placesTextView && (!self.placesTextView.text || [self.placesTextView.text isEqualToString:@""])) {
        textView.text = @"\u2022 ";
    }
    
    return YES;
}

// to scroll text view while typing
// source: http://stackoverflow.com/a/19276988/1700540
- (void)textViewDidChange:(UITextView *)textView {
    CGRect line = [textView caretRectForPosition:
                   textView.selectedTextRange.start];
    CGFloat overflow = line.origin.y + line.size.height
    - ( textView.contentOffset.y + textView.bounds.size.height
       - textView.contentInset.bottom - textView.contentInset.top );
    if ( overflow > 0 ) {
        // We are at the bottom of the visible text and introduced a line feed, scroll down (iOS 7 does not do it)
        // Scroll caret to visible area
        CGPoint offset = textView.contentOffset;
        offset.y += overflow + 7; // leave 7 pixels margin
        // Cannot animate with setContentOffset:animated: or caret will not appear
        [UIView animateWithDuration:.2 animations:^{
            [textView setContentOffset:offset];
        }];
    }
}

-(void) dismissKeyboard:(id) sender {
    // check that we actually are editing a text view
    // if not, do nothing
    if (self.selectedTextView != nil) {
        [self textViewShouldReturn:self.selectedTextView];
    }
}

-(BOOL)textViewShouldReturn:(UITextView *)textView {
    
    if (textView == self.dateTextView) {
        self.pin.date = textView.text;
    } else if (textView == self.placesTextView) {
        // don't persist just a bullet point
        if ([textView.text isEqualToString:@"\u2022"] || [textView.text isEqualToString:@"\u2022 "]) {
            textView.text = nil;
        }
        self.pin.places = textView.text;
    } else if (textView == self.notesTextView) {
        self.pin.notes = textView.text;
    } else {
        NSLog(@"Mysterious text view being returned");
    }

    self.edited = YES;
    [textView resignFirstResponder];
    self.selectedTextView = nil;
    
    return YES;
}

// add bullet point to new line in the 'Places Visited' window
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if ([textView.text length] >= MAX_TEXT_LENGTH && ![text isEqualToString:@""]) {
        return NO;
    }
    
    if (textView == self.placesTextView && [text isEqualToString:@"\n"]) {
        return [AutomaticBulletAndNumberLists autoContinueListsForTextView:textView editingAtRange:range];
    }
    return YES;
}

// leave the detail view
-(void)goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

@end