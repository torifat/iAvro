//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/24/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "AutoCorrect.h"

@implementation AutoCorrect

- (id)init {
    
    self = [super init];
    
	if (self) {
        // Open the file
        NSString *fileName = [[NSBundle mainBundle] pathForResource:@"autodict" ofType:@"dct"];
        const char *fn = [fileName UTF8String];
        FILE *file = fopen(fn, "r");
        
        // Read from the file
        char keyBuffer[512], valueBuffer[512];
        _keys = [NSMutableArray array];
        _values = [NSMutableArray array];
        while(fscanf(file, "%s %[^\n]\n", keyBuffer, valueBuffer) == 2) {
            [_keys addObject:[NSString stringWithFormat:@"%s", keyBuffer]];
            [_values addObject:[NSString stringWithFormat:@"%s", valueBuffer]];
        }
        fclose(file);
    }
    
	return self;
}

- (void)dealloc {
	[super dealloc];
}

static AutoCorrect* sharedInstance = nil;

+ (void)allocateSharedInstance {
	sharedInstance = [[self alloc] init];
}

+ (void)deallocateSharedInstance {
	[sharedInstance release];
}

+ (AutoCorrect *)sharedInstance {
	return sharedInstance;
}

// Instance Methods

- (NSString*)find:(NSString*)key {
    int keyCount = [_keys count];
    
    NSString* result = nil;
    
    // Binary Search
    CFIndex stringIndex = CFArrayBSearchValues((CFArrayRef)_keys, CFRangeMake(0, keyCount), key, (CFComparatorFunction)CFStringCompare, NULL);
    if ((stringIndex < 0) || (stringIndex >= keyCount)) {
        // NSLog(@"Something went wrong");
    } else if ([key isEqualToString:[_keys objectAtIndex:stringIndex]] == NO) {
        // NSLog(@"Not Found");
    } else {
        result = [_values objectAtIndex:stringIndex];
    }
    
    return result;
}

@end
