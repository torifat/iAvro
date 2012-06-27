//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/25/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AutoCorrectModel : NSObject {
    NSString* replace;
    NSString* with;
}

@property (copy) NSString* replace;
@property (copy) NSString* with;

@end
