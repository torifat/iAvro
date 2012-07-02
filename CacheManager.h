//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 7/1/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CacheManager : NSObject {
    NSMutableDictionary*    _weightData;
}

+ (void)allocateSharedInstance;
+ (void)deallocateSharedInstance;
+ (CacheManager *)sharedInstance;

- (NSString*)objectForKey:(NSString*)aKey;
- (void)removeObjectForKey:(NSString*)aKey;
- (void)setObject:(NSString*)anObject forKey:(NSString*)aKey;

@end
