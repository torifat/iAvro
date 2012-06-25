//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/24/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AutoCorrect : NSObject {
    NSMutableArray* autoCorrectEntries;
}

@property (copy) NSMutableArray* autoCorrectEntries;

+ (void)allocateSharedInstance;
+ (void)deallocateSharedInstance;
+ (AutoCorrect *)sharedInstance;

- (NSString*)find:(NSString*)term;

@end
