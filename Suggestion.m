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
#import "CacheManager.h"

@implementation Suggestion

- (id)init {
    
    self = [super init];
    
	if (self) {
        [AvroParser allocateSharedInstance];
        [AutoCorrect allocateSharedInstance];
        [CacheManager allocateSharedInstance];
        [Database allocateSharedInstance];
        _suggestions = [[NSMutableArray alloc] initWithCapacity:0];
    }
    
	return self;
}

- (void)dealloc {
    [_suggestions release];
    [super dealloc];
}

static Suggestion* sharedInstance = nil;

+ (void)allocateSharedInstance {
	sharedInstance = [[self alloc] init];
}

+ (void)deallocateSharedInstance {
    [AvroParser deallocateSharedInstance];
    [AutoCorrect deallocateSharedInstance];
    [CacheManager deallocateSharedInstance];
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
    
    // Saving humanity by reducing a few CPU cycles
    [_suggestions addObjectsFromArray:[[CacheManager sharedInstance] arrayForKey:term]];
    if (_suggestions && [_suggestions count] > 0) {
        return _suggestions;
    }
    
    // Suggestions form AutoCorrect
    NSString* autoCorrect = [[AutoCorrect sharedInstance] find:term];
    if (autoCorrect) {
        [_suggestions addObject:autoCorrect];
    }
    
    // Suggestions from Dictionary
    NSArray* dicList = [[Database sharedInstance] find:term];
    // Suggestions from Default Parser
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
    
    // Suggestions with Suffix
    int i;
    for (i = [term length]-1; i > 0; --i) {
        NSLog(@"Suffix English: %@", [[term substringFromIndex:i] lowercaseString]);
        NSString* suffix = [[Database sharedInstance] banglaForSuffix:[[term substringFromIndex:i] lowercaseString]];
        NSLog(@"Suffix Bangla: %@", suffix);
        if (suffix) {
            NSString* base = [term substringToIndex:i];
            NSLog(@"Suffix: %@", base);
            NSArray* cached = [[CacheManager sharedInstance] arrayForKey:base];
            // This should always exist, so it's just a safety check
            if (cached) {
                for (NSString *item in cached) {
                    NSLog(@"Item: %@", item);
                    // Skip AutoCorrect English Entry
                    if ([base isEqualToString:item]) {
                        continue;
                    }
                    [_suggestions addObject:[NSString stringWithFormat:@"%@%@", item, suffix]];
                }
            }
        }
    }
    
    if ([_suggestions containsObject:paresedString] == NO) {
        [_suggestions addObject:paresedString];
    }
    
    [[CacheManager sharedInstance] setArray:[[_suggestions copy] autorelease] forKey:term];
    
    return _suggestions;
}

@end
