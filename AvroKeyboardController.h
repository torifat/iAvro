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
    
    //the current active client.
    id								_currentClient;
    
    NSMutableArray*                 _currentCandidates;
}

//These are simple methods for managing our composition and original buffers
//They are all simple wrappers around basic NSString methods.
- (void)commitText:(NSString*)string;

@end