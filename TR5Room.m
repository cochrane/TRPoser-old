//
//  TR5Room.m
//  TRViewer
//
//  Created by Torsten on 08.07.06.
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

#import "TR5Room.h"
#import "TRLevelData.h"
#import "SimpleErrorCreation.h"
#import "MFunctions.h"

#warning TR5 is not supported, and attempting to load it will fail!

@implementation TR5Room

- (id)initWithLevelData:(TRLevelData *)levelData error:(NSError **)outError;
{
	if (![super init])
	{
		[self release];
		return nil;
	}
	
	level = nil;
	char shouldBeXela[4] = {'X', 'E', 'L', 'A'};
	char actualXela[4];
	[levelData readUint8Array:actualXela count:4];
	if (memcmp(actualXela, shouldBeXela, 4) != 0)
	{
		if (outError) *outError = [NSError trErrorWithCode:TRIndexOutOfBoundsErrorCode description:@"XELA was not found" moreInfo:@"An expected part of the file was not found. It is likely corrupt." localizationSuffix:@"No XELA"];
		NSLog(@"lacks XELA, got '%c' '%c' '%c' '%c' instead", actualXela[0], actualXela[1], actualXela[2], actualXela[3]);
		[self release];
		return nil;
	}
	
	unsigned roomDataSize = [levelData readUint32]; // idea with subdata here taken from vt, most of the rest code taken from there, too
	TRLevelData *roomData = [levelData subdataWithLength:roomDataSize];
	
	if ([roomData readUint32] != 0xCDCDCDCD) NSLog(@"Seperator 1 seems to have wrong value");
	
	unsigned portalOffset = [roomData readUint32];
	unsigned sectorDataOffset = [roomData readUint32];
	unsigned temp = [roomData readUint32];
	if ((temp != 0) && (temp != 0xCDCDCDCD)) NSLog(@"Seperator 2 seems to have wrong value");
	
	unsigned staticMeshOffset = [roomData readUint32];
	[self readRoomInfo:roomData];
	
	unsigned width = (unsigned) [roomData readUint16];
	unsigned length = (unsigned) [roomData readUint16];
	
	[self readFirstLightInfo:roomData];
	
	numLights = (unsigned) [roomData readUint16];
	numStaticMeshes = (unsigned) [roomData readUint16];
	[roomData skipBytes:4]; // Unknown
	if ([roomData readUint32] != 0x7FFF) NSLog(@"Filler 1 seems to have wrong value");
	if ([roomData readUint32] != 0x7FFF) NSLog(@"Filler 2 seems to have wrong value");
	if ([roomData readUint32] != 0xCDCDCDCD) NSLog(@"Seperator 3 seems to have wrong value");
	if ([roomData readUint32] != 0xCDCDCDCD) NSLog(@"Seperator 4 seems to have wrong value");
	[roomData skipBytes:6]; // Seperator 5
	unsigned roomTypeFlag = (unsigned) [roomData readUint16];
	if (roomTypeFlag == 0x01) roomType = TRRoomWater;
	else if (roomTypeFlag == 0x20) roomType = TRRoomOutside;
	else roomType = TRRoomNormal;
	
	[roomData skipBytes:2]; // Unknown
	[roomData skipBytes:10]; // Seperator 6
	temp = [roomData readUint32];
	if ((temp != 0) && (temp != 0xCDCDCDCD)) NSLog(@"Seperator 6.5 seems to have wrong value");
	[roomData skipBytes:4]; // unknown
	float floatX = [roomData readFloat32];
	temp = [roomData readUint32];
	if ((temp != 0) && (temp != 0xCDCDCDCD)) NSLog(@"Seperator 7 seems to have wrong value");
	float floatZ = [roomData readFloat32];
	if ([roomData readUint32] != 0xCDCDCDCD) NSLog(@"Seperator 8 seems to have wrong value");
	if ([roomData readUint32] != 0xCDCDCDCD) NSLog(@"Seperator 9 seems to have wrong value");
	if ([roomData readUint32] != 0xCDCDCDCD) NSLog(@"Seperator 10 seems to have wrong value");
	if ([roomData readUint32] != 0xCDCDCDCD) NSLog(@"Seperator 11 seems to have wrong value");
	temp = [roomData readUint32];
	if ((temp != 0) && (temp != 0xCDCDCDCD)) NSLog(@"Seperator 12 seems to have wrong value");
	if ([roomData readUint32] != 0xCDCDCDCD) NSLog(@"Seperator 13 seems to have wrong value");
	
	numTriangles = [roomData readUint32];
	if (numTriangles == 0xCDCDCDCD) numTriangles = 0;
	
	numRectangles = [roomData readUint32];
	if (numRectangles == 0xCDCDCDCD) numRectangles = 0;
	
	unsigned sep14 = [roomData readUint32];
	if (sep14 != 0x0) NSLog(@"Seperator 14 seems to have wrong value, is 0x%x", sep14);
	
	unsigned lightSize = [roomData readUint32];
	if ([roomData readUint32] != numLights) NSLog(@"Second num lights does not equal first one");
	
	[roomData skipBytes:4 * 2]; // 2 unknown uint32s
	[roomData skipBytes:4]; // second yBottom, unless null room
	
	numLayers = [roomData readUint32];
	unsigned layerOffset = [roomData readUint32];
	unsigned vertexOffset = [roomData readUint32];
	unsigned polygonOffset = [roomData readUint32];
	if ([roomData readUint32] != polygonOffset) NSLog(@"Second polygon offset does not equal first one");
	unsigned vertexSize = [roomData readUint32];
	if ([roomData readUint32] != 0xCDCDCDCD) NSLog(@"Seperator 14.5 seems to have wrong value");
	if ([roomData readUint32] != 0xCDCDCDCD) NSLog(@"Seperator 15 seems to have wrong value");
	if ([roomData readUint32] != 0xCDCDCDCD) NSLog(@"Seperator 16 seems to have wrong value");
	if ([roomData readUint32] != 0xCDCDCDCD) NSLog(@"Seperator 17 seems to have wrong value");
	
	unsigned i;
	lights = calloc(numLights, sizeof(TRLight));
	for (i = 0; i < numLights; i++)
		lights[i] = [self readLight:roomData];
		
	[roomData skipBytes:width * length * 8]; // Sector data, one day I might want to actually use that
	
	numPortals = [roomData readUint16];
	portals = calloc(numPortals, sizeof(TRRoomPortal));
	for (i = 0; i < numPortals; i++)
		portals[i] = [self readPortal:roomData];
	
	[roomData setPosition:208 + staticMeshOffset];
	
	staticMeshes = calloc(numStaticMeshes, sizeof(TRStaticMeshInstance));
	for (i = 0; i < numStaticMeshes; i++)
		staticMeshes[i] = [self readStaticMesh:roomData];
	
	[roomData setPosition:208 + layerOffset];
	
	layers = calloc(numLayers, sizeof(TRRoomLayer));
	for (i = 0; i < numLayers; i++)
		layers[i] = [self readLayerFrom:roomData];
		
	[roomData setPosition:208 + vertexOffset];
	
	numVertices = vertexSize / 28;
	vertices = calloc(numVertices, sizeof(TRRoomVertex));
	for (i = 0; i < numVertices; i++)
		vertices[i] = [self readRoomVertex:roomData];
	
	[roomData setPosition:208 + polygonOffset];
	
	triangles = calloc(numTriangles, sizeof(TRRoomFace));
	rectangles = calloc(numRectangles, sizeof(TRRoomFace));
	
	unsigned loadedRectangles = 0;
	unsigned loadedTriangles = 0;
	unsigned layerVertexOffset = 0;
	
	for (i = 0; i < numLayers; i++)
	{
		unsigned j;
		for (j = 0; j < layers[i].numRectangles; j++)
		{
			rectangles[loadedRectangles] = [self readRectangle:roomData layerOffset:layerVertexOffset];
			loadedRectangles++;
		}
		for (j = 0; j < layers[i].numTriangles; j++)
		{
			triangles[loadedTriangles] = [self readTriangle:roomData layerOffset:layerVertexOffset];
			loadedTriangles++;
		}
		layerVertexOffset += layers[i].numVertices;
	}
	
	roomNumber = -1;
	[self calculateBoundingBox];
	
	return self;
}

- (void)dealloc
{
	if (layers) free(layers);
	[super dealloc];
}

- (void)readRoomInfo:(TRLevelData *)levelData;
{
	int roomInfo[5];
	[levelData readUint32Array:(uint32_t *)roomInfo count:5];
	x = (float) roomInfo[0] / 1024.0f;
	z = (float) roomInfo[2] / 1024.0f;
	lowY = (float) roomInfo[3] / 1024.0f;
	highY = (float) roomInfo[4] / 1024.0f;
}

- (void)readFirstLightInfo:(TRLevelData *)levelData;
{
	uint8_t roomColor[4];
	[levelData readUint8Array:roomColor count:4];
	
	roomLightColor[0] = (float) roomColor[1] / 255.0f;
	roomLightColor[1] = (float) roomColor[2] / 255.0f;
	roomLightColor[2] = (float) roomColor[3] / 255.0f;
}

- (TRRoomLayer)readLayerFrom:(TRLevelData *)levelData;
{
	unsigned start = [levelData position];

	TRRoomLayer result;
	result.numVertices = (unsigned) [levelData readUint32];
	[levelData skipBytes:2]; // Unknown
	result.numRectangles = (unsigned) [levelData readUint16];
	result.numTriangles = (unsigned) [levelData readUint16];
	
	[levelData skipBytes:2]; // Unknown
	
	if ([levelData readUint16] != 0) NSLog(@"Layer filler 1 might be wrong");
	if ([levelData readUint16] != 0) NSLog(@"Layer filler 2 might be wrong");
	
	[levelData skipBytes:6 * 4]; // Layer bounding box
	
	if ([levelData readUint32] != 0) NSLog(@"Layer filler 3 might be wrong");
	
	[levelData skipBytes:3 * 4]; // Unknown
	
	return result;
}

- (TRRoomFace)readTriangle:(TRLevelData *)levelData layerOffset:(unsigned)layerOffset;
{
	TRRoomFace result;
	
	uint16_t vertexIndices[3];
	[levelData readUint16Array:vertexIndices count:3];
	
	unsigned i;
	for (i = 0; i < 3; i++)
	{
		result.vertices[i] = vertices[vertexIndices[i] + layerOffset].vertex;
		result.normals[i] = vertices[vertexIndices[i] + layerOffset].normal;
		result.colors[i][0] = vertices[vertexIndices[i] + layerOffset].color[0];
		result.colors[i][1] = vertices[vertexIndices[i] + layerOffset].color[1];
		result.colors[i][2] = vertices[vertexIndices[i] + layerOffset].color[2];
		result.colors[i][3] = vertices[vertexIndices[i] + layerOffset].color[3];
	}
	
	result.textureIndex = (unsigned) [levelData readUint16] & 0x0FFF; // High 4 bits are flags
	[levelData skipBytes:2]; // Unknown
	
	return result;
}
- (TRRoomFace)readRectangle:(TRLevelData *)levelData layerOffset:(unsigned)layerOffset;
{
	TRRoomFace result;
	
	uint16_t vertexIndices[4];
	[levelData readUint16Array:vertexIndices count:4];
	
	unsigned i;
	for (i = 0; i < 4; i++)
	{
		result.vertices[i] = vertices[vertexIndices[i] + layerOffset].vertex;
		result.normals[i] = vertices[vertexIndices[i] + layerOffset].normal;
		result.colors[i][0] = vertices[vertexIndices[i] + layerOffset].color[0];
		result.colors[i][1] = vertices[vertexIndices[i] + layerOffset].color[1];
		result.colors[i][2] = vertices[vertexIndices[i] + layerOffset].color[2];
		result.colors[i][3] = vertices[vertexIndices[i] + layerOffset].color[3];
	}
	
	result.textureIndex = (unsigned) [levelData readUint16] & 0x0FFF; // High 4 bits are flags
	[levelData skipBytes:2]; // Unknown
	
	return result;
}

- (TRRoomVertex)readRoomVertex:(TRLevelData *)levelData;
{
	TRRoomVertex result;
	
	result.normal = MMakeVec3(0.0f, 0.0f, 0.0f);
	
	[levelData readFloat32Array:&result.vertex.x count:3];
	MVecScale(result.vertex, 1.0f/1024.0f);
	
	[levelData readFloat32Array:&result.normal.x count:3];
	MVecNormalize(&result.normal);
	
	uint8_t color[4];
	[levelData readUint8Array:color count:4];
	
	result.color[0] = (float) color[1] / 255.0f;
	result.color[1] = (float) color[2] / 255.0f;
	result.color[2] = (float) color[3] / 255.0f;
	result.color[3] = (float) color[0] / 255.0f;
	
	return result;
}

@end
