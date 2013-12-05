//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/25/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSWindowController {
    IBOutlet NSView*                    _aboutView;
    IBOutlet NSView*                    _autoCorrectView;
    IBOutlet NSView*                    _generalView;
    IBOutlet NSTextView*                _aboutContent;
    IBOutlet NSDictionaryController*    _autoCorrectController;

    int                                 _currentViewTag;
}

@end
