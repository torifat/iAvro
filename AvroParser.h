//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/22/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AvroParser : NSObject {
	NSString*       vowel;
    NSString*       consonant;
    NSString*       casesensitive;
    NSDictionary*   patterns;
}

+ (void)allocateSharedInstance;
+ (void)deallocateSharedInstance;
+ (AvroParser *)sharedInstance;
- (NSString*)parse:(NSString*)string;

@end
