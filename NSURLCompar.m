//
//  NSURLCompar.m
//  TR Poser
//
//  Created by Torsten on 17.05.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSURLCompar.h"


@implementation NSURL (Compare)

- (NSComparisonResult)compare:(NSURL *)anURL;
{
	return [[self absoluteString] compare:[anURL absoluteString]];
}

@end
