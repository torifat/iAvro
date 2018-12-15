//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/24/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "IMPreferences.h"

@interface MainMenuAppDelegate : NSObject <NSApplicationDelegate> {
	IBOutlet NSMenu* _menu;
}

@property(retain) IMPreferences* imPref;

-(NSMenu*)menu;

@end
