//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/25/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSWindowController {
@private
    IBOutlet NSView*                    _aboutView;
    IBOutlet NSView*                    _autoCorrectView;
    IBOutlet NSView*                    _generalView;
    IBOutlet NSTextView*                _aboutContent;
    IBOutlet NSArrayController*         _autoCorrectController;

    int                                 _currentViewTag;
    NSMutableArray*                     _autoCorrectItemsArray;
}

@property (assign) NSMutableArray* autoCorrectItemsArray;

@end
