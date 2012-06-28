//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/28/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Suggestion : NSObject

+ (void)allocateSharedInstance;
+ (void)deallocateSharedInstance;
+ (Suggestion *)sharedInstance;

- (NSMutableArray*)list:(NSString*)term;

@end
