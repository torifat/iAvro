//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/24/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AutoCorrect : NSObject {
    NSMapTable* _autoCorrectEntries;
}

@property (retain) NSMapTable* autoCorrectEntries;

+ (AutoCorrect *)sharedInstance;

- (NSString*)find:(NSString*)term;
- (NSMapTable*)autoCorrectEntries;
- (void)setAutoCorrectEntries:(NSMapTable *)autoCorrectEntries;

@end
