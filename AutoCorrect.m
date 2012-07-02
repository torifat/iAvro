//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/24/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "AutoCorrect.h"
#import "AvroParser.h"
#import "RegexParser.h"

@implementation AutoCorrect

@synthesize autoCorrectEntries;

- (id)init {
    
    self = [super init];
    
	if (self) {
        // Open the file
        NSString *fileName = [[NSBundle mainBundle] pathForResource:@"autodict" ofType:@"dct"];
        const char *fn = [fileName UTF8String];
        FILE *file = fopen(fn, "r");
        
        // Read from the file
        char replaceBuffer[512], withBuffer[512];
        autoCorrectEntries = [[NSMutableArray alloc] init];
        while(fscanf(file, "%s %[^\n]\n", replaceBuffer, withBuffer) == 2) {
            NSString* replace = [NSString stringWithFormat:@"%s", replaceBuffer];
            NSString* with = [NSString stringWithFormat:@"%s", withBuffer];
            
            if ([replace isEqualToString:with] == NO) {
                with = [[AvroParser sharedInstance] parse:with];
            }
            
            NSMutableDictionary* item = [[NSMutableDictionary alloc] initWithObjectsAndKeys:replace, @"replace", with, @"with", nil];
            [autoCorrectEntries addObject:item];
            [item release];
        }
        fclose(file);
    }
    
	return self;
}

- (void)dealloc {
    [autoCorrectEntries release];
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
- (NSString*)find:(NSString*)term {
    term = [[RegexParser sharedInstance] clean:term];
    // Binary Search
    int left = 0, right = [autoCorrectEntries count] -1, mid;
    while (right >= left) {
        mid = (left + right) / 2;
        NSDictionary* item = [autoCorrectEntries objectAtIndex:mid];
        NSComparisonResult comp = [term compare:[item objectForKey:@"replace"]];
        if (comp == NSOrderedDescending) {
            left = mid + 1;
        } else if (comp == NSOrderedAscending) {
            right = mid - 1;
        } else {
            return [item objectForKey:@"with"];
        }
    }
    return nil;
}

@end
