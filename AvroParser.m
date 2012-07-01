//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/22/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "AvroParser.h"

@implementation AvroParser

- (id)init {
    
    self = [super init];
    
	if (self) {
        NSError *error = nil;
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"];
        NSData *jsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingUncached error: &error];
        
        if (jsonData) {
            
            NSDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData: jsonData options: NSJSONReadingMutableContainers error: &error];
            
            if (!jsonArray) {
                @throw error;
                // @throw [NSException exceptionWithName:@"AvroParser init" reason:@"Error parsing JSON" userInfo:nil];
            } else {
                _vowel = [jsonArray objectForKey:@"vowel"];
                _consonant = [jsonArray objectForKey:@"consonant"];
                _casesensitive = [jsonArray objectForKey:@"casesensitive"];
                _patterns = [jsonArray objectForKey:@"patterns"];
                _maxPatternLength = [[[_patterns objectAtIndex:0] objectForKey:@"find"] length];
            }
            
        } else {
            @throw error;
        }
    }
    
	return self;
}

- (void)dealloc {
	[_vowel release];
	[_consonant release];
	[_casesensitive release];
	[_patterns release];
	
	[super dealloc];
}

static AvroParser* sharedInstance = nil;

+ (void)allocateSharedInstance {
	sharedInstance = [[self alloc] init];
}

+ (void)deallocateSharedInstance {
	[sharedInstance release];
}

+ (AvroParser *)sharedInstance {
    return sharedInstance;
}

- (NSString*)parse:(NSString *)string {
    
    NSMutableString* fixed = [[NSMutableString alloc] initWithCapacity:0];
    int i, len = [string length];
    for (i = 0; i < len; ++i) {
        unichar c = [string characterAtIndex:i];
        if (![self isCaseSensitive:c]) {
            [fixed appendFormat:@"%C", [self smallCap:c]];
        }
        else {
            [fixed appendFormat:@"%C", c];
        }
    }
    
    NSMutableString* output = [[NSMutableString alloc] initWithCapacity:0];
    
    len = [fixed length];
    int cur;
    for(cur = 0; cur < len; ++cur) {
        int start = cur, end;
        BOOL matched = FALSE;
        
        int chunkLen;
        for(chunkLen = _maxPatternLength; chunkLen > 0; --chunkLen) {
            end = start + chunkLen;
            if(end <= len) {
                NSString* chunk = [fixed substringWithRange:NSMakeRange(start, chunkLen)];
                
                // Binary Search
                int left = 0, right = [_patterns count] - 1, mid;
                while(right >= left) {
                    mid = (right + left) / 2;
                    NSDictionary* pattern = [_patterns objectAtIndex:mid];
                    NSString* find = [pattern objectForKey:@"find"];
                    if([find isEqualToString:chunk]) {
                        NSArray* rules = [pattern objectForKey:@"rules"];
                        for(NSDictionary* rule in rules) {
                            
                            BOOL replace = TRUE;
                            int chk = 0;
                            NSArray* matches = [rule objectForKey:@"matches"];
                            for(NSDictionary* match in matches) {
                                NSString* value = [match objectForKey:@"value"];
                                NSString* type = [match objectForKey:@"type"];
                                NSString* scope = [match objectForKey:@"scope"];
                                BOOL isNegative = [[match objectForKey:@"negative"] boolValue];
                                
                                if([type isEqualToString:@"suffix"]) {
                                    chk = end;
                                } 
                                // Prefix
                                else {
                                    chk = start - 1;
                                }
                                
                                // Beginning
                                if([scope isEqualToString:@"punctuation"]) {
                                    if(
                                       ! (
                                          (chk < 0 && [type isEqualToString:@"prefix"]) || 
                                          (chk >= len && [type isEqualToString:@"suffix"]) || 
                                          [self isPunctuation:[fixed characterAtIndex:chk]]
                                          ) ^ isNegative
                                       ) {
                                        replace = FALSE;
                                        break;
                                    }
                                }
                                // Vowel
                                else if([scope isEqualToString:@"vowel"]) {
                                    if(
                                       ! (
                                          (
                                           (chk >= 0 && [type isEqualToString:@"prefix"]) || 
                                           (chk < len && [type isEqualToString:@"suffix"])
                                           ) && 
                                          [self isVowel:[fixed characterAtIndex:chk]]
                                          ) ^ isNegative
                                       ) {
                                        replace = FALSE;
                                        break;
                                    }
                                }
                                // Consonant
                                else if([scope isEqualToString:@"consonant"]) {
                                    if(
                                       ! (
                                          (
                                           (chk >= 0 && [type isEqualToString:@"prefix"]) || 
                                           (chk < len && [type isEqualToString:@"suffix"])
                                           ) && 
                                          [self isConsonant:[fixed characterAtIndex:chk]]
                                          ) ^ isNegative
                                       ) {
                                        replace = FALSE;
                                        break;
                                    }
                                }
                                // Exact
                                else if([scope isEqualToString:@"exact"]) {
                                    int s, e;
                                    if([type isEqualToString:@"suffix"]) {
                                        s = end;
                                        e = end + [value length];
                                    } 
                                    // Prefix
                                    else {
                                        s = start - [value length];
                                        e = start;
                                    }
                                    if(![self isExact:value heystack:fixed start:s end:e not:isNegative]) {
                                        replace = FALSE;
                                        break;
                                    }
                                }
                            }
                            
                            if(replace) {
                                [output appendString:[rule objectForKey:@"replace"]];
                                cur = end - 1;
                                matched = TRUE;
                                break;
                            }
                            
                        }
                        
                        if(matched == TRUE) break;
                        
                        // Default
                        [output appendString:[pattern objectForKey:@"replace"]];
                        cur = end - 1;
                        matched = TRUE;
                        break;
                    }
                    else if ([find length] > [chunk length] || 
                             ([find length] == [chunk length] && [find compare:chunk] == NSOrderedAscending)) {
                        left = mid + 1;
                    } else {
                        right = mid - 1;
                    }
                }
                if(matched == TRUE) break;                
            }
        }
        
        if(!matched) {
            unichar oldChar = [fixed characterAtIndex:cur];
            [output appendString:[NSString stringWithCharacters:&oldChar length:1]];
        }
        // NSLog(@"cur: %s, start: %s, end: %s, prev: %s\n", cur, start, end, prev);
    }
    
    [fixed release];
    [output autorelease];
    
    return output;
}

- (BOOL)isVowel:(unichar)c {
	// Making it lowercase for checking
    c = [self smallCap:c];
    int i, len = [_vowel length];
    for (i = 0; i < len; ++i) {
        if ([_vowel characterAtIndex:i] == c) {
            return TRUE;
        }
    }
	return FALSE;
}

- (BOOL)isConsonant:(unichar)c {
	// Making it lowercase for checking
    c = [self smallCap:c];
    int i, len = [_consonant length];
    for (i = 0; i < len; ++i) {
        if ([_consonant characterAtIndex:i] == c) {
            return TRUE;
        }
    }
	return FALSE;
    //return [consonant rangeOfString:c options:NSCaseInsensitiveSearch].location != NSNotFound;
}

- (BOOL)isPunctuation:(unichar)c {
	return !([self isVowel:c] || [self isConsonant:c]);
}

- (BOOL)isCaseSensitive:(unichar)c {
    // Making it lowercase for checking
    c = [self smallCap:c];
    int i, len = [_casesensitive length];
    for (i = 0; i < len; ++i) {
        if ([_casesensitive characterAtIndex:i] == c) {
            return TRUE;
        }
    }
	return FALSE;
}

- (BOOL)isExact:(NSString*) needle heystack:(NSString*)heystack start:(int)start end:(int)end not:(BOOL)not {
    // NSLog(@"Cut: %@", [heystack substringWithRange:NSMakeRange(start, end)]);
    int len = end - start;
    return ((start >= 0 && end < [heystack length] 
             && [[heystack substringWithRange:NSMakeRange(start, len)] isEqualToString:needle]) ^ not);
}

- (unichar) smallCap:(unichar) letter {
    if(letter >= 'A' && letter <= 'Z') {
        letter = letter - 'A' + 'a';
    }
    return letter;
}

@end
