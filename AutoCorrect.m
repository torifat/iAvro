//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/24/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "AutoCorrect.h"
#import "AutoCorrectModel.h"

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
        char keyBuffer[512], valueBuffer[512];
        autoCorrectEntries = [[NSMutableArray alloc] init];
        while(fscanf(file, "%s %[^\n]\n", keyBuffer, valueBuffer) == 2) {
            AutoCorrectModel* acm = [[AutoCorrectModel alloc] init];
            [acm setReplace:[NSString stringWithFormat:@"%s", keyBuffer]];
            [acm setWith:[NSString stringWithFormat:@"%s", valueBuffer]];
            [autoCorrectEntries addObject:acm];
            [acm release];
        }
        fclose(file);
        
        // Sort the array after reading
        NSArray* tempArray = [autoCorrectEntries sortedArrayUsingSelector:@selector(compare:)];
        autoCorrectEntries = [[NSMutableArray alloc] initWithArray:tempArray];
        [tempArray release];
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
    // Binary Search
    int left = 0, right = [autoCorrectEntries count] -1, mid;
    while (right >= left) {
        mid = (left + right) / 2;
        NSComparisonResult comp = [term compare:[[autoCorrectEntries objectAtIndex:mid] replace]];
        if (comp == NSOrderedDescending) {
            left = mid + 1;
        } else if (comp == NSOrderedAscending) {
            right = mid - 1;
        } else {
            return [[autoCorrectEntries objectAtIndex:mid] with];
        }
    }
    return nil;
}

@end
