//
//  TR4Mesh.m
//  TRViewer
//
//  Created by Torsten on 09.06.06.
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

#import "TR4Mesh.h"
#import "TR4Level.h"
#import "SimpleErrorCreation.h"
#import "TRLevelData.h"

@implementation TR4Mesh

- (id)initWithLevelData:(TRLevelData *)levelData error:(NSError **)error;
{
	if (![super init])
	{
		[self release];
		return nil;
	}

	[self readCollisionSphereFrom:levelData];
	[self readVertexDataFrom:levelData];
	
	unsigned i;
	
	@try
	{
		numTexturedRectangles = (unsigned) [levelData readUint16];
		if (numTexturedRectangles > 0)
		{
			texturedRectangles = calloc(numTexturedRectangles, sizeof(TRMeshFace));
			for (i = 0; i < numTexturedRectangles; i++)
				texturedRectangles[i] = [self readRectangleFrom:levelData];
		}
		else texturedRectangles = NULL;
		
		numTexturedTriangles = (unsigned) [levelData readUint16];
		if (numTexturedTriangles > 0)
		{
			texturedTriangles = calloc(numTexturedTriangles, sizeof(TRMeshFace));
			for (i = 0; i < numTexturedTriangles; i++)
				texturedTriangles[i] = [self readTriangleFrom:levelData];
		}
		else texturedTriangles = NULL;
		
		numColoredRectangles = 0;
		coloredRectangles = NULL;
		
		numColoredTriangles = 0;
		coloredTriangles = NULL;
	}
	@catch (NSException *exception)
	{
		DebugLog(@"%@ %@ caught exception: %@", [self className], self, exception);
		if (error) *error = [NSError trErrorWithCode:TRIndexOutOfBoundsErrorCode description:@"An interal index is out of bounds" moreInfo:@"A part of the file points to wrong other parts of the file. The level is likely corrupt" localizationSuffix:@"Generic index out of bounds"];
		// There is no other reason for failure at this point.
		[self release];
		return nil;
	}

	return self;
}

- (TRMeshFace)readTriangleFrom:(TRLevelData *)levelData;
{
	TRMeshFace result = [super readTriangleFrom:levelData];
	uint16_t lighting = [levelData readUint16];
	
	if (lighting & 0x1) result.hasAlpha = YES;
	else result.hasAlpha = NO;
	
	result.shininess = (float) (lighting & 0x7fff);
	
	result.surface.tempIndex = result.surface.tempIndex & 0x0FFF;
	
	return result;
}

- (TRMeshFace)readRectangleFrom:(TRLevelData *)levelData;
{
	TRMeshFace result = [super readRectangleFrom:levelData];
	uint16_t lighting = [levelData readUint16];
	
	if (lighting & 0x1) result.hasAlpha = YES;
	else result.hasAlpha = NO;
	
	result.shininess = (float) (lighting & 0x7fff);
	
	return result;
}

@end
