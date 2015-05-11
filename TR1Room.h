//
//  TR1Room.h
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

#import <Cocoa/Cocoa.h>
#import "TR1Level.h"

@class TRLevelData;
@class TR1Room;
@class TR1Mesh;

typedef struct
{
	MVec3 vertex;
	MVec3 normal;
	float color[4]; // RGBA, for direct feed to OpenGL
} TRRoomVertex;

typedef struct
{
	MVec3 vertices[4];
	MVec3 normals[4];
	unsigned pixelTexCoords[4][2];
	float colors[4][4]; // RGBA, so that we can feed it directly to OpenGL. Means reordering for TR5!
	unsigned textureIndex; // A room face will _always_ have a texture, _never_ a color. Ignore this once texCoords have been set.
	unsigned texturePage;
	BOOL hasAlpha;
	BOOL twoSided;
} TRRoomFace; // The 4th element of both vertices and texCoords is _undefined_ for triangles. It is not 0, it could and will be any garbage that happens to be around

typedef struct
{
	TR1Room *otherRoom;
	MVec3 normal;
	MVec3 vertices[4];
} TRRoomPortal;

typedef struct
{
	MVec3 position;
	float rotation; // in degrees
	BOOL externalLighting;
	float lightValue;
	TRStaticMesh *object;
} TRStaticMeshInstance;

typedef struct
{
	MVec3 position;
	float color[3];
	float intensity;
	float innerRadius;
	float outerRadius;
	float length;
	float cutoffAngle;
	float direction[3];
	enum
	{
		TRLightPoint = 1,
		TRLightSpot = 2,
		TRLightDirectional = 3
	} type;
} TRLight;

@interface TR1Room : NSObject 
{	
	float x, z;
	float lowY, highY;
	
	unsigned numVertices;
	TRRoomVertex *vertices;
	unsigned numRectangles;
	TRRoomFace *rectangles;
	unsigned numTriangles;
	TRRoomFace *triangles;
	
	unsigned numPortals;
	TRRoomPortal *portals;
	
	unsigned numStaticMeshes;
	TRStaticMeshInstance *staticMeshes;
	
	unsigned numLights;
	TRLight *lights;
	
	float lightIntensity;
	float roomLightColor[3];
	
	MVec3 max;
	MVec3 min;
	
	TR1Room *alternateRoom;
	
	TR1Level *level;
	
	int roomNumber;
	
	enum
	{
		TRRoomNormal,
		TRRoomOutside,
		TRRoomWater
	} roomType;
}

- (id)initWithLevelData:(TRLevelData *)levelData error:(NSError **)outError;

- (void)setLevel:(TR1Level *)level; // When this is called, the complete level should be completely initialized. It will set all pointers correctly, get texture coordinates and so on
- (TR1Level *)level;

- (unsigned)staticMeshCount;
- (TRStaticMeshInstance *)staticMeshes;

- (unsigned)rectangleCount;
- (TRRoomFace *)rectangles;

- (unsigned)triangleCount;
- (TRRoomFace *)triangles;

- (unsigned)portalCount;
- (TRRoomPortal *)portals;

- (void)getMidpoint:(MVec3 *)midpoint;
- (void)getRoomColor:(float *)roomColor;

- (NSNumber *)numberInLevel;

- (NSPoint)roomPosition;

- (void)readRoomInfo:(TRLevelData *)levelData;
- (void)readFirstLightInfo:(TRLevelData *)levelData;
- (void)readRoomFooter:(TRLevelData *)levelData;
- (TRRoomVertex)readRoomVertex:(TRLevelData *)levelData;
- (TRRoomFace)readRectangle:(TRLevelData *)levelData;
- (TRRoomFace)readTriangle:(TRLevelData *)levelData;
- (TRRoomPortal)readPortal:(TRLevelData *)levelData;
- (TRStaticMeshInstance)readStaticMesh:(TRLevelData *)levelData;
- (TRLight)readLight:(TRLevelData *)levelData;
- (void)determineNumberInLevel;
- (void)calculateBoundingBox;

@end
