//
//  NSImage_SubImage.m
//  TRViewer
//
//  Created by Torsten on 10.06.06.
//  Copyright 2006 Ferroequinologist.de. All rights reserved.
//
/*
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 * This file is part of TR Poser.
 *
 */

#import "NSImage_SubImage.h"


@implementation NSImage (SubImage)

- (NSImage *)subImageWithRect:(NSRect)aRect;
{
	NSImage *result = [[NSImage alloc] initWithSize:aRect.size];
	
	[result setFlipped:YES];
	[result lockFocus];
	
	//[self drawAtPoint:NSMakePoint(0.0f, 0.0f) fromRect:aRect operation:NSCompositeSourceOver fraction:1.0f];
	
	NSRect selfRect;
	selfRect.size = aRect.size;
	selfRect.origin = NSMakePoint(0.0f, 0.0f);
	[self drawInRect:selfRect fromRect:aRect operation:NSCompositeSourceOver fraction:1.0f];
	
	[result unlockFocus];
	
	[result autorelease];
	return result;
}

@end
