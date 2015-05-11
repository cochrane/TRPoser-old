//
//  TR5AnimatedObject.m
//  TRViewer
//
//  Created by Torsten on 14.07.06.
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

#import "TR5AnimatedObject.h"
#import "TRLevelData.h"

#warning TR5 is not supported, and attempting to load it will fail!

@implementation TR5AnimatedObject

- (id)initWithLevel:(TR1Level *)aLevel levelData:(TRLevelData *)levelData error:(NSError **)outError;
{
	if (![super initWithLevel:aLevel levelData:levelData error:outError])
	{
		return nil; // Whose damn job is releasing oneself when initing?
	}
	
	if ([levelData readUint16] != 0xFFEF) NSLog(@"Moveable filler might be wrong");
	
	return self;
}

@end
