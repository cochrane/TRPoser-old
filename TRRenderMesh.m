//
//  TRRenderMesh.m
//  TRViewer
//
//  Created by Torsten Kammer on 06.06.06.
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

#import "TRRenderMesh.h"
#import "TR1Mesh.h"
#import "TR1Level.h"
#import <OpenGL/gl.h>

@interface TRRenderMesh (Private)

- (void)_generateTexturedList:(unsigned *)listPointer alphaFaces:(BOOL)skipFlag;

@end

@implementation TRRenderMesh (Private)

- (void)_generateTexturedList:(unsigned *)listPointer alphaFaces:(BOOL)skipFlag;
{	
	unsigned quadCount = [mesh texturedRectangleCount];
	TRMeshFace *quads = [mesh texturedRectangles];
	
	unsigned triCount = [mesh texturedTriangleCount];
	TRMeshFace *tris = [mesh texturedTriangles];
	
	unsigned i, j, k;
	
	unsigned texturePageCount = [[mesh level] texturePageCount];
	
	*listPointer = glGenLists(1);
	glNewList(*listPointer, GL_COMPILE);
	glColor3f(1.0f, 1.0f, 1.0f);
	
	unsigned drawnPolygonCount = 0;
	
	for (i = 0; i < texturePageCount; i++)
	{
		BOOL textured = NO;
		BOOL glBegun = NO;
		
		for (j = 0; j < triCount; j++)
		{
			if (tris[j].hasAlpha != skipFlag) continue;
			if (tris[j].surface.texture.texturePageNumber != i) continue;
			
			if (!textured) glBindTexture(GL_TEXTURE_2D, [level textureIDForPage:i]);
			textured = YES;
			if (!glBegun) glBegin(GL_TRIANGLES);
			glBegun = YES;
			
			for (k = 0; k < 3; k++)
			{	
				if (internalLighting)
					glColor3f(tris[j].lighting.light[k], tris[j].lighting.light[k], tris[j].lighting.light[k]);
				else
					glNormal3fv(&tris[j].lighting.normals[k].x);
				
				float texCoords[2];
				texCoords[0] = (float) tris[j].surface.texture.pixelTexCoords[k][0] / 256.0f;
				texCoords[1] = (float) tris[j].surface.texture.pixelTexCoords[k][1] / 256.0f;
				glTexCoord2fv(texCoords);
				glVertex3fv(&tris[j].vertices[k].x);
			}
			drawnPolygonCount++;
		}
		if (glBegun) glEnd();
		
		glBegun = NO;
		
		for (j = 0; j < quadCount; j++)
		{
			if (quads[j].hasAlpha != skipFlag) continue;
			if (quads[j].surface.texture.texturePageNumber != i) continue;
		
			if (!textured) glBindTexture(GL_TEXTURE_2D, [level textureIDForPage:i]);
			textured = YES;
			if (!glBegun) glBegin(GL_QUADS);
			glBegun = YES;
			
			for (k = 0; k < 4; k++)
			{	
				if (internalLighting)
					glColor3f(quads[j].lighting.light[k], quads[j].lighting.light[k], quads[j].lighting.light[k]);
				else
					glNormal3fv(&quads[j].lighting.normals[k].x);
				
				float texCoords[2];
				texCoords[0] = (float) quads[j].surface.texture.pixelTexCoords[k][0] / 256.0f;
				texCoords[1] = (float) quads[j].surface.texture.pixelTexCoords[k][1] / 256.0f;
				glTexCoord2fv(texCoords);
				glVertex3fv(&quads[j].vertices[k].x);
			}
			drawnPolygonCount++;
		}
		if (glBegun) glEnd();
	}
		
	glEndList();
}

@end

@implementation TRRenderMesh

- (id)initWithMesh:(TR1Mesh *)aMesh renderLevel:(TRRenderLevel *)aLevel;
{
	if (![super init])
	{
		[self release];
		return nil;
	}
	
	mesh = aMesh;
	level = aLevel;
	
	hasAlpha = NO;
	hasColored = NO;
	hasTextured = NO;
	
	alphaList = 0;
	coloredList = 0;
	texturedList = 0;
	
	if (([mesh coloredTriangleCount] + [mesh coloredRectangleCount]) > 0) hasColored = YES;
	
	unsigned faceCount = [mesh texturedTriangleCount];
	TRMeshFace *faces = [mesh texturedTriangles];
	unsigned i;
	for (i = 0; i < faceCount; i++)
	{
		if (faces[i].hasAlpha) hasAlpha = YES;
		else hasTextured = YES;
		if (hasAlpha && hasTextured) break;
	}
	
	faceCount = [mesh texturedRectangleCount];
	faces = [mesh texturedRectangles];
	for (i = 0; i < faceCount; i++)
	{
		if (faces[i].hasAlpha) hasAlpha = YES;
		else hasTextured = YES;
		if (hasAlpha && hasTextured) break;
	}
	
	internalLighting = [mesh usesInternalLighting];
	
	return self;
}

- (void)dealloc
{
	if (texturedList) glDeleteLists(texturedList, 1);
	if (coloredList) glDeleteLists(coloredList, 1);
	if (alphaList) glDeleteLists(alphaList, 1);
	[super dealloc];
}

- (TR1Mesh *)mesh;
{
	return mesh;
}
- (TRRenderLevel *)renderLevel;
{
	return level;
}

- (BOOL)hasTexturedParts;
{
	return hasTextured;
}
- (BOOL)hasColoredParts;
{
	return hasColored;
}
- (BOOL)hasAlphaParts;
{
	return hasAlpha;
}

- (unsigned)texturedDisplayList;
{
	if (!texturedList && hasTextured) [self generateTexturedDisplayList];
	return texturedList;
}
- (unsigned)coloredDisplayList;
{
	if (!coloredList && hasColored) [self generateColoredDisplayList];
	return coloredList;
}
- (unsigned)alphaDisplayList;
{
	if (!alphaList && hasAlpha) [self generateAlphaDisplayList];
	return alphaList;
}

- (void)renderTexturedParts;
{
	if (!texturedList && hasTextured) [self generateTexturedDisplayList];
	glCallList(texturedList);
}
- (void)renderColoredParts;
{
	if (!coloredList && hasColored) [self generateColoredDisplayList];
	glCallList(coloredList);
}
- (void)renderAlphaParts;
{
	if (!alphaList && hasAlpha) [self generateAlphaDisplayList];
	glCallList(alphaList);
}

- (void)generateTexturedDisplayList;
{
	if (texturedList || !hasTextured) return;
	[self _generateTexturedList:&texturedList alphaFaces:NO];
}
- (void)generateAlphaDisplayList;
{
	if (alphaList || !hasAlpha) return;
	[self _generateTexturedList:&alphaList alphaFaces:YES];
}

- (void)generateColoredDisplayList;
{
	if (coloredList || !hasColored) return;
	
	BOOL glBegun = NO;
	
	unsigned faceCount = [mesh coloredTriangleCount];
	TRMeshFace *faces = [mesh coloredTriangles];
	unsigned i, j;
	
	coloredList = glGenLists(1);
	
	glNewList(coloredList, GL_COMPILE);
	
	for (i = 0; i < faceCount; i++)
	{
		if (!glBegun) glBegin(GL_TRIANGLES);
		glBegun = YES;
		for (j = 0; j < 3; j++)
		{
			float color[4];
			memcpy(color, faces[i].surface.color, sizeof (float [4]));
			if (internalLighting)
			{
				color[0] *= faces[i].lighting.light[j];
				color[1] *= faces[i].lighting.light[j];
				color[2] *= faces[i].lighting.light[j];
			}
			else
				glNormal3fv(&faces[i].lighting.normals[j].x);
			
			glColor4fv(color);
			
			glVertex3fv(&faces[i].vertices[j].x);
		}
	}
	if (glBegun) glEnd();
	glBegun = NO;
	
	faceCount = [mesh coloredRectangleCount];
	faces = [mesh coloredRectangles];
	for (i = 0; i < faceCount; i++)
	{
		if (!glBegun) glBegin(GL_QUADS);
		glBegun = YES;
		for (j = 0; j < 4; j++)
		{
			float color[4];
			memcpy(color, faces[i].surface.color, sizeof (float [4]));
			if (internalLighting)
			{
				color[0] *= faces[i].lighting.light[j];
				color[1] *= faces[i].lighting.light[j];
				color[2] *= faces[i].lighting.light[j];
			}
			else
				glNormal3fv(&faces[i].lighting.normals[j].x);
			
			glColor4fv(color);
			
			glVertex3fv(&faces[i].vertices[j].x);
		}
	}
	if (glBegun) glEnd();
	
	glEndList();
}

- (void)getMidpoint:(MVec3 *)midpoint;
{
	[mesh getMidpoint:midpoint];
}

- (NSString *)stringValue
{
	return [self description];
}

#pragma mark Methods that forward unsupported messages to the mesh
// This way, a TRRenderMesh can be used like the mesh it wraps. Can be useful at times, especially because I'm so lazy
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:mesh];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	NSMethodSignature *result = [super methodSignatureForSelector:aSelector];
	if (!result) result = [mesh methodSignatureForSelector:aSelector];	return result;
}

@end
