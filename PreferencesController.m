//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/25/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "PreferencesController.h"

@implementation PreferencesController

@synthesize window;

-(void)awakeFromNib {
	[[self window] setContentSize:[_autoCorrectView frame].size];
    [[[self window] contentView] addSubview:_autoCorrectView];
    [[[self window] contentView] setWantsLayer:YES];
}

@end
