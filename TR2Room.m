//
//  TR2Room.m
//  TRViewer
//
//  Created by Torsten Kammer on 30.05.06.
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

#import "TR2Room.h"
#import "SimpleErrorCreation.h"
#import "TRLevelData.h"

@implementation TR2Room

- (TRRoomVertex)readRoomVertex:(TRLevelData *)levelData;
{
	TRRoomVertex result = [super readRoomVertex:levelData];
	[levelData skipBytes:4]; // Attributes + Second lighting attribute
	return result;
}

- (TRStaticMeshInstance)readStaticMesh:(TRLevelData *)levelData;
{
	TRStaticMeshInstance result = [super readStaticMesh:levelData];
	// What TR1 read into the objectID was actually the intensity2 field that TR2 added before the objectID. So we'll have to read that value again
	
	uint16_t objectID = [levelData readUint16];
	result.object = (TRStaticMesh *) (unsigned) objectID; // Notice how I store the index in the pointer. This will have to be changed once all meshes are created
	
	return result;
}

- (void)readFirstLightInfo:(TRLevelData *)levelData
{
	[super readFirstLightInfo:levelData];
	[levelData skipBytes:4]; // That is intensity2 and flicker attribute
}

- (TRLight)readLight:(TRLevelData *)levelData;
{
	TRLight result;
	
	int32_t position[3];
	[levelData readUint32Array:(uint32_t *) position count:3];
	
	result.position.x = (float) position[0] / 1024.0f;
	result.position.y = (float) position[1] / 1024.0f;
	result.position.z = (float) position[2] / 1024.0f;
	
	int16_t intensity1 = [levelData readInt16];
	result.intensity = 1.0f - ((float) intensity1 + 1.0f) / 8192.0f;
	[levelData skipBytes:2]; // intensity2
	
	int32_t fade1 = [levelData readInt32];
	result.length = fade1;
	[levelData skipBytes:4]; // fade2
	
	result.type = TRLightPoint;
	
	return result;
}

@end
