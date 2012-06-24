//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/25/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSObject <NSApplicationDelegate> {
    NSMutableArray*         autoCorrectItems;
    IBOutlet NSView*        autoCorrectView;
    IBOutlet NSWindow*      window;
}

@property (copy) NSMutableArray* autoCorrectItems;
@property (assign) NSWindow* window;

@end
