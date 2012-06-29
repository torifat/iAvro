//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/28/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "Suggestion.h"
#import "AvroParser.h"
#import "AutoCorrect.h"
#import "RegexParser.h"
#import "Database.h"

@implementation Suggestion

- (id)init {
    
    self = [super init];
    
	if (self) {
        [AvroParser allocateSharedInstance];
        [AutoCorrect allocateSharedInstance];
        [Database allocateSharedInstance];
        suggestions = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
	return self;
}

- (void)dealloc {
    [super dealloc];
}

static Suggestion* sharedInstance = nil;

+ (void)allocateSharedInstance {
	sharedInstance = [[self alloc] init];
}

+ (void)deallocateSharedInstance {
    [AvroParser deallocateSharedInstance];
    [AutoCorrect deallocateSharedInstance];
    [Database deallocateSharedInstance];
	[sharedInstance release];
}

+ (Suggestion *)sharedInstance {
	return sharedInstance;
}

- (NSMutableArray*)getList:(NSString*)term {
    NSString* autoCorrect = [[AutoCorrect sharedInstance] find:term];
    if (autoCorrect) {
        [suggestions addObject:autoCorrect];
    }
    NSArray* dicList = [[Database sharedInstance] find:term];
    if (dicList) {
        [suggestions addObjectsFromArray:dicList];
        if (autoCorrect && [dicList containsObject:autoCorrect]) {
            [suggestions removeObjectIdenticalTo:autoCorrect];
        }
    }
    
    NSString* paresedString = [[AvroParser sharedInstance] parse:term];
    if ([suggestions containsObject:paresedString] == NO) {
        [suggestions addObject:paresedString];
    }
    
    return suggestions;
}

@end
