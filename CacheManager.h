//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 7/1/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CacheManager : NSObject {
    NSMutableDictionary*    _weightCache;
    NSMutableDictionary*    _phoneticCache;
}

+ (void)allocateSharedInstance;
+ (void)deallocateSharedInstance;
+ (CacheManager *)sharedInstance;

// Weight Cache
- (NSString*)stringForKey:(NSString*)aKey;
- (void)removeStringForKey:(NSString*)aKey;
- (void)setString:(NSString*)aString forKey:(NSString*)aKey;

// Phonetic Cahce
- (NSArray*)arrayForKey:(NSString*)aKey;
- (void)setArray:(NSArray*)anArray forKey:(NSString*)aKey;

@end
