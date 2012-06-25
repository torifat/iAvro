//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/25/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import "AutoCorrectModel.h"

@implementation AutoCorrectModel

@synthesize replace, with;

- (NSComparisonResult)compare:(AutoCorrectModel *)otherObject {
    return [self.replace compare:otherObject.replace];
}

@end
