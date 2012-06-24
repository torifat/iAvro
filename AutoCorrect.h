//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/24/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AutoCorrect : NSObject {
    NSMutableArray *_keys;
    NSMutableArray *_values;
}

+ (void)allocateSharedInstance;
+ (void)deallocateSharedInstance;
+ (AutoCorrect *)sharedInstance;

- (NSString*)find:(NSString*)key;

@end
