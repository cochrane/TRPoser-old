//
//  TR1Mesh.h
//  TRViewer
//
//  Created by Torsten Kammer on 04.06.06.
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
#import "MTypes.h"

@class TR1Level;
@class TRLevelData;

typedef struct
{
	BOOL hasAlpha;
	float shininess;
	union
	{
		struct
		{
			unsigned pixelTexCoords[4][2];
			unsigned texturePageNumber;
		} texture;
		float color[4];
		unsigned tempIndex;
	} surface;
	union
	{
		MVec3 normals[4];
		float light[4]; // 0 - 1, 0 dark 1 light
	} lighting;
	MVec3 vertices[4];
} TRMeshFace;


@interface TR1Mesh : NSObject
{	
	MSphere collisionSphere;
			
	unsigned numVertices;
	MVec3 *vertices;
	BOOL internallyLit;
	MVec3 *normals;
	float *lightValues; // Only one of normals and lightValues is ever used
	
	unsigned numTexturedTriangles;
	TRMeshFace *texturedTriangles;
	
	unsigned numTexturedRectangles;
	TRMeshFace *texturedRectangles;

	unsigned numColoredTriangles;
	TRMeshFace *coloredTriangles;
	
	unsigned numColoredRectangles;
	TRMeshFace *coloredRectangles;
	
	TR1Level *level;
	
	int meshNumber;
}

- (id)initWithLevelData:(TRLevelData *)levelData error:(NSError **)outError;

- (void)setLevel:(TR1Level *)aLevel; // When this is called, the complete level should be completely initialized. It will set all pointers correctly, get texture coordinates and so on
- (TR1Level *)level;

- (unsigned)texturedTriangleCount;
- (TRMeshFace *)texturedTriangles;

- (unsigned)texturedRectangleCount;
- (TRMeshFace *)texturedRectangles;

- (unsigned)coloredTriangleCount;
- (TRMeshFace *)coloredTriangles;

- (unsigned)coloredRectangleCount;
- (TRMeshFace *)coloredRectangles;

- (BOOL)usesInternalLighting;

- (void)getMidpoint:(MVec3 *)midpoint;

- (NSNumber *)numberInLevel;

- (void)readCollisionSphereFrom:(TRLevelData *)levelData;
- (void)readVertexDataFrom:(TRLevelData *)levelData;
- (TRMeshFace)readTriangleFrom:(TRLevelData *)levelData;
- (TRMeshFace)readRectangleFrom:(TRLevelData *)levelData;

@end
