//
//  TR1Mesh.m
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

#import "TR1Mesh.h"
#import "TR1Level.h"
#import "TRLevelData.h"
#import "SimpleErrorCreation.h"
#import "MFunctions.h"

@implementation TR1Mesh

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
		
		numColoredRectangles = (unsigned) [levelData readUint16];
		if (numColoredRectangles > 0)
		{
			coloredRectangles = calloc(numColoredRectangles, sizeof(TRMeshFace));
			for (i = 0; i < numColoredRectangles; i++)
				coloredRectangles[i] = [self readRectangleFrom:levelData];
		}
		else coloredRectangles = NULL;
		
		numColoredTriangles = (unsigned) [levelData readUint16];
		if (numColoredTriangles > 0)
		{
			coloredTriangles = calloc(numColoredTriangles, sizeof(TRMeshFace));
			for (i = 0; i < numColoredTriangles; i++)
				coloredTriangles[i] = [self readTriangleFrom:levelData];
		}
		else coloredTriangles = NULL;
	}
	@catch (NSException *exception)
	{
		DebugLog(@"%@ %@ caught exception: %@", [self className], self, exception);
		if (error) *error = [NSError trErrorWithCode:TRIndexOutOfBoundsErrorCode description:@"An interal index is out of bounds" moreInfo:@"A part of the file points to wrong other parts of the file. The level is likely corrupt" localizationSuffix:@"Generic index out of bounds"];
		// There is no other reason for failure at this point.
		[self release];
		return nil;
	}
	
	meshNumber = -1;

	return self;
}

- (void)dealloc
{
	if (vertices) free(vertices);
	if (normals) free(normals);
	if (lightValues) free(lightValues);
	
	if (texturedTriangles) free(texturedTriangles);
	if (texturedRectangles) free(texturedRectangles);
	if (coloredTriangles) free(coloredTriangles);
	if (coloredRectangles) free(coloredRectangles);
	
	[super dealloc];
}

- (void)setLevel:(TR1Level *)aLevel;
{
	level = aLevel;
		
	meshNumber = (int) [[level meshes] indexOfObject:self];
	unsigned basePage = [level meshTextureBasePage];
	
	unsigned i, j;
	
	for (i = 0; i < numTexturedTriangles; i++)
	{
		TRTexture *texture = [level textureAtIndex:texturedTriangles[i].surface.tempIndex];
		for (j = 0; j < 3; j++)
		{
			texturedTriangles[i].surface.texture.pixelTexCoords[j][0] = texture->coords[j][0];
			texturedTriangles[i].surface.texture.pixelTexCoords[j][1] = texture->coords[j][1];
		}
		if (texture->transparency == TRTextureAlphaAdd) texturedTriangles[i].hasAlpha = YES;
		texturedTriangles[i].surface.texture.texturePageNumber = texture->texturePageNumber + basePage;
	}
	
	for (i = 0; i < numTexturedRectangles; i++)
	{
		TRTexture *texture = [level textureAtIndex:texturedRectangles[i].surface.tempIndex];
		for (j = 0; j < 4; j++)
		{
			texturedRectangles[i].surface.texture.pixelTexCoords[j][0] = texture->coords[j][0];
			texturedRectangles[i].surface.texture.pixelTexCoords[j][1] = texture->coords[j][1];
		}
		if (texture->transparency == TRTextureAlphaAdd) texturedRectangles[i].hasAlpha = YES;
		texturedRectangles[i].surface.texture.texturePageNumber = texture->texturePageNumber + basePage;
	}
	
	for (i = 0; i < numColoredTriangles; i++)
		[level getColor:coloredTriangles[i].surface.color forPaletteIndex:coloredTriangles[i].surface.tempIndex];
	
	for (i = 0; i < numColoredRectangles; i++)
		[level getColor:coloredRectangles[i].surface.color forPaletteIndex:coloredRectangles[i].surface.tempIndex];
}

- (TR1Level *)level;
{
	return level;
}

- (NSNumber *)numberInLevel;
{
	return [NSNumber numberWithInt:meshNumber];
}

- (void)getMidpoint:(MVec3 *)midpoint;
{
	unsigned i, j;
	MVec3 max = {-100000.0f, -100000.0f, -100000.0f};
	MVec3 min = {100000.0f, 100000.0f, 100000.0f};

	for (i = 0; i < numColoredTriangles; i++)
	{
		for (j = 0; j < 3; j++)
		{
			float vertexValue = coloredTriangles[i].vertices[j].x;
			if (vertexValue > max.x) max.x = vertexValue;
			if (vertexValue < min.x) min.x = vertexValue;
			
			vertexValue = coloredTriangles[i].vertices[j].y;
			if (vertexValue > max.y) max.y = vertexValue;
			if (vertexValue < min.y) min.y = vertexValue;
			
			vertexValue = coloredTriangles[i].vertices[j].z;
			if (vertexValue > max.z) max.z = vertexValue;
			if (vertexValue < min.z) min.z = vertexValue;
		}
	}
	
	for (i = 0; i < numColoredRectangles; i++)
	{
		for (j = 0; j < 4; j++)
		{
			float vertexValue = coloredRectangles[i].vertices[j].x;
			if (vertexValue > max.x) max.x = vertexValue;
			if (vertexValue < min.x) min.x = vertexValue;
			
			vertexValue = coloredRectangles[i].vertices[j].y;
			if (vertexValue > max.y) max.y = vertexValue;
			if (vertexValue < min.y) min.y = vertexValue;
			
			vertexValue = coloredRectangles[i].vertices[j].z;
			if (vertexValue > max.z) max.z = vertexValue;
			if (vertexValue < min.z) min.z = vertexValue;
		}
	}
	
	for (i = 0; i < numTexturedTriangles; i++)
	{
		for (j = 0; j < 3; j++)
		{
			float vertexValue = texturedTriangles[i].vertices[j].x;
			if (vertexValue > max.x) max.x = vertexValue;
			if (vertexValue < min.x) min.x = vertexValue;
			
			vertexValue = texturedTriangles[i].vertices[j].y;
			if (vertexValue > max.y) max.y = vertexValue;
			if (vertexValue < min.y) min.y = vertexValue;
			
			vertexValue = texturedTriangles[i].vertices[j].z;
			if (vertexValue > max.z) max.z = vertexValue;
			if (vertexValue < min.z) min.z = vertexValue;
		}
	}
	
	for (i = 0; i < numTexturedRectangles; i++)
	{
		for (j = 0; j < 4; j++)
		{
			float vertexValue = texturedRectangles[i].vertices[j].x;
			if (vertexValue > max.x) max.x = vertexValue;
			if (vertexValue < min.x) min.x = vertexValue;
			
			vertexValue = texturedRectangles[i].vertices[j].y;
			if (vertexValue > max.y) max.y = vertexValue;
			if (vertexValue < min.y) min.y = vertexValue;
			
			vertexValue = texturedRectangles[i].vertices[j].z;
			if (vertexValue > max.z) max.z = vertexValue;
			if (vertexValue < min.z) min.z = vertexValue;
		}
	}
	
	midpoint->x = (max.x + min.x) / 2.0f;
	midpoint->y = (max.y + min.y) / 2.0f;
	midpoint->z = (max.z + min.z) / 2.0f;
}

- (void)readCollisionSphereFrom:(TRLevelData *)levelData;
{
	int16_t position[3];
	[levelData readUint16Array:(void *)position count:3];
	collisionSphere.center.x = (float) position[0] / 1024.0f;
	collisionSphere.center.y = (float) position[1] / 1024.0f;
	collisionSphere.center.z = (float) position[2] / 1024.0f;
	
	int radius = [levelData readInt32];
	collisionSphere.radius = (float) radius / 1024.0f;
}

- (void)readVertexDataFrom:(TRLevelData *)levelData;
{
	numVertices = [levelData readUint16];
	unsigned i;
	vertices = calloc(numVertices, sizeof(MVec3));
	for (i = 0; i < numVertices; i++)
	{
		int16_t vertex[3];
		[levelData readUint16Array:(void *)vertex count:3];
		vertices[i].x = (float) vertex[0] / 1024.0f;
		vertices[i].y = (float) vertex[1] / 1024.0f;
		vertices[i].z = (float) vertex[2] / 1024.0f;
	}

	int numNormals = (int) [levelData readInt16];
	if (numNormals < 0) internallyLit = YES;
	else if (numNormals == numVertices) internallyLit = NO;
	
	if (internallyLit)
	{
		normals = NULL;
		lightValues = calloc(numVertices, sizeof(float));
		for (i = 0; i < numVertices; i++)
		{
			uint16_t intensity = [levelData readUint16];
			lightValues[i] = 1.0f - ((float) intensity + 1.0f) / 8192.0f;
		}
	}
	else
	{
		lightValues = NULL;
		normals = calloc(numVertices, sizeof(MVec3));
		for (i = 0; i < numVertices; i++)
		{
			int16_t normal[3];
			[levelData readUint16Array:(void *)normal count:3];
			
			normals[i].x = (float) normal[0];
			normals[i].y = (float) normal[1];
			normals[i].z = (float) normal[2];
			
			MVecNormalize(&normals[i]);
		}
	}
}

- (TRMeshFace)readTriangleFrom:(TRLevelData *)levelData;
{
	TRMeshFace result;
	
	uint16_t vertexIndices[3];
	[levelData readUint16Array:vertexIndices count:3];
	uint16_t surfaceIndex = [levelData readUint16];
	
	result.hasAlpha = NO;
	result.shininess = 0;
	result.surface.tempIndex = surfaceIndex;
	
	// Assign vertices
	unsigned i;
	for (i = 0; i < 3; i++)
	{
		if (vertexIndices[i] >= numVertices) [NSException raise:NSRangeException format:@"The index %u is equal or larger to the number of vertices %u, this is not allowed", vertexIndices[i], numVertices];
		
		result.vertices[i] = vertices[vertexIndices[i]];
				
		if (internallyLit) result.lighting.light[i] = lightValues[vertexIndices[i]];
		else result.lighting.normals[i] = normals[vertexIndices[i]];
	}
	
	return result;
}

- (TRMeshFace)readRectangleFrom:(TRLevelData *)levelData;
{
	TRMeshFace result;
	
	uint16_t vertexIndices[4];
	[levelData readUint16Array:vertexIndices count:4];
	uint16_t surfaceIndex = [levelData readUint16];
	
	result.hasAlpha = NO;
	result.shininess = 0;
	result.surface.tempIndex = surfaceIndex;
	
	// Assign vertices
	unsigned i;
	for (i = 0; i < 4; i++)
	{
		if (vertexIndices[i] >= numVertices) [NSException raise:NSRangeException format:@"The index %u is equal or larger to the number of vertices %u, this is not allowed", vertexIndices[i], numVertices];
		
		result.vertices[i] = vertices[vertexIndices[i]];
				
		if (internallyLit) result.lighting.light[i] = lightValues[vertexIndices[i]];
		else result.lighting.normals[i] = normals[vertexIndices[i]];
	}
	
	return result;
}

- (BOOL)usesInternalLighting;
{
	return internallyLit;
}

- (unsigned)texturedTriangleCount;
{
	return numTexturedTriangles;
}
- (TRMeshFace *)texturedTriangles;
{
	return texturedTriangles;
}

- (unsigned)texturedRectangleCount;
{
	return numTexturedRectangles;
}
- (TRMeshFace *)texturedRectangles;
{
	return texturedRectangles;
}

- (unsigned)coloredTriangleCount;
{
	return numColoredTriangles;
}
- (TRMeshFace *)coloredTriangles;
{
	return coloredTriangles;
}

- (unsigned)coloredRectangleCount;
{
	return numColoredRectangles;
}
- (TRMeshFace *)coloredRectangles;
{
	return coloredRectangles;
}


@end
