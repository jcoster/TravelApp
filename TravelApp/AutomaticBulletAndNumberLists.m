//
//  AutomaticBulletAndNumberLists.m
//
//  Copyright 2013 David Sweetman
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "AutomaticBulletAndNumberLists.h"

// =============================================================================
// Helper class to make it easier to work with either the char or the string:

@interface CharAndString : NSObject
@property (strong, nonatomic) NSString *stringValue;
@property (assign, nonatomic) unichar charValue;
- (id)initWithChar:(unichar)charValue;
@end

@implementation CharAndString

- (id)initWithChar:(unichar)charValue
{
    self = [super init];
    if (self) {
        _charValue = charValue;
        _stringValue = [NSString stringWithFormat:@"%C", _charValue];
    }
    return self;
}

@end

// =============================================================================
// Helper function to make a CharAndString object from the character at a
// given index of a string:

static CharAndString* getChar(NSString* string, int index)
{
    if (string.length == 0
        || index > string.length-1) {
        return nil;
    }
    @try {
        unichar thisChar = [string characterAtIndex:index];
        return [[CharAndString alloc] initWithChar:thisChar];
    }
    @catch (NSException *exception) {
        return nil;
    }
}


// =============================================================================

@implementation AutomaticBulletAndNumberLists

+ (BOOL)autoContinueListsForTextView:(UITextView*)textView
                                     editingAtRange:(NSRange)range
{
    // Check Bullet Point List:
    BOOL shouldContinue = [AutomaticBulletAndNumberLists
                                     autoContinueBulletListForTextView:textView
                                     editingAtRange:range];
    if (shouldContinue) {
        // Check Numbered List:
        shouldContinue = [AutomaticBulletAndNumberLists
                                    autoContinueNumberedListForTextView:textView
                                    editingAtRange:range];
    }
    return shouldContinue;
}

+ (BOOL)autoContinueBulletListForTextView:(UITextView*)textView
                           editingAtRange:(NSRange)range
{
    // Returns NO if a bullet point was automatically inserted, otherwise returns YES

    if (range.length > 0) {
        // don't auto-continue a list if there was an active  selection
        return YES;
    }
    if (textView.text.length == 0) {
        return YES;
    }

    // First make sure we're at the current EOL.
    int currentPos = textView.selectedRange.location;
    NSString *nextCharFromCurrentPos = [getChar(textView.text, currentPos) stringValue];
    if (nextCharFromCurrentPos != nil
        && ![nextCharFromCurrentPos isEqualToString:@"\n"]) {
        return YES;
    }

    int location = currentPos - 1;
    BOOL insertedText = NO;
    BOOL isNewline = NO;
    while (!isNewline) {

        if (location < 0) { location = 0; }
        NSString *prevCharStr = [(CharAndString*)getChar(textView.text, location) stringValue];
        
        // If this is a newline char or the beginning of the document,
        // proceed to determine the first character of this line
        if ([prevCharStr rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound
            || location == 0)
        {
            isNewline = YES;
            int nextLocation = (location == 0 ? location : location + 1);
            if (nextLocation == 0 || textView.text.length > nextLocation) {

                CharAndString* charAndString = getChar(textView.text, nextLocation);

                // Check if this line starts with a bullet:
                if ([charAndString charValue] == 0x2022) {

                    NSString *autoBulletString = [NSString stringWithFormat:@"\n%@ ", charAndString.stringValue];
                    NSString *newText = [textView.text
                                         stringByReplacingCharactersInRange:range withString:autoBulletString];
                    [textView resignFirstResponder];
                    [textView setText:newText];
                    NSRange newRange = NSMakeRange(range.location + autoBulletString.length, 0);
                    [textView becomeFirstResponder];
                    [textView setSelectedRange:newRange];

                    insertedText = YES;

                }
            }
            break;
        }

        // keep stepping backward until we find the beginning of the current line
        location--;
    }
    return !insertedText;
}

+ (BOOL)autoContinueNumberedListForTextView:(UITextView*)textView
                             editingAtRange:(NSRange)range
{
    // Returns NO if a Number was automatically inserted, otherwise returns YES

    if (range.length > 0) {
        // don't auto-continue if there was an active  selection
        return YES;
    }
    if (textView.text.length == 0) {
        return YES;
    }

    // First make sure we're at the current EOL.
    int currentPos = textView.selectedRange.location;
    NSString *nextCharFromCurrentPos = [getChar(textView.text, currentPos) stringValue];
    if (nextCharFromCurrentPos != nil
        && ![nextCharFromCurrentPos isEqualToString:@"\n"]) {
        return YES;
    }

    int location = currentPos - 1;
    BOOL insertedText = NO;
    BOOL isNewline = NO;
    while (!isNewline) {

        if (location < 0) { location = 0; }
        NSString *prevCharStr = [(CharAndString*)getChar(textView.text, location) stringValue];

        NSString *numberString = @"";

        // If this is a newline char or the beginning of the document, determine the first character of this line
        if ([prevCharStr rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound
            || location == 0)
        {
            isNewline = YES;

            int nextLocation = (location == 0 ? location : location + 1);

            BOOL finished = NO;
            BOOL validNumber = NO;
            while (!finished) {

                if (nextLocation != 0 && textView.text.length <= nextLocation) {
                    finished = YES;
                    validNumber = NO;
                    break;
                }

                NSString *nextCharString = [(CharAndString*)getChar(textView.text, nextLocation) stringValue];

                if ([nextCharString
                     rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound) {

                    // This character is a number, add it to the current numberstring:
                    numberString = [numberString stringByAppendingString:nextCharString];

                    if (numberString.length > 5) {
                        // Only auto-increment lists up to 100000:
                        finished = YES;
                        validNumber = NO;
                    }

                } else if ([nextCharString
                            isEqualToString:@"."]) {
                    
                    if (numberString.length < 1) {
                        finished = YES;
                        validNumber = NO;
                        break;
                    }

                    // This character is a period,
                    // Check that the next char is a space. if so, add an auto-incremented number.

                    if (textView.text.length > nextLocation+1) {
                        unichar spaceChar = [textView.text characterAtIndex:nextLocation+1];
                        NSString *spaceString = [NSString stringWithFormat:@"%C", spaceChar];

                        if ([spaceString
                             rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location != NSNotFound) {
                            // A space trails the period:
                            finished = YES;
                            validNumber = YES;
                        } else {
                            // A space does not trail the period:
                            finished = YES;
                            validNumber = NO;
                        }
                    }

                } else if ([nextCharString
                            rangeOfCharacterFromSet:
                            [NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound)
                {
                    // We've come to a space or newline before we found a period at the end of a number
                    finished = YES;
                    validNumber = NO;
                    break;
                }
                
                nextLocation++;
            }
            
            if (validNumber) {
                
                // The conditions for auto-inserting a number for a list have
                // been met. Increment the current number and add to the list:
                NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                [f setNumberStyle:NSNumberFormatterDecimalStyle];
                int newNumber = [f numberFromString:numberString].intValue;
                newNumber++;
                
                NSString *newNumberString = [NSString stringWithFormat:@"\n%d. ", newNumber];
                NSString *newText = [textView.text
                                     stringByReplacingCharactersInRange:range withString:newNumberString];
                
                [textView resignFirstResponder];
                [textView setText:newText];
                NSRange newRange = NSMakeRange(range.location + newNumberString.length, 0);
                [textView becomeFirstResponder];
                [textView setSelectedRange:newRange];
                
                insertedText = YES;
                
            }
            
        }
        
        location--;
        
    }
    // We need to return the opposite of insertedText - because if we DID insert
    // text, we want to tell the textView delegate to NOT insert its own.
    return !insertedText;
}

@end
