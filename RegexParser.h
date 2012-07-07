//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/22/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RegexParser : NSObject {
	NSString*       _vowel;
    NSString*       _consonant;
    NSString*       _casesensitive;
    NSArray*        _patterns;
    int             _maxPatternLength;
}

+ (RegexParser *)sharedInstance;

- (NSString*)parse:(NSString*)string;
- (BOOL)isVowel:(unichar)c;
- (BOOL)isConsonant:(unichar)c;
- (BOOL)isPunctuation:(unichar)c;
- (BOOL)isCaseSensitive:(unichar)c;
- (BOOL)isExact:(NSString*) needle heystack:(NSString*)heystack start:(int)start end:(int)end not:(BOOL)not;
- (unichar)smallCap:(unichar) letter;

@end
