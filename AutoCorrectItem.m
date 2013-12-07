//
//  AutoCorrectItem.m
//  AvroKeyboard
//
//  Created by Rifat Nabi on 12/8/13.
//
//

#import "AutoCorrectItem.h"

@implementation AutoCorrectItem

@synthesize replace, with;

static NSString * const iAVRO_ERROR_DOMAIN = @"iAvroErrorDomain";

static NSInteger const  iAVRO_INVALID_REPLACE_CODE = -1;
static NSInteger const  iAVRO_INVALID_WITH_CODE = -2;

- (id)init
{
    self = [super init];
    if (self) {
        replace = @"replace";
        with = @"with";
    }
    return self;
}

-(BOOL)validateReplace:(id *)ioValue error:(NSError * __autoreleasing *)outError {
    NSLog(@"Validating...");
    return YES;
}

-(BOOL)validateWith:(id *)ioValue error:(NSError * __autoreleasing *)outError {
    // The with must not be nil, and must be at least one characters long.
    if ((*ioValue == nil) || ([(NSString *)*ioValue length] < 1)) {
        if (outError != NULL) {
            NSString *errorString = NSLocalizedString(
                                                      @"Value of 'With' can't be empty",
                                                      @"validation: Value of 'With' can't be empty");
            NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
            *outError = [[NSError alloc] initWithDomain:iAVRO_ERROR_DOMAIN
                                                   code:iAVRO_INVALID_WITH_CODE
                                               userInfo:userInfoDict];
        }
        return NO;
    }
    return YES;
}

@end
