//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/21/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

@interface Candidates : IMKCandidates

+ (void)allocateSharedInstanceWithServer:(IMKServer *)server;
+ (void)deallocateSharedInstance;
+ (void)reallocate;
+ (Candidates *)sharedInstance;

@end
