//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 7/1/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "CacheManager.h"

static CacheManager* sharedInstance = nil;

@implementation CacheManager

+ (CacheManager *)sharedInstance  {
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
    return nil; //on subsequent allocation attempts return nil
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
        _recentBaseCache = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    return self;
}

- (void)dealloc {
    [self persist];
    [_phoneticCache release];
    [_recentBaseCache release];
    [_weightCache release];
    [super dealloc];
}

- (void)persist {
    [_weightCache writeToFile:[[self getSharedFolder] stringByAppendingPathComponent:@"weight.plist"] atomically:YES];
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

// Base Cache
- (void)removeAllBase {
    [_recentBaseCache removeAllObjects];
}

- (NSArray*)baseForKey:(NSString*)aKey {
    return [_recentBaseCache objectForKey:aKey];
}

- (void)setBase:(NSArray*)aBase forKey:(NSString*)aKey {
    [_recentBaseCache setObject:aBase forKey:aKey];
}

@end
