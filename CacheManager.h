//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 7/1/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CacheManager : NSObject {
    NSMutableDictionary* _weightCache;
    NSMutableDictionary* _phoneticCache;
    NSMutableDictionary* _recentBaseCache;
}

+ (void)allocateSharedInstance;
+ (void)deallocateSharedInstance;
+ (CacheManager *)sharedInstance;

- (void)persist;

// TODO - Rewrite the CacheManager with meaningful methods

// Weight Cache (default for String)
- (NSString*)stringForKey:(NSString*)aKey;
- (void)removeStringForKey:(NSString*)aKey;
- (void)setString:(NSString*)aString forKey:(NSString*)aKey;

// Phonetic Cahce (default for Array)
- (NSArray*)arrayForKey:(NSString*)aKey;
- (void)setArray:(NSArray*)anArray forKey:(NSString*)aKey;

// Base Cahce
- (void)removeAllBase;
- (NSArray*)baseForKey:(NSString*)aKey;
- (void)setBase:(NSArray*)aBase forKey:(NSString*)aKey;

@end
