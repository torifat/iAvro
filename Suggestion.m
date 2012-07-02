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
#import "NSString+Levenshtein.h"

@implementation Suggestion

- (id)init {
    
    self = [super init];
    
	if (self) {
        [AvroParser allocateSharedInstance];
        [AutoCorrect allocateSharedInstance];
        [Database allocateSharedInstance];
        _suggestions = [[NSMutableArray alloc] initWithCapacity:0];
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
    if (term && [term length] == 0) {
        return _suggestions;
    }
    
    // Suggestion form AutoCorrect
    NSString* autoCorrect = [[AutoCorrect sharedInstance] find:term];
    if (autoCorrect) {
        [_suggestions addObject:autoCorrect];
    }
    
    // Suggestion from Dictionary
    NSArray* dicList = [[Database sharedInstance] find:term];
    // Suggestion from Default Parser
    NSString* paresedString = [[AvroParser sharedInstance] parse:term];
    if (dicList) {
        // Sort dicList based on edit distance
        NSArray* sortedDicList = [dicList sortedArrayUsingComparator:^NSComparisonResult(id left, id right) {
            int dist1 = [paresedString computeLevenshteinDistanceWithString:(NSString*)left];
            int dist2 = [paresedString computeLevenshteinDistanceWithString:(NSString*)right];
            if (dist1 < dist2) {
                return NSOrderedAscending;
            }
            else if (dist1 > dist2) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        }];
        [_suggestions addObjectsFromArray:sortedDicList];
        if (autoCorrect && [dicList containsObject:autoCorrect]) {
            [_suggestions removeObjectIdenticalTo:autoCorrect];
        }
    }
    
    if ([_suggestions containsObject:paresedString] == NO) {
        [_suggestions addObject:paresedString];
    }
    
    return _suggestions;
}

@end
