//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/25/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "PreferencesController.h"
#import "AutoCorrect.h"
#import "AutoCorrectModel.h"

@implementation PreferencesController

@synthesize window, autoCorrectItems;

- (id)init {
    self = [super init];
    if (self) {
        autoCorrectItems = [[NSMutableArray alloc] init];
        AutoCorrect* autoCorrect = [AutoCorrect sharedInstance];
        int i;
        AutoCorrectModel* acm = nil;
        for (i = 0; i < [[autoCorrect keys] count]; ++i) {
            // Will implement method initWith key andVaule
            acm = [[AutoCorrectModel alloc] init];
            [acm setKey:[[autoCorrect keys] objectAtIndex:i]];
            [acm setValue:[[autoCorrect values] objectAtIndex:i]];
            [autoCorrectItems addObject:acm];
        }
        [acm release];
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
