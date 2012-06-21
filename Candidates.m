//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/21/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "Candidates.h"

@implementation Candidates

static Candidates *sharedInstance = nil;

+ (void)allocateSharedInstanceWithServer:(IMKServer *)server {
	sharedInstance = [[self alloc] initWithServer:server panelType:kIMKSingleRowSteppingCandidatePanel];
}

+ (void)deallocateSharedInstance {
	[sharedInstance release];
}

+ (Candidates *)sharedInstance; {
	return sharedInstance;
}

@end
