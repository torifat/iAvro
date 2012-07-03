//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 7/1/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "CacheManager.h"

@implementation CacheManager

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
            _weightCache = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        } else {
            _weightCache = [[NSMutableDictionary alloc] initWithCapacity:0];
        }
        _phoneticCache = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"-----------------------------------------------------------------");
    NSLog(@"CacheManager Unloaded");
    NSLog(@"-----------------------------------------------------------------");
    [_weightCache writeToFile:[[self getSharedFolder] stringByAppendingPathComponent:@"weight.plist"] atomically:YES];
    [_weightCache release];
	[super dealloc];
}

- (NSString*)getSharedFolder {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    return [[[paths objectAtIndex:0] 
             stringByAppendingPathComponent:@"OmicronLab"] 
            stringByAppendingPathComponent:@"Avro Keyboard"];
}

// Weight Cache
- (NSString*)stringForKey:(NSString*)aKey {
    return [_weightCache objectForKey:aKey];
}

- (void)removeStringForKey:(NSString*)aKey {
    [_weightCache removeObjectForKey:aKey];
}

- (void)setString:(NSString*)aString forKey:(NSString*)aKey {
    [_weightCache setObject:aString forKey:aKey];
}

// Phonetic Cache
- (NSArray*)arrayForKey:(NSString*)aKey {
    return [_phoneticCache objectForKey:aKey];
}

- (void)setArray:(NSArray*)anArray forKey:(NSString*)aKey {
    [_phoneticCache setObject:anArray forKey:aKey];
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
