//
//  TR2AnimatedObject.m
//  TRViewer
//
//  Created by Torsten on 13.06.06.
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

#import "TR2AnimatedObject.h"
#import "TRLevelData.h"
#import "MFunctions.h"

@implementation TR2AnimatedObject

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
	
	for (i = 0; i < meshCount; i++)
	{
		uint16_t frameword1 = [levelData readUint16];
		unsigned angleFlag = frameword1 & 0xC000;
		
		if (angleFlag == 0)
		{
			uint16_t frameword2 = [levelData readUint16];
			// Code from VT
			result.rotations[i].x = (float) ((frameword1 & 0x3ff0) >> 4);
			result.rotations[i].y = (float) (((frameword1 & 0x000f) << 6) | ((frameword2 & 0xfc00) >> 10));
			result.rotations[i].z = (float) (frameword2 & 0x03ff);
		}
		else if (angleFlag == 0x4000)
			result.rotations[i].x = (float) (frameword1 & 0x03FF);
		else if (angleFlag = 0x8000)
			result.rotations[i].y = (float) (frameword1 & 0x03FF);
		else if (angleFlag = 0xC000)
			result.rotations[i].z = (float) (frameword1 & 0x03FF);
		
		result.rotations[i] = MVecScale(result.rotations[i], 90.0f / 256.0f);
	}
	
	return result;
}

@end
