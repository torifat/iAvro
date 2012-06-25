//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/24/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "MainMenuAppDelegate.h"


@implementation MainMenuAppDelegate

//this method is added so that our controllers can access the shared NSMenu.
-(NSMenu*)menu {
	return _menu;
}

//add an awakeFromNib item so that we can set the action method.  Note that any menuItems without an action will be disabled when
//displayed in the Text Input Menu.
-(void)awakeFromNib {
	NSMenuItem* preferences = [_menu itemWithTag:1];
	
	if (preferences) {
		[preferences setAction:@selector(showPreferences:)];
	}
}

@end
