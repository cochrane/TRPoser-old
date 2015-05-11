//
//  TR1Room.m
//  TRViewer
//
//  Created by Torsten Kammer on 29.05.06.
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

#import "TR1Room.h"
#import "SimpleErrorCreation.h"
#import "TRLevelData.h"
#import "TR1Level.h"
#import "MFunctions.h"

@implementation TR1Room

- (id)initWithLevelData:(TRLevelData *)levelData error:(NSError **)error;
{
	if (![super init])
	{
		[self release];
		return nil;
	}
	
	level = nil;
	
	[self readRoomInfo:levelData];
	unsigned roomDataLength = [levelData readUint32];
	unsigned roomStartPosition = [levelData position];
	unsigned i;
	
	numVertices = (unsigned) [levelData readUint16];
	vertices = calloc(numVertices, sizeof(TRRoomVertex));
	for (i = 0; i < numVertices; i++)
		vertices[i] = [self readRoomVertex:levelData];

	@try
	{
		numRectangles = (unsigned) [levelData readUint16];
		rectangles = calloc(numRectangles, sizeof(TRRoomFace));
		for (i = 0; i < numRectangles; i++)
			rectangles[i] = [self readRectangle:levelData];
	}
	@catch (NSException *exception)
	{
		DebugLog(@"TR1Room caught exception %@", exception);
		if (error) *error = [NSError trErrorWithCode:TRIndexOutOfBoundsErrorCode description:@"An interal index is out of bounds" moreInfo:@"A part of the file points to wrong other parts of the file. The level is likely corrupt" localizationSuffix:@"Generic index out of bounds"];
		[self release];
		return nil;
	}
	
	@try
	{
		numTriangles = (unsigned) [levelData readUint16];
		triangles = calloc(numTriangles, sizeof(TRRoomFace));
		for (i = 0; i < numTriangles; i++)
			triangles[i] = [self readTriangle:levelData];
	}
	@catch (NSException *exception)
	{
		DebugLog(@"TR1Room caught exception %@", exception);
		if (error) *error = [NSError trErrorWithCode:TRIndexOutOfBoundsErrorCode description:@"An interal index is out of bounds" moreInfo:@"A part of the file points to wrong other parts of the file. The level is likely corrupt" localizationSuffix:@"Generic index out of bounds"];
		[self release];
		return nil;
	}
	
	//DebugLog(@"length till here is %u, rdl*2 is %u", [levelData position] - roomStartPosition, roomDataLength*2);
	
	unsigned actualLength = [levelData position] - roomStartPosition + 2;
	if (actualLength != roomDataLength*2)
	{
		DebugLog(@"Possible error here: actual length is %u, expected lengt is %u", actualLength - 2, roomDataLength * 2);
//		if (error) *error = [NSError trErrorWithCode:TRRoomLoadingUnspecificError description:@"The length of a room structure is wrong" moreInfo:@"A part of the file has a wrong length. The file is likely to be corrupt." localizationSuffix:@"Room data length mismatch"];
//		[self release];
//		return nil;
	}
	
	[levelData skipField16:4]; // Sprites
	
	numPortals = (unsigned) [levelData readUint16];
	portals = calloc(numPortals, sizeof(TRRoomPortal));
	for (i = 0; i < numPortals; i++)
		portals[i] = [self readPortal:levelData];
	
	unsigned width = (unsigned) [levelData readUint16];
	unsigned length = (unsigned) [levelData readUint16];
	[levelData skipBytes:width * length * 8];
	
	[self readFirstLightInfo:levelData];
	
	numLights = (unsigned) [levelData readUint16];
	lights = calloc(numLights, sizeof(TRLight));
	for (i = 0; i < numLights; i++)
		lights[i] = [self readLight:levelData];
		
	numStaticMeshes = (unsigned) [levelData readUint16];
	staticMeshes = calloc(numStaticMeshes, sizeof(TRStaticMeshInstance));
	for (i = 0; i < numStaticMeshes; i++)
		staticMeshes[i] = [self readStaticMesh:levelData];
	
	alternateRoom = (TR1Room *) (unsigned) [levelData readUint16];
	if (alternateRoom == (TR1Room *) 0xffff) alternateRoom = nil;
	
	[self readRoomFooter:levelData];
	
	if ([levelData isAtEnd])
	{
		if (error) *error = [NSError trErrorWithCode:TRPrematureEndOfFileErrorCode description:@"The file ends too early" moreInfo:@"The level does not have all the data it needs to be complete. If you downloaded it, please download it again" localizationSuffix:@"Generic file ends when it shouldn't error"];
		[self release];
		return nil;
	}
	
	roomNumber = -1;
	[self calculateBoundingBox];
	
	return self;
}

- (void)dealloc
{
	if (lights) free(lights);
	if (staticMeshes) free(staticMeshes);
	if (portals) free(portals);
	if (rectangles) free(rectangles);
	if (triangles) free(triangles);
	if (vertices) free(vertices);
	[super dealloc];
}

- (void)getRoomColor:(float *)roomColor;
{
	roomColor[0] = roomLightColor[0];
	roomColor[1] = roomLightColor[1];
	roomColor[2] = roomLightColor[2];
}

- (void)calculateBoundingBox;
{
	unsigned i, j;
	
	max.x = max.y = max.z = -1000.0f;
	min.x = min.y = min.z = 1000.0f;

	for (i = 0; i < numTriangles; i++)
	{
		for (j = 0; j < 3; j++)
		{
			float vertexValue = triangles[i].vertices[j].x;
			if (vertexValue > max.x) max.x = vertexValue;
			if (vertexValue < min.x) min.x = vertexValue;
			
			vertexValue = triangles[i].vertices[j].y;
			if (vertexValue > max.y) max.y = vertexValue;
			if (vertexValue < min.y) min.y = vertexValue;
			
			vertexValue = triangles[i].vertices[j].z;
			if (vertexValue > max.z) max.z = vertexValue;
			if (vertexValue < min.z) min.z = vertexValue;
		}
	}
	
	for (i = 0; i < numRectangles; i++)
	{
		for (j = 0; j < 4; j++)
		{
			float vertexValue = rectangles[i].vertices[j].x;
			if (vertexValue > max.x) max.x = vertexValue;
			if (vertexValue < min.x) min.x = vertexValue;
			
			vertexValue = rectangles[i].vertices[j].y;
			if (vertexValue > max.y) max.y = vertexValue;
			if (vertexValue < min.y) min.y = vertexValue;
			
			vertexValue = rectangles[i].vertices[j].z;
			if (vertexValue > max.z) max.z = vertexValue;
			if (vertexValue < min.z) min.z = vertexValue;
		}
	}
}

- (void)getMidpoint:(MVec3 *)midpoint;
{	
	midpoint->x = (max.x + min.x) / 2.0f;
	midpoint->y = (max.y + min.y) / 2.0f;
	midpoint->z = (max.z + min.z) / 2.0f;
}

- (NSNumber *)numberInLevel;
{
	return [NSNumber numberWithInt:roomNumber];
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
			if (roomType != TRRoomWater)
			{
				rectangles[i].colors[j][0] = lightValue;
				rectangles[i].colors[j][1] = lightValue;
			}
			else
			{
				// The magic value 0.78 was gotten by trial and error. Feel free to adjust it for better results
				rectangles[i].colors[j][0] = 0.78f * lightValue;
				rectangles[i].colors[j][1] = 0.78f * lightValue;
			}
			rectangles[i].colors[j][2] = lightValue;
		}
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

- (TR1Level *)level;
{
	return level;
}

- (NSPoint)roomPosition;
{
	return NSMakePoint(x, z);
}

- (void)readRoomInfo:(TRLevelData *)levelData;
{
	int roomInfo[4];
	[levelData readUint32Array:(uint32_t *)roomInfo count:4];
	x = (float) roomInfo[0] / 1024.0f;
	z = (float) roomInfo[1] / 1024.0f;
	lowY = (float) roomInfo[2] / 1024.0f;
	highY = (float) roomInfo[3] / 1024.0f;
}

- (TRRoomVertex)readRoomVertex:(TRLevelData *)levelData;
{
	TRRoomVertex result;
	short position[3];
	[levelData readUint16Array:(uint16_t *)position count:3];
	result.vertex.x = (float) position[0] / 1024.0f;
	result.vertex.y = (float) position[1] / 1024.0f;
	result.vertex.z = (float) position[2] / 1024.0f;
	
	short lighting = [levelData readUint16];
	result.color[0] = (float) lighting;
	result.color[1] = (float) lighting;
	result.color[2] = (float) lighting;
	result.color[3] = 1.0f;
	
	result.normal = MMakeVec3(0.0f, 0.0f, 0.0f);
	
	return result;
}

- (TRRoomFace)readRectangle:(TRLevelData *)levelData;
{
	TRRoomFace result;
	
	uint16_t vertexIndices[4];
	[levelData readUint16Array:vertexIndices count:4];
	uint16_t surfaceAttrib = (unsigned) [levelData readUint16];
	result.textureIndex = surfaceAttrib & 0x7fff;
	result.twoSided = surfaceAttrib > 0x7fff;
	result.hasAlpha = NO;
	unsigned i;
	for (i = 0; i < 4; i++)
	{
		if (vertexIndices[i] >= numVertices) [NSException raise:NSRangeException format:@"The index %u is equal or larger to the number of vertices %u, this is not allowed", vertexIndices[i], numVertices];
		result.vertices[i] = vertices[vertexIndices[i]].vertex;
		result.colors[i][0] = vertices[vertexIndices[i]].color[0];
		result.colors[i][1] = vertices[vertexIndices[i]].color[1];
		result.colors[i][2] = vertices[vertexIndices[i]].color[2];
		result.colors[i][3] = vertices[vertexIndices[i]].color[3];
		result.normals[i] = vertices[vertexIndices[i]].normal;
	}
	
	return result;
}

- (TRRoomFace)readTriangle:(TRLevelData *)levelData;
{
	TRRoomFace result;
	
	uint16_t vertexIndices[3];
	[levelData readUint16Array:vertexIndices count:3];
	uint16_t surfaceAttrib = (unsigned) [levelData readUint16];
	result.textureIndex = surfaceAttrib & 0x7fff;
	result.twoSided = surfaceAttrib & (1 << 15);
	result.hasAlpha = NO;
	unsigned i;
	for (i = 0; i < 3; i++)
	{
		if (vertexIndices[i] >= numVertices) [NSException raise:NSRangeException format:@"The index %u is equal or larger to the number of vertices %u, this is not allowed", vertexIndices[i], numVertices];
		result.vertices[i] = vertices[vertexIndices[i]].vertex;
		result.colors[i][0] = vertices[vertexIndices[i]].color[0];
		result.colors[i][1] = vertices[vertexIndices[i]].color[1];
		result.colors[i][2] = vertices[vertexIndices[i]].color[2];
		result.colors[i][3] = vertices[vertexIndices[i]].color[3];
		result.normals[i] = MMakeVec3(0.0f, 0.0f, 0.0f);
	}
	
	return result;
}

- (TRRoomPortal)readPortal:(TRLevelData *)levelData;
{
	TRRoomPortal result;
	
	result.otherRoom = (TR1Room *) (unsigned) [levelData readUint16]; // Notice how I store the index in the pointer. This will have to be changed once all rooms are created
	int16_t normal[3];
	[levelData readUint16Array:(uint16_t *) normal count:3];
	result.normal.x = (float) normal[0];
	result.normal.y = (float) normal[1];
	result.normal.z = (float) normal[2];
	MVecNormalize(&result.normal);
	
	unsigned i;
	for (i = 0; i < 4; i++)
	{
		int16_t vertex[3];
		[levelData readUint16Array:(void *)vertex count:3];
		result.vertices[i].x = (float) vertex[0] / 1024.0f;
		result.vertices[i].y = (float) vertex[1] / 1024.0f;
		result.vertices[i].z = (float) vertex[2] / 1024.0f;
	}
	
	return result;
}

- (TRStaticMeshInstance)readStaticMesh:(TRLevelData *)levelData;
{
	TRStaticMeshInstance result;
	
	int32_t position[3];
	[levelData readUint32Array:(uint32_t *)position count:3];
	
	result.position.x = (float) position[0] / 1024.0f;
	result.position.y = (float) position[1] / 1024.0f;
	result.position.z = (float) position[2] / 1024.0f;

	uint16_t rotation = [levelData readUint16];
	result.rotation = (float) (rotation >> 14) * 90.f;
	
	int16_t intensity1 = [levelData readUint16];
	if (intensity1 < 0) result.externalLighting = YES;
	else
	{
		result.externalLighting = NO;
		result.lightValue = (float) intensity1;
	}
	
	uint16_t objectID = [levelData readUint16];
	result.object = (TRStaticMesh *) (unsigned) objectID; // Notice how I store the index in the pointer. This will have to be changed once all meshes are created
	
	return result;
}

- (void)readFirstLightInfo:(TRLevelData *)levelData;
{
	uint16_t intensity = [levelData readUint16];
	lightIntensity = (float) intensity;
}

- (void)readRoomFooter:(TRLevelData *)levelData;
{
	uint16_t flags = [levelData readUint16];
	if (flags & 1) roomType = TRRoomWater;
	else roomType = TRRoomNormal;
	
	roomLightColor[0] = 1.0f;
	roomLightColor[1] = 1.0f;
	roomLightColor[2] = 1.0f;
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
	result.intensity = (float) intensity1;
	
	int32_t fade1 = [levelData readInt32];
	result.length = fade1;
	
	result.type = TRLightPoint;
	
	return result;
}

- (void)determineNumberInLevel;
{
	if (!level) return;
	
	unsigned index = [[level rooms] indexOfObject:self];
	roomNumber = (int) index;
}

- (unsigned)rectangleCount;
{
	return numRectangles;
}
- (TRRoomFace *)rectangles;
{
	return rectangles;
}

- (unsigned)triangleCount;
{
	return numTriangles;
}
- (TRRoomFace *)triangles;
{
	return triangles;
}

- (unsigned)staticMeshCount;
{
	return numStaticMeshes;
}
- (TRStaticMeshInstance *)staticMeshes;
{
	return staticMeshes;
}

- (unsigned)portalCount;
{
	return numPortals;
}
- (TRRoomPortal *)portals;
{
	return portals;
}

@end
