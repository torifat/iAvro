//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/21/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "AvroKeyboardController.h"
#import "Suggestion.h"
#import "Candidates.h"
#import "CacheManager.h"

@implementation AvroKeyboardController

- (id)initWithServer:(IMKServer*)server delegate:(id)delegate client:(id)inputClient {
    self = [super initWithServer:server delegate:delegate client:inputClient];
    
	if (self) {
        _currentClient = inputClient;
		_composedBuffer = [[NSMutableString alloc] initWithString:@""];
        _currentCandidates = [[NSMutableArray alloc] initWithCapacity:0];
    }

	return self;
}

- (void)dealloc {
    [_composedBuffer release];
    [_currentCandidates release];
	[super dealloc];
}

- (void)findCurrentCandidates {
    if(_composedBuffer) {
        [_currentCandidates removeAllObjects];
        _currentCandidates = [[[Suggestion sharedInstance] getList:_composedBuffer] retain];
    }
}

- (void)updateCandidatesPanel {
    if (_currentCandidates && [_currentCandidates count] > 0) {
        // Need to set font here; setting it in init... doesn't work.		
        // NSUserDefaults *defaultsDictionary = [NSUserDefaults standardUserDefaults];
        
        // NSString *candidateFontName = [defaultsDictionary objectForKey:@"candidateFontName"];
        // float candidateFontSize = [[defaultsDictionary objectForKey:@"candidateFontSize"] floatValue];
        
        // NSFont *candidateFont = [NSFont fontWithName:candidateFontName size:candidateFontSize];
        // [[Candidates sharedInstance] setAttributes:[NSDictionary dictionaryWithObject:candidateFont forKey:NSFontAttributeName]];
        
        // [[Candidates sharedInstance] setPanelType:[defaultsDictionary integerForKey:@"candidatePanelType"]];		
        [[Candidates sharedInstance] updateCandidates];
        if ([[Candidates sharedInstance] isVisible] == NO) {
            [[Candidates sharedInstance] show:kIMKLocateCandidatesBelowHint];
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
	// Intentionally blank.
}

- (void)clearCompositionBuffer {
	[_composedBuffer deleteCharactersInRange:NSMakeRange(0, [_composedBuffer length])];	
}

- (void)candidateSelected:(NSAttributedString*)candidateString {
    BOOL comp = [[candidateString string] isEqualToString:[_currentCandidates objectAtIndex:0]];
    if ((comp && !_prevSelected) == NO) {
        if (comp == YES) {
            [[[CacheManager sharedInstance] weightData] removeObjectForKey:_composedBuffer];
        }
        else {
            [[[CacheManager sharedInstance] weightData] setObject:[candidateString string] forKey:_composedBuffer];
        }
    }
	[_currentClient insertText:candidateString replacementRange:NSMakeRange(NSNotFound, 0)];
	
	[self clearCompositionBuffer];
	[_currentCandidates removeAllObjects];
    [self updateCandidatesPanel];
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
        [self commitText:string];
        return YES;
    }
    else {
        [_composedBuffer appendString:string];
        [self findCurrentCandidates];
        [self updateComposition];
        [self updateCandidatesPanel];
        
        _prevSelected = [[[CacheManager sharedInstance] weightData] objectForKey:_composedBuffer];
        if (_prevSelected) {
            // candidateStringIdentifier for >= Lion
            int i;
            for (i = 0; i < [_currentCandidates count]; ++i) {
                NSString* item = [_currentCandidates objectAtIndex:i];
                if ([item isEqualToString:_prevSelected] ) {
                    [[Candidates sharedInstance] selectCandidate:i];
                }
            }
        }
        
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
    [self commitText:@""];
}

- (BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender {
    if ([self respondsToSelector:aSelector]) {
		// The NSResponder methods like insertNewline: or deleteBackward: are
		// methods that return void. didCommandBySelector method requires
		// that you return YES if the command is handled and NO if you do not. 
		// This is necessary so that unhandled commands can be passed on to the
		// client application. For that reason we need to test in the case where
		// we might not handle the command.
		
		if(_composedBuffer && [_composedBuffer length] > 0) {
            if (aSelector == @selector(insertTab:) 
                || aSelector == @selector(insertNewline:)
                || aSelector == @selector(deleteBackward:)) {
                [self performSelector:aSelector withObject:sender];
                return YES;
            }
        }
    }
	return NO;
}

- (void)commitText:(NSString*)string {
    if (_currentCandidates) {
        [self candidateSelected:[[Candidates sharedInstance] selectedCandidateString]];
        [_currentClient insertText:string replacementRange:NSMakeRange(NSNotFound, 0)];
    }
    else {
        NSBeep();
    }
}

- (NSMenu*)menu {
    return [[NSApp delegate] menu];
}

@end