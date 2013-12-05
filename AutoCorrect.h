//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/24/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AutoCorrect : NSObject {
    NSMutableDictionary* _autoCorrectEntries;
}

@property (retain) NSMutableDictionary* autoCorrectEntries;

+ (AutoCorrect *)sharedInstance;

- (NSString*)find:(NSString*)term;
- (NSMutableDictionary*)autoCorrectEntries;
- (void)setAutoCorrectEntries:(NSMutableDictionary *)autoCorrectEntries;

@end
