//
//  TR4Room.m
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

#import "TR4Room.h"
#import "TRLevelData.h"

@implementation TR4Room

- (TRLight)readLight:(TRLevelData *)levelData;
{
	TRLight result;
	
	int32_t position[3];
	[levelData readUint32Array:(uint32_t *) position count:3];
	
	result.position.x = (float) position[0] / 1024.0f;
	result.position.y = (float) position[1] / 1024.0f;
	result.position.z = (float) position[2] / 1024.0f;
	
	uint8_t color[3];
	[levelData readUint8Array:color count:3];
	result.color[0] = (float) color[0] / 255.0f;
	result.color[1] = (float) color[1] / 255.0f;
	result.color[2] = (float) color[2] / 255.0f;
	
	result.type = [levelData readUint8];
	
	[levelData skipBytes:1];
	
	int8_t intensity1 = [levelData readInt8];
	result.intensity = 1.0f - ((float) intensity1 + 1.0f) / 8192.0f;
	
	result.innerRadius = [levelData readFloat32] / 1024.0f;
	result.outerRadius = [levelData readFloat32] / 1024.0f;
	result.length = [levelData readFloat32] / 1024.0f;
	result.cutoffAngle = [levelData readFloat32];
	
	float direction[3];
	[levelData readFloat32Array:direction count:3];
	result.direction[0] = direction[0];
	result.direction[1] = direction[1];
	result.direction[2] = direction[2];
	
	return result;
}

@end
