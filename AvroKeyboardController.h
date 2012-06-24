//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/21/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>


@interface AvroKeyboardController : IMKInputController {
    
    //_composedBuffer contains text that the input method has converted
    NSMutableString*				_composedBuffer;
    //_original buffer contains the text has it was received from user input.
    NSMutableString*				_originalBuffer;
    //used to mark where text is being inserted in the _composedBuffer
    NSInteger						_insertionIndex;
    //This flag indicates that the original text was converted once in response to a trigger (space key)
    //the next time the trigger is received the composition will be committed.
    BOOL							_didConvert;
    //the current active client.
    id								_currentClient;
    
    NSMutableArray*                 _currentCandidates;
}

//These are simple methods for managing our composition and original buffers
//They are all simple wrappers around basic NSString methods.
- (void)commitText:(NSString*)string;

@end