//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 7/1/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "CacheManager.h"

@implementation CacheManager

@synthesize weightData = _weightData;

- (id)init {
    self = [super init];
    if (self) {
        
        NSLog(@"-----------------------------------------------------------------");
        NSLog(@"CacheManager Loaded");
        NSLog(@"-----------------------------------------------------------------");
        
        // Weight PLIST File
        NSString *path = [self getSharedFolder];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:path] == NO) {
            NSError* error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                @throw error;
            }
        }
        
        path = [path stringByAppendingPathComponent:@"weight.plist"];
        
        if ([fileManager fileExistsAtPath:path]) {
            _weightData = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        } else {
            _weightData = [[NSMutableDictionary alloc] initWithCapacity:0];
        }
    }
    return self;
}

- (void)dealloc {
    NSLog(@"-----------------------------------------------------------------");
    NSLog(@"CacheManager Loaded");
    NSLog(@"-----------------------------------------------------------------");
    
    [_weightData writeToFile:[[self getSharedFolder] stringByAppendingPathComponent:@"weight.plist"] atomically:YES];
    [_weightData release];
	[super dealloc];
}

- (NSString*)getSharedFolder {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    return [[[paths objectAtIndex:0] 
             stringByAppendingPathComponent:@"OmicronLab"] 
            stringByAppendingPathComponent:@"Avro Keyboard"];
}

static CacheManager* sharedInstance = nil;

+ (void)allocateSharedInstance {
	sharedInstance = [[self alloc] init];
}

+ (void)deallocateSharedInstance {
	[sharedInstance release];
}

+ (CacheManager *)sharedInstance {
    return sharedInstance;
}

@end
