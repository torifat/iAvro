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
#import "RegexKitLite.h"

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
    
    // Suggestions from Default Parser
    NSString* paresedString = [[AvroParser sharedInstance] parse:term];
    
    // Saving humanity by reducing a few CPU cycles
    [_suggestions addObjectsFromArray:[[CacheManager sharedInstance] arrayForKey:term]];
    if (_suggestions && [_suggestions count] == 0) {
        // Suggestions form AutoCorrect
        NSString* autoCorrect = [[AutoCorrect sharedInstance] find:term];
        if (autoCorrect) {
            [_suggestions addObject:autoCorrect];
        }
        
        // Suggestions from Dictionary
        NSArray* dicList = [[Database sharedInstance] find:term];
        if (dicList) {
            // Remove autoCorrect if it is already in the dictionary
            // PROPOSAL: don't add the autoCorrect, which matches with the dictionary entry
            if (autoCorrect && [dicList containsObject:autoCorrect]) {
                [_suggestions removeObjectIdenticalTo:autoCorrect];
            }
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
        }
        
        [[CacheManager sharedInstance] setArray:[[_suggestions copy] autorelease] forKey:term];
    }
    
    // Suggestions with Suffix
    int i;
    BOOL alreadySelected = FALSE;
    [[CacheManager sharedInstance] removeAllBase];
    for (i = [term length]-1; i > 0; --i) {
        NSString* suffix = [[Database sharedInstance] banglaForSuffix:[[term substringFromIndex:i] lowercaseString]];
        if (suffix) {
            NSString* base = [term substringToIndex:i];
            NSArray* cached = [[CacheManager sharedInstance] arrayForKey:base];
            NSString* selected;
            if (!alreadySelected) {
                // Base user selection
                selected = [[CacheManager sharedInstance] stringForKey:base];
            }
            // This should always exist, so it's just a safety check
            if (cached) {
                for (NSString *item in cached) {
                    // Skip AutoCorrect English Entry
                    if ([base isEqualToString:item]) {
                        continue;
                    }
                    NSString* word;
                    // Again saving humanity cause I'm Superman, no I'm not drunk or on weed :D 
                    int cutPos = [item length] - 1;
                    
                    NSString* itemRMC = [item substringFromIndex:cutPos];   // RMC is Right Most Character
                    NSString* suffixLMC = [suffix substringToIndex:1];      // LMC is Left Most Character
                    // BEGIN :: This part was taken from http://d.pr/zTmF
                    if ([self isVowel:itemRMC] && [self isKar:suffixLMC]) {
                        word = [NSString stringWithFormat:@"%@\u09df%@", item ,suffix];
                    }
                    else {
                        if ([itemRMC isEqualToString:@"\u09ce"]) {
                            word = [NSString stringWithFormat:@"%@\u09a4%@", [item substringToIndex:cutPos], suffix];
                        }
                        else if ([itemRMC isEqualToString:@"\u0982"]) {
                            word = [NSString stringWithFormat:@"%@\u0999%@", [item substringToIndex:cutPos], suffix];
                        } else {
                            word = [NSString stringWithFormat:@"%@%@", item, suffix];
                        }
                    }
                    // END
                    
                    // Reverse Suffix Caching 
                    [[CacheManager sharedInstance] setBase:[NSArray arrayWithObjects:base, item, nil] forKey:word];
                    
                    // Check that the WORD is not already in the list
                    if (![_suggestions containsObject:word]) {
                        // Intelligent Selection
                        if (!alreadySelected && selected && [item isEqualToString:selected]) {
                            if (![[CacheManager sharedInstance] stringForKey:term]) {
                                [[CacheManager sharedInstance] setString:word forKey:term];
                            }
                            alreadySelected = TRUE;
                        }
                        [_suggestions addObject:word];
                    }
                }
            }
        }
    }
    
    if ([_suggestions containsObject:paresedString] == NO) {
        [_suggestions addObject:paresedString];
    }
    
    return _suggestions;
}

- (BOOL)isKar:(NSString*)letter {
    return [letter isMatchedByRegex:@"^[\u09be\u09bf\u09c0\u09c1\u09c2\u09c3\u09c7\u09c8\u09cb\u09cc\u09c4]$"];
}

- (BOOL)isVowel:(NSString*)letter {
    return [letter isMatchedByRegex:@"^[\u0985\u0986\u0987\u0988\u0989\u098a\u098b\u098f\u0990\u0993\u0994\u098c\u09e1\u09be\u09bf\u09c0\u09c1\u09c2\u09c3\u09c7\u09c8\u09cb\u09cc]$"];
}

@end
