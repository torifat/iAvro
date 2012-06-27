//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/24/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MainMenuAppDelegate : NSObject <NSApplicationDelegate> {
	IBOutlet NSMenu* _menu;
}

-(NSMenu*)menu;

@end
