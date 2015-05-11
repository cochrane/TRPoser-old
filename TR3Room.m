//
//  TR3Room.m
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

#import "TR3Room.h"
#import "TRLevelData.h"
#import "TR1Level.h"

@implementation TR3Room

- (void)readFirstLightInfo:(TRLevelData *)levelData
{
	uint16_t intensity = [levelData readUint16];
	lightIntensity = (float) intensity / 32767.0f; // Thanks to vt project for this info on lighting
	[levelData skipBytes:2]; // That is intensity2, TR3 has no flicker attribute
}

- (void)readRoomFooter:(TRLevelData *)levelData;
{
	[super readRoomFooter:levelData];
	
	uint8_t roomColor[3];
	[levelData readUint8Array:roomColor count:3];
	
	roomLightColor[0] = (float) roomColor[0] / 255.0f;
	roomLightColor[1] = (float) roomColor[1] / 255.0f;
	roomLightColor[2] = (float) roomColor[2] / 255.0f;
}

- (void)setLevel:(TR1Level *)aLevel;
{
	level = aLevel;
	unsigned i, j;
	
	Class levelClass = [level class];
	
	for (i = 0; i < numPortals; i++)
		portals[i].otherRoom = [[level rooms] objectAtIndex:(unsigned) portals[i].otherRoom];
	
	for (i = 0; i < numStaticMeshes; i++)
	{
		unsigned staticMeshIndex = (unsigned) staticMeshes[i].object;
		staticMeshes[i].object = [level staticMeshWithObjectID:(unsigned) staticMeshIndex];
		if (!staticMeshes[i].object) [NSException raise:NSRangeException format:@"Static mesh at index %u could not be loaded", staticMeshIndex];
		staticMeshes[i].lightValue = [levelClass convertRawLightValue:staticMeshes[i].lightValue];
	}
	
	for (i = 0; i < numRectangles; i++)
	{
		TRTexture *texture = [level textureAtIndex:rectangles[i].textureIndex];
		if (!texture) [NSException raise:NSRangeException format:@"The texture at index %u could not be loaded", rectangles[i].textureIndex];
		for (j = 0; j < 4; j++)
		{
			rectangles[i].pixelTexCoords[j][0] = texture->coords[j][0];
			rectangles[i].pixelTexCoords[j][1] = texture->coords[j][1];
			float lightValue = [levelClass convertRawLightValue:rectangles[i].colors[j][0]];
			rectangles[i].colors[j][0] = lightValue;
			rectangles[i].colors[j][1] = lightValue;
			rectangles[i].colors[j][2] = lightValue;
		}
		if (texture->transparency == TRTextureAlphaAdd) rectangles[i].hasAlpha = YES;
		rectangles[i].texturePage = texture->texturePageNumber;
	}
		
	for (i = 0; i < numTriangles; i++)
	{
		TRTexture *texture = [level textureAtIndex:triangles[i].textureIndex];
		if (!texture) [NSException raise:NSRangeException format:@"The texture at index %u could not be loaded", triangles[i].textureIndex];
		for (j = 0; j < 3; j++)
		{
			triangles[i].pixelTexCoords[j][0] = texture->coords[j][0];
			triangles[i].pixelTexCoords[j][1] = texture->coords[j][1];
			float lightValue = [levelClass convertRawLightValue:triangles[i].colors[j][0]];
			triangles[i].colors[j][0] = lightValue;
			triangles[i].colors[j][1] = lightValue;
			triangles[i].colors[j][2] = lightValue;
		}
		if (texture->transparency == TRTextureAlphaAdd) triangles[i].hasAlpha = YES;
		triangles[i].texturePage = texture->texturePageNumber;
	}
	
	for (i = 0; i < numLights; i++)
	{
		lights[i].intensity = [levelClass convertRawLightValue:lights[i].intensity];
	}
	
	if (alternateRoom) alternateRoom = [[level rooms] objectAtIndex:(unsigned) alternateRoom];
	
	lightIntensity = [levelClass convertRawLightValue:lightIntensity];
	
	[self determineNumberInLevel];
}

- (void)getRoomColor:(float *)roomColor;
{
	roomColor[0] = 1.0f;
	roomColor[1] = 1.0f;
	roomColor[2] = 1.0f;
}

@end
