//
//  NSString+Levenshtein.m
//  Levenshtein
//
//  Created by Stefano Pigozzi on 8/20/09.
//  Copyright 2009 Stefano Pigozzi. All rights reserved.
//

#import "NSString+Levenshtein.h"
#include <stdlib.h>

@implementation NSString (Levenshtein)

/// minimum between three values
int minimum(int a,int b,int c)
{
	int min=a;
	if(b<min)
		min=b;
	if(c<min)
		min=c;
	return min;
}


-(int) computeLevenshteinDistanceWithString:(NSString *) string
{
	int *d; // distance vector
	int i,j,k; // indexes
	int cost, distance;
	
	int n = (int)[self length];
	int m = (int)[string length];
	
	if( n!=0 && m!=0 ){
		
		d = malloc( sizeof(int) * (++n) * (++m) );
		
		for( k=0 ; k<n ; k++ )
			d[k] = k;
		for( k=0 ; k<m ; k++ )
			d[k*n] = k;
		
		for( i=1; i<n ; i++ ) {
			for( j=1 ;j<m ; j++ ) {
				if( [self characterAtIndex:i-1]  == [string characterAtIndex:j-1])
					cost = 0;
				else
					cost = 1;
				d[j*n+i]=minimum(d[(j-1)*n+i]+1,d[j*n+i-1]+1,d[(j-1)*n+i-1]+cost);
			}
		}
		distance = d[n*m-1];
		free(d);
		return distance;
	}
	
	return -1; // error
}


@end
