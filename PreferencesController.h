//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/25/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSObject <NSApplicationDelegate> {
    IBOutlet NSView*        _autoCorrectView;
    IBOutlet NSWindow*      window;
}

@property (assign) NSWindow* window;

@end
