//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/21/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "AvroKeyboardController.h"
#import "MainMenuAppDelegate.h"
#import "Suggestion.h"
#import "Candidates.h"
#import "CacheManager.h"
#import "RegexKitLite.h"
#import "AvroParser.h"
#import "AutoCorrect.h"

@implementation AvroKeyboardController

@synthesize prefix = _prefix, term = _term, suffix = _suffix;

- (id)initWithServer:(IMKServer*)server delegate:(id)delegate client:(id)inputClient {
    
    self = [super initWithServer:server delegate:delegate client:inputClient];
    
	if (self) {
        _currentClient = [inputClient retain];
        _composedBuffer = [[NSMutableString alloc] initWithString:@""];
        _currentCandidates = [[NSMutableArray alloc] initWithCapacity:0];
        _prevSelected = -1;
        _usedArrowKeys = false;
    }

	return self;
}

- (void)dealloc {
    [_prefix release];
    [_term release];
    [_suffix release];
    [_currentCandidates release];
    [_composedBuffer release];
    [_currentClient release];
	[super dealloc];
}

- (void)findCurrentCandidates {
    [_currentCandidates removeAllObjects];
    if (_composedBuffer && [_composedBuffer length] > 0) {
        NSString* regex = @"(^(?::`|\\.`|[-\\]\\\\~!@#&*()_=+\\[{}'\";<>/?|.,])*?(?=(?:,{2,}))|^(?::`|\\.`|[-\\]\\\\~!@#&*()_=+\\[{}'\";<>/?|.,])*)(.*?(?:,,)*)((?::`|\\.`|[-\\]\\\\~!@#&*()_=+\\[{}'\";<>/?|.,])*$)";
        NSArray* items = [_composedBuffer captureComponentsMatchedByRegex:regex];
        if (items && [items count] > 0) {
            // Split Prefix, Term & Suffix
            [self setPrefix:[[AvroParser sharedInstance] parse:[items objectAtIndex:1]]];
            [self setTerm:[items objectAtIndex:2]];
            [self setSuffix:[[AvroParser sharedInstance] parse:[items objectAtIndex:3]]];
            
            _currentCandidates = [[[Suggestion sharedInstance] getList:[self term]] retain];
            if (_currentCandidates && [_currentCandidates count] > 0) {
                NSString* prevString = nil;
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IncludeDictionary"]) {
                    _prevSelected = -1;
                    prevString = [[CacheManager sharedInstance] stringForKey:[self term]];
                }
                int i;
                for (i = 0; i < [_currentCandidates count]; ++i) {
                    NSString* item = [_currentCandidates objectAtIndex:i];
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IncludeDictionary"] && 
                        _prevSelected && [item isEqualToString:prevString] ) {
                        _prevSelected = i;
                    }
                    [_currentCandidates replaceObjectAtIndex:i withObject:
                     [NSString stringWithFormat:@"%@%@%@", [self prefix], item, [self suffix]]];
                }
                // Emoticons                
                if ([_composedBuffer isEqualToString:[self term]] == NO && 
                    [[NSUserDefaults standardUserDefaults] boolForKey:@"IncludeDictionary"]) {
                    NSString* smily = [[AutoCorrect sharedInstance] find:_composedBuffer];
                    if (smily) {
                        [_currentCandidates insertObject:smily atIndex:0];
                    }
                }
            }
            else {
                [_currentCandidates addObject:[self prefix]];
            }
        }
    }
}

- (void)updateCandidatesPanel {
    if (_currentCandidates && [_currentCandidates count] > 0) {
        [[Candidates sharedInstance] updateCandidates];
        [[Candidates sharedInstance] show:kIMKLocateCandidatesBelowHint];
        if (_prevSelected > -1) {
            // IMKCandidates:selectCandidate not working here in sierra
            // Temporary workaounrd
            for (int i = 0 ; i < _prevSelected; ++i) {
                if ([[Candidates sharedInstance] panelType] == kIMKSingleColumnScrollingCandidatePanel) {
                    [[Candidates sharedInstance] moveDown:self];
                } else if ([[Candidates sharedInstance] panelType] == kIMKSingleRowSteppingCandidatePanel) {
                    [[Candidates sharedInstance] moveRight:self];
                }
            }
            // [[Candidates sharedInstance] selectCandidate:_prevSelected];
        }
    }
    else {
        [[Candidates sharedInstance] hide];
    }
}

- (NSArray*)candidates:(id)sender {
	return _currentCandidates;	
}

- (void)candidateSelectionChanged:(NSAttributedString*)candidateString {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IncludeDictionary"]) {
        if ([self term] && [[self term] length] > 0) {
            BOOL comp = [[candidateString string] isEqualToString:[_currentCandidates objectAtIndex:0]];
            if ((comp && _prevSelected == -1) == NO) {
                NSRange range = NSMakeRange([[self prefix] length], 
                                            [candidateString length] - ([[self prefix] length] + [[self suffix] length]));
                [[CacheManager sharedInstance] setString:[[candidateString string] substringWithRange:range] forKey:[self term]];
                
                // Reverse Suffix Caching
                NSArray* tmpArray = [[CacheManager sharedInstance] baseForKey:[candidateString string]];
                if (tmpArray && [tmpArray count] > 0) {
                    [[CacheManager sharedInstance] setString:[tmpArray objectAtIndex:1] forKey:[tmpArray objectAtIndex:0]];
                }
            }
        }
    }
    _selectedCandidateIndex = [_currentCandidates indexOfObject:candidateString.string];
}

- (void)candidateSelected:(NSAttributedString*)candidateString {
    [_currentClient insertText:candidateString replacementRange:NSMakeRange(NSNotFound, 0)];
	
	[self clearCompositionBuffer];
	[_currentCandidates removeAllObjects];
    [self updateCandidatesPanel];
    
    if (_usedArrowKeys) {
        _usedArrowKeys = false;
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"IncludeDictionary"]) {
            [[CacheManager sharedInstance] persist];
        }
    }
}

- (void)commitComposition:(id)sender {
	[sender insertText:_composedBuffer replacementRange:NSMakeRange(NSNotFound, 0)];
	
	[self clearCompositionBuffer];
	[_currentCandidates removeAllObjects];
    [self updateCandidatesPanel];
}

- (id)composedString:(id)sender {
	return [[[NSAttributedString alloc] initWithString:_composedBuffer] autorelease];
}

- (void)clearCompositionBuffer {
	[_composedBuffer deleteCharactersInRange:NSMakeRange(0, [_composedBuffer length])];	
}

/*
 Implement one of the three ways to receive input from the client. 
 Here are the three approaches:
 
 1.  Support keybinding.  
 In this approach the system takes each keydown and trys to map the keydown to an action method that the input method has implemented.  If an action is found the system calls didCommandBySelector:client:.  If no action method is found inputText:client: is called.  An input method choosing this approach should implement
 -(BOOL)inputText:(NSString*)string client:(id)sender;
 -(BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender;
 
 2. Receive all key events without the keybinding, but do "unpack" the relevant text data.
 Key events are broken down into the Unicodes, the key code that generated them, and modifier flags.  This data is then sent to the input method's inputText:key:modifiers:client: method.  For this approach implement:
 -(BOOL)inputText:(NSString*)string key:(NSInteger)keyCode modifiers:(NSUInteger)flags client:(id)sender;
 
 3. Receive events directly from the Text Services Manager as NSEvent objects.  For this approach implement:
 -(BOOL)handleEvent:(NSEvent*)event client:(id)sender;
 */

/*!
 @method     
 @abstract   Receive incoming text.
 @discussion This method receives key board input from the client application.  The method receives the key input as an NSString. The string will have been created from the keydown event by the InputMethodKit.
 */
- (BOOL)inputText:(NSString*)string client:(id)sender {
    // Return YES to indicate the the key input was received and dealt with.  Key processing will not continue in that case.  In
    // other words the system will not deliver a key down event to the application.
    // Returning NO means the original key down will be passed on to the client.
    if ([string isEqualToString:@" "]) {
        if (_currentCandidates && [_currentCandidates count]) {
            // IMKCandidates:selectedCandidateString returns null for some reason, so null is commited when user presses enter.
            // Temporary fix for macOS sierra, use our own _selectedCandidateIndex instead.
            // TODO: Figure out why IMKCandidates:selectedCandidateString isn't working.
            [self candidateSelected:_currentCandidates[_selectedCandidateIndex]];
        }
        return NO;
    }
    else {
        [_composedBuffer appendString:string];
        [self findCurrentCandidates];
        [self updateComposition];
        [self updateCandidatesPanel];
        return YES;
    }
}

- (void)deleteBackward:(id)sender {
    // We're called only when [compositionBuffer length] > 0
    [_composedBuffer deleteCharactersInRange:NSMakeRange([_composedBuffer length] - 1, 1)];
    [self findCurrentCandidates];
    [self updateComposition];
    [self updateCandidatesPanel];
}

- (void)insertTab:(id)sender {
    [self commitText:@"\t"];
}

- (void)insertNewline:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"CommitNewLineOnEnter"]) {
        [self commitText:@"\n"];
    }
    else {
        [self commitText:@""];
    }
}

- (void)moveUp:(id)sender {
    if ([[Candidates sharedInstance] isVisible]) {
        _usedArrowKeys = true;
    }
}

- (void)moveDown:(id)sender {
    if ([[Candidates sharedInstance] isVisible]) {
        _usedArrowKeys = true;
    }
}

- (BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender {
    if ([self respondsToSelector:aSelector]) {
		// The NSResponder methods like insertNewline: or deleteBackward: are
		// methods that return void. didCommandBySelector method requires
		// that you return YES if the command is handled and NO if you do not. 
		// This is necessary so that unhandled commands can be passed on to the
		// client application. For that reason we need to test in the case where
		// we might not handle the command.
		
		if (_composedBuffer && [_composedBuffer length] > 0) {
            if (aSelector == @selector(insertTab:) 
                || aSelector == @selector(insertNewline:)
                || aSelector == @selector(deleteBackward:)) {
                [self performSelector:aSelector withObject:sender];
                return YES;
            } else if (aSelector == @selector(moveUp:)
                || aSelector == @selector(moveDown:)) {
                [self performSelector:aSelector withObject:sender];
                return NO;
            }
        }
    }
	return NO;
}

- (void)commitText:(NSString*)string {
    if (_currentCandidates) {
        [self candidateSelected:_currentCandidates[_selectedCandidateIndex]];
        [_currentClient insertText:string replacementRange:NSMakeRange(NSNotFound, 0)];
    }
    else {
        NSBeep();
    }
}

- (NSMenu*)menu {
    return [(MainMenuAppDelegate *)[NSApp delegate] menu];
}

- (void)showPreferences:(id)sender {
    NSWindow *pw = [[[(MainMenuAppDelegate *)[NSApp delegate] imPref] windowController] window];

    [pw setHidesOnDeactivate:NO];
    [pw setLevel:NSModalPanelWindowLevel];
    [pw makeKeyAndOrderFront:self];
}

@end
