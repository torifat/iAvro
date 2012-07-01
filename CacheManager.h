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

@property (retain) NSMutableDictionary* weightData;

+ (void)allocateSharedInstance;
+ (void)deallocateSharedInstance;
+ (CacheManager *)sharedInstance;

@end
