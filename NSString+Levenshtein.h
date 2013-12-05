//
//  NSString+Levenshtein.h
//  Levenshtein
//
//  Created by Stefano Pigozzi on 8/20/09.
//  Copyright 2009 Stefano Pigozzi. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (Levenshtein)

-(int) computeLevenshteinDistanceWithString:(NSString *) string;

@end
