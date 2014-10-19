//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/21/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>


@interface AvroKeyboardController : IMKInputController {
@private
    id                      _currentClient;         // the current active client.
    int                     _prevSelected;
    NSMutableString*		_composedBuffer;        // _composedBuffer contains text that the input method has converted
    NSMutableArray*         _currentCandidates;
    NSString*               _prefix;                // Converted Prefix
    NSString*               _term;                  // Original Non-Converted Term
    NSString*               _suffix;                // Converted Suffix
    BOOL                    _usedArrowKeys;
}

@property (nonatomic, retain) NSString* prefix;
@property (nonatomic, retain) NSString* term;
@property (nonatomic, retain) NSString* suffix;

//These are simple methods for managing our composition and original buffers
//They are all simple wrappers around basic NSString methods.
- (void)commitText:(NSString*)string;

@end