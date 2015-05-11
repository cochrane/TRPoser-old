//
//  TRAnimatedObject.m
//  TRViewer
//
//  Created by Torsten on 11.06.06.
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

#import "TR1AnimatedObject.h"
#import "TRLevelData.h"
#import "MFunctions.h"

@implementation TR1AnimatedObject

- (id)initWithLevel:(TR1Level *)aLevel levelData:(TRLevelData *)levelData error:(NSError **)outError;
{
	if (![super init])
	{
		[self release];
		return nil;
	}
	objectID = [levelData readUint32];
	
	level = aLevel;
	
	unsigned numMeshes = (unsigned) [levelData readUint16];
	unsigned startingMesh = (unsigned) [levelData readUint16];
	NSMutableArray *mutableMeshes = [[NSMutableArray alloc] initWithCapacity:numMeshes];
	unsigned i;
	for (i = 0; i < numMeshes; i++)
	{
		TR1Mesh *mesh = [[level meshes] objectAtIndex:startingMesh + i];
		[mutableMeshes addObject:mesh];
	}
	meshes = [mutableMeshes copy];
	[mutableMeshes release];
	
	meshTreeOffset = [levelData readUint32];
	frameOffset = [levelData readUint32];
	animationOffset = (unsigned) [levelData readUint16];
	
	return self;
}

- (void)dealloc
{
	unsigned i;
	for (i = 0; i < numFrames; i++) free(frames[i].rotations);
	free(frames);
	[meshes release];
	[super dealloc];
}

- (void)readMeshTreeFrom:(TRLevelData *)levelData;
{
	unsigned i;
	unsigned meshCount = [meshes count];
	if (meshCount == 0)
	{
		meshTreeNodes = NULL;
		return;
	}
	
	[levelData skipBytes:4 + meshTreeOffset * 4];
	
	meshTreeNodes = calloc(meshCount, sizeof(TRMeshTreeNode));
	
	meshTreeNodes[0].pushParent = YES;
	meshTreeNodes[0].popParent = NO;
	meshTreeNodes[0].offset = MMakeVec3(0.0f, 0.0f, 0.0f);
	meshTreeNodes[0].mesh = [meshes objectAtIndex:0];
	
	for (i = 1; i < meshCount; i++)
	{
		meshTreeNodes[i].pushParent = NO;
		meshTreeNodes[i].popParent = NO;
		
		unsigned stackOp = [levelData readUint32];
		if (stackOp & 0x0001) meshTreeNodes[i].popParent = YES;
	
		if (stackOp & 0x0002) meshTreeNodes[i].pushParent = YES;
	
		meshTreeNodes[i].offset.x = (float) [levelData readInt32] / 1024.0f;
		meshTreeNodes[i].offset.y = (float) [levelData readInt32] / 1024.0f;
		meshTreeNodes[i].offset.z = (float) [levelData readInt32] / 1024.0f;
		
		meshTreeNodes[i].mesh = [meshes objectAtIndex:i];
	}
}

- (void)readAnimationsFrom:(TRLevelData *)levelData
{
	// Should be filled in later
}

- (void)readFramesFrom:(TRLevelData *)levelData;
{
	[levelData skipBytes:4 + frameOffset];
	numFrames = 1;
	frames = calloc(1, sizeof(TRAnimationFrame));
	frames[0] = [self readFrameFrom:levelData];
}

- (TRAnimationFrame)readFrameFrom:(TRLevelData *)levelData;
{
	TRAnimationFrame result;
	
	result.boundingBox[0].x = (float) [levelData readInt16] / 1024.0f;
	result.boundingBox[0].y = (float) [levelData readInt16] / 1024.0f;
	result.boundingBox[0].z = (float) [levelData readInt16] / 1024.0f;
	
	result.boundingBox[1].x = (float) [levelData readInt16] / 1024.0f;
	result.boundingBox[1].y = (float) [levelData readInt16] / 1024.0f;
	result.boundingBox[1].z = (float) [levelData readInt16] / 1024.0f;
	
	result.offset.x = (float) [levelData readInt16] / 1024.0f;
	result.offset.y = (float) [levelData readInt16] / 1024.0f;
	result.offset.z = (float) [levelData readInt16] / 1024.0f;
	
	unsigned meshCount = [meshes count];
	result.rotations = malloc(sizeof(MVec3) * meshCount);
	
	unsigned i;
	for (i = 0; i < meshCount; i++)
	{
		result.rotations[i].x = 0.0f;
		result.rotations[i].y = 0.0f;
		result.rotations[i].z = 0.0f;
	}
	
	unsigned numValues = [levelData readUint16];
	
	for (i = 0; i < numValues; i++)
	{
		// The order looks wrong, but it's not. Code comes from VT Project
		uint16_t frameword2 = [levelData readUint16];
		uint16_t frameword1 = [levelData readUint16];
	
		result.rotations[i].x = (float) ((frameword1 & 0x3ff0) >> 4);
		result.rotations[i].y = (float) (((frameword1 & 0x000f) << 6) | ((frameword2 & 0xfc00) >> 10));
		result.rotations[i].z = (float) (frameword2 & 0x03ff);
		
		result.rotations[i] = MVecScale(result.rotations[i], 360.0f / 1024.0f);
	}
	
	return result;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p, objectID=%u>", [self className], self, objectID];
}

- (unsigned)meshCount
{
	return [meshes count];
}

- (TRMeshTreeNode *)meshTreeNodes
{
	return meshTreeNodes;
}

- (TRAnimationFrame *)frames;
{
	return frames;
}

- (TR1Level *)level;
{
	return level;
}

- (unsigned)objectID;
{
	return objectID;
}

@end
