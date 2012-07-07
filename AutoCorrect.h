//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/24/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AutoCorrect : NSObject {
    NSMutableArray* _autoCorrectEntries;
}

@property (retain) NSMutableArray* autoCorrectEntries;

+ (AutoCorrect *)sharedInstance;

- (NSString*)find:(NSString*)term;
- (NSMutableArray*)autoCorrectEntries;
- (void)setAutoCorrectEntries:(NSMutableArray *)autoCorrectEntries;

@end
