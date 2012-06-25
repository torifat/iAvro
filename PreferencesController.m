//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/25/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "PreferencesController.h"

@implementation PreferencesController

@synthesize window, autoCorrectItems;

- (id)init {
    self = [super init];
    if (self) {
        autoCorrectItems = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [autoCorrectItems release];
    [super dealloc];
}

-(void)awakeFromNib {
	[[self window] setContentSize:[autoCorrectView frame].size];
    [[[self window] contentView] addSubview:autoCorrectView];
    [[[self window] contentView] setWantsLayer:YES];
}

@end
