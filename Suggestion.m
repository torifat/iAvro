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

- (NSArray*)list:(NSString*)term {
    NSMutableArray* list = [[NSMutableArray alloc] initWithCapacity:0];
    
    NSString* autoCorrect = [[AutoCorrect sharedInstance] find:term];
    if (autoCorrect) {
        [list addObject:autoCorrect];
    }
    NSArray* dicList = [[Database sharedInstance] find:term];
    if (dicList) {
        [list addObjectsFromArray:dicList];
        if (autoCorrect && [dicList containsObject:autoCorrect]) {
            [list removeObjectIdenticalTo:autoCorrect];
        }
    }
    
    NSString* paresedString = [[AvroParser sharedInstance] parse:term];
    if ([list containsObject:paresedString] == NO) {
        [list addObject:paresedString];
    }
    
    [list autorelease];
    
    return list;
}

@end
