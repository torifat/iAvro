//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/21/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "Candidates.h"

@implementation Candidates

static Candidates *_sharedInstance = nil;

+ (void)allocateSharedInstanceWithServer:(IMKServer *)server {
	_sharedInstance = [[self alloc] initWithServer:server panelType:kIMKSingleRowSteppingCandidatePanel];
}

+ (void)deallocateSharedInstance {
	[_sharedInstance release];
}

+ (Candidates *)sharedInstance; {
	return _sharedInstance;
}

@end
