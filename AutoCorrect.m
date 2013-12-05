//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/24/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "AutoCorrect.h"
#import "AvroParser.h"

static AutoCorrect* sharedInstance = nil;

@implementation AutoCorrect

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
        NSString *fileName = [[NSBundle mainBundle] pathForResource:@"autodict" ofType:@"plist"];
        // Check if the file exist and load from it, otherwise start with a empty dictionary
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
            _autoCorrectEntries = [[NSMutableDictionary alloc] initWithContentsOfFile:fileName];
        } else {
            _autoCorrectEntries = [[NSMutableDictionary alloc] init];
        }
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
    return _autoCorrectEntries[term];
}

@end
