//
//  AvroKeyboard
//
//  Created by Rifat Nabi on 6/25/12.
//  Copyright (c) 2012 OmicronLab. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AutoCorrectModel : NSObject {
    NSString* key;
    NSString* value;
}

@property (copy) NSString* key;
@property (copy) NSString* value;

@end
