//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/21/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "AvroKeyboardController.h"
#import "AvroParser.h"
#import "Candidates.h"

@implementation AvroKeyboardController

- (id)initWithServer:(IMKServer*)server delegate:(id)delegate client:(id)inputClient {
    self = [super initWithServer:server delegate:delegate client:inputClient];
    
	if (self) {
		_currentClient = inputClient;
		_composedBuffer = [[NSMutableString alloc] initWithString:@""];
		_currentCandidates = nil;
    }
    
	return self;
}

- (void)dealloc {
	[_composedBuffer release];
	
	[super dealloc];
}

- (void)findCurrentCandidates {
    if(_composedBuffer) {
        [_currentCandidates addObject:[[AvroParser sharedInstance] parse:_composedBuffer]];
    }
    /*
    if (_currentCandidates) {
        [_currentCandidates retain];
    }
    */
}

- (void)updateCandidatesPanel {
    if (_currentCandidates) {
        // Need to set font here; setting it in init... doesn't work.		
        // NSUserDefaults *defaultsDictionary = [NSUserDefaults standardUserDefaults];
        
        // NSString *candidateFontName = [defaultsDictionary objectForKey:@"candidateFontName"];
        // float candidateFontSize = [[defaultsDictionary objectForKey:@"candidateFontSize"] floatValue];
        
        // NSFont *candidateFont = [NSFont fontWithName:candidateFontName size:candidateFontSize];
        // [[Candidates sharedInstance] setAttributes:[NSDictionary dictionaryWithObject:candidateFont forKey:NSFontAttributeName]];
        
        // [[Candidates sharedInstance] setPanelType:[defaultsDictionary integerForKey:@"candidatePanelType"]];		
        [[Candidates sharedInstance] setPanelType:kIMKSingleColumnScrollingCandidatePanel];
        [[Candidates sharedInstance] updateCandidates];
        [[Candidates sharedInstance] show:kIMKLocateCandidatesBelowHint];
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
	[_currentClient insertText:candidateString replacementRange:NSMakeRange(NSNotFound, 0)];
	
	[self clearCompositionBuffer];
	
	[_currentCandidates release];
	_currentCandidates = nil;
}

- (void)commitComposition:(id)sender {
	[sender insertText:_composedBuffer replacementRange:NSMakeRange(NSNotFound, 0)];
	
	[self clearCompositionBuffer];
	
	[_currentCandidates release];
	_currentCandidates = nil;
}

- (id)composedString:(id)sender {
	return [[[NSAttributedString alloc] initWithString:_composedBuffer] autorelease];
}

- (NSString *)convertPunctuation:(NSString*)string {
    /*
     NSDictionary *punctuations = [[ConversionEngine sharedInstance] punctuations];
     
     return [punctuations objectForKey:[compositionBuffer stringByAppendingString:string]];
     */
    return @"";
}

- (BOOL)areValidCharacters:(NSString*)string {
    char key = [string characterAtIndex:0];
    return ((key >= 'a' && key <= 'z') || (key >= 'A' && key <= 'Z') || key == '\'' || key == '`');
    /*
     NSCharacterSet *validCharacterSet = [NSCharacterSet lowercaseLetterCharacterSet];
     
     NSScanner *scanner = [NSScanner scannerWithString:string];
     
     return [scanner scanCharactersFromSet:validCharacterSet intoString:NULL] && [scanner isAtEnd];
     */
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
-(BOOL)inputText:(NSString*)string client:(id)sender {
    // Return YES to indicate the the key input was received and dealt with.  Key processing will not continue in that case.  In
    // other words the system will not deliver a key down event to the application.
    // Returning NO means the original key down will be passed on to the client.
    /*
     NSString *punctuation = [self convertPunctuation:string];
     if (punctuation)
     {
     [client insertText:punctuation replacementRange:NSMakeRange(NSNotFound, 0)];
     
     [self clearCompositionBuffer];
     
     return YES;
     }
     else */if ([string isEqualToString:@" "]) {
         if ([_composedBuffer length] == 0) {
             [_currentClient insertText:@" " replacementRange:NSMakeRange(NSNotFound, 0)];
         }
         else {
             [_currentClient insertText:[[AvroParser sharedInstance] parse:_composedBuffer] replacementRange:NSMakeRange(NSNotFound, 0)];
             
             [self clearCompositionBuffer];
             
             [_currentCandidates release];
             _currentCandidates = nil;
             /*
             if (_currentCandidates) {
                 [self candidateSelected:[_currentCandidates objectAtIndex:0]];
             }
             else {
                 NSBeep();
             }
              */
         }
         
         return YES;
     }
     else if ([self areValidCharacters:string]) {
         [_composedBuffer appendString:string];
         
         [self findCurrentCandidates];
         
         [self updateComposition];
         
         [self updateCandidatesPanel];
         
         return YES;
     }
     else {
         return NO;
     }
}

- (void)deleteBackward:(id)sender {
    // We're called only when [compositionBuffer length] > 0
    [_composedBuffer deleteCharactersInRange:NSMakeRange([_composedBuffer length] - 1, 1)];
    
    [self findCurrentCandidates];
    
    [self updateComposition];
    
    [self updateCandidatesPanel];
}

-(BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender {
    if ([self respondsToSelector:aSelector] && [_composedBuffer length] > 0) {
        [self performSelector:aSelector withObject:sender];
        return YES; 
    }
    else {
        return NO;
    }
}

- (NSMenu*)menu {
    return [[NSApp delegate] menu];
}

@end