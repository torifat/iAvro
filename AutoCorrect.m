//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/24/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "AutoCorrect.h"
#import "AvroParser.h"

static AutoCorrect* sharedInstance = nil;

@implementation AutoCorrect {
    NSString* fileName;
}

@synthesize autoCorrectEntries = _autoCorrectEntries;

+ (AutoCorrect *)sharedInstance  {
    if (sharedInstance == nil) {
        [[self alloc] init]; // assignment not done here, see allocWithZone
    }
	return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    if (sharedInstance == nil) {
        sharedInstance = [super allocWithZone:zone];
        return sharedInstance;  // assignment and return on first allocation
    }
    return sharedInstance; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (oneway void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;  // This is sooo not zero
}

- (id)init {
    self = [super init];
    if (self) {
        // Open the file
        fileName = [[NSBundle mainBundle] pathForResource:@"autodict" ofType:@"dct"];
        const char *fn = [fileName UTF8String];
        FILE *file = fopen(fn, "r");
        
        // Read from the file
        char replaceBuffer[1024], withBuffer[512];
        _autoCorrectEntries = [[NSMapTable alloc] init];
        while(fscanf(file, "%s %[^\n]\n", replaceBuffer, withBuffer) == 2) {
            NSString* replace = [NSString stringWithFormat:@"%s", replaceBuffer];
            NSString* with = [NSString stringWithFormat:@"%s", withBuffer];
            
            if ([replace isEqualToString:with] == NO) {
                with = [[AvroParser sharedInstance] parse:with];
            }
            
            [_autoCorrectEntries setObject:with forKey:replace];
        }
        fclose(file);
    }
    return self;
}

- (void)dealloc {
    [_autoCorrectEntries release];
    [super dealloc];
}

// Instance Methods
- (NSString*)find:(NSString*)term {
    term = [[AvroParser sharedInstance] fix:term];
    return [_autoCorrectEntries objectForKey:term];
}

@end
