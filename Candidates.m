//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/21/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "Candidates.h"

static Candidates *_sharedInstance = nil;

@implementation Candidates

+ (void)allocateSharedInstanceWithServer:(IMKServer *)server {
	_sharedInstance = [[self alloc] initWithServer:server panelType:kIMKSingleColumnScrollingCandidatePanel];
    [_sharedInstance setAttributes:[NSDictionary 
                                    dictionaryWithObject:[NSNumber numberWithBool:YES] 
                                    forKey:IMKCandidatesSendServerKeyEventFirst]];
    
    [_sharedInstance setDismissesAutomatically:NO];
}

+ (void)deallocateSharedInstance {
	[_sharedInstance release];
}

+ (Candidates *)sharedInstance; {
	return _sharedInstance;
}

@end
