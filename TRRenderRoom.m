//
//  TRRenderRoom.m
//  TRViewer
//
//  Created by Torsten on 06.06.06.
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

#import "TRRenderRoom.h"
#import "TRRenderMesh.h"
#import "TR1Room.h"
#import "TRRoomViewing.h"
#import "MFunctions.h"

#import <OpenGL/gl.h>

@interface TRRenderRoom (Private)

- (void)_drawRoomFacesWithAlpha:(BOOL)skipFlag;

@end

@implementation TRRenderRoom (Private)

- (void)_drawRoomFacesWithAlpha:(BOOL)skipFlag;
{
	unsigned i, j, k;
	
	unsigned staticMeshCount = [room staticMeshCount];
	TRStaticMeshInstance *staticMeshes = [room staticMeshes];
	for (i = 0; i < staticMeshCount; i++)
	{
		TRRenderMesh *renderMesh = [level renderMeshForMesh:staticMeshes[i].object->mesh];
		if (skipFlag && ![renderMesh hasAlphaParts]) continue;
		else if (!skipFlag && ![renderMesh hasTexturedParts]) continue;
		glPushMatrix();
		glTranslatef(staticMeshes[i].position.x - roomPoint.x, staticMeshes[i].position.y, staticMeshes[i].position.z - roomPoint.y);
		glRotatef(staticMeshes[i].rotation, 0.0f, 1.0f, 0.0f);
		if (skipFlag) [renderMesh renderAlphaParts];
		else [renderMesh renderTexturedParts];
		glPopMatrix();
	}
	
	float roomColor[3];
	[room getRoomColor:roomColor];
	
	unsigned textureCount = [[room level] texturePageCount];
	
	unsigned triCount = [room triangleCount];
	TRRoomFace *tris = [room triangles];
	
	unsigned quadCount = [room rectangleCount];
	TRRoomFace *quads = [room rectangles];
	
	for (i = 0; i < textureCount; i++)
	{
		BOOL textured = NO;
		BOOL glBegun = NO; // glBegin will only be called 
	
		for (j = 0; j < triCount; j++)
		{
			if (tris[j].hasAlpha != skipFlag) continue;
			if (tris[j].texturePage != i) continue;
			if (!textured) glBindTexture(GL_TEXTURE_2D, [level textureIDForPage:i]);
			textured = YES;
			if (!glBegun) glBegin(GL_TRIANGLES);
			glBegun = YES;
			
			for (k = 0; k < 3; k++)
			{
				glColor4fv(tris[j].colors[k]);
				float texCoords[2];
				texCoords[0] = (float) tris[j].pixelTexCoords[k][0] / 256.0f;
				texCoords[1] = (float) tris[j].pixelTexCoords[k][1] / 256.0f;
				glTexCoord2fv(texCoords);
				glVertex3fv(&tris[j].vertices[k].x);
			}
			
			if (tris[j].twoSided)
			{
				for (k = 2; k <= 2; k--)
				{
					glColor4fv(tris[j].colors[k]);
					float texCoords[2];
					texCoords[0] = (float) tris[j].pixelTexCoords[k][0] / 256.0f;
					texCoords[1] = (float) tris[j].pixelTexCoords[k][1] / 256.0f;
					glTexCoord2fv(texCoords);
					glVertex3fv(&tris[j].vertices[k].x);
				}
			}
		}
		if (glBegun) glEnd();
		glBegun = NO;

		for (j = 0; j < quadCount; j++)
		{
			if (quads[j].hasAlpha != skipFlag) continue;
			if (quads[j].texturePage != i) continue;
			if (!textured) glBindTexture(GL_TEXTURE_2D, [level textureIDForPage:i]);
			textured = YES;
			if (!glBegun) glBegin(GL_QUADS);
			glBegun = YES;
			
			for (k = 0; k < 4; k++)
			{
				glColor4fv(quads[j].colors[k]);
				float texCoords[2];
				texCoords[0] = (float) quads[j].pixelTexCoords[k][0] / 256.0f;
				texCoords[1] = (float) quads[j].pixelTexCoords[k][1] / 256.0f;
				glTexCoord2fv(texCoords);
				glVertex3fv(&quads[j].vertices[k].x);
			}
			
			if (quads[j].twoSided)
			{
				for (k = 3; k <= 3; k--)
				{
					glColor4fv(quads[j].colors[k]);
					float texCoords[2];
					texCoords[0] = (float) quads[j].pixelTexCoords[k][0] / 256.0f;
					texCoords[1] = (float) quads[j].pixelTexCoords[k][1] / 256.0f;
					glTexCoord2fv(texCoords);
					glVertex3fv(&quads[j].vertices[k].x);
				}
			}
		}
		if (glBegun) glEnd();
	}
}

@end

@implementation TRRenderRoom

- (id)initWithRoom:(TR1Room *)aRoom renderLevel:(TRRenderLevel *)aLevel;
{
	if (![super init])
	{
		[self release];
		return nil;
	}
	
	room = aRoom;
	level = aLevel;
	
	hasAlpha = NO;
	hasColored = NO;
	hasTextured = NO;
	
	alphaList = 0;
	coloredList = 0;
	texturedList = 0;
	
	numPortals = [room portalCount];
	portals = [room portals];
	
	unsigned i;
	unsigned faceCount = [room triangleCount];
	TRRoomFace *faces = [room triangles];
	for (i = 0; i < faceCount; i++)
	{
		if (faces[i].hasAlpha) hasAlpha = YES;
		else hasTextured = YES;
		if (hasAlpha && hasTextured) break;
	}
	
	faceCount = [room rectangleCount];
	faces = [room rectangles];
	for (i = 0; i < faceCount; i++)
	{
		if (faces[i].hasAlpha) hasAlpha = YES;
		else hasTextured = YES;
		if (hasAlpha && hasTextured) break;
	}
	
	roomPoint = [room roomPosition];
	
	unsigned staticMeshCount = [room staticMeshCount];
	TRStaticMeshInstance *staticMeshes = [room staticMeshes];
	for (i = 0; i < staticMeshCount; i++)
	{
		TRRenderMesh *renderMesh = [level renderMeshForMesh:staticMeshes[i].object->mesh];
		if ([renderMesh hasAlphaParts]) hasAlpha = YES;
		if ([renderMesh hasTexturedParts]) hasTextured = YES;
		if ([renderMesh hasColoredParts]) hasColored = YES;
		
		if (hasAlpha && hasTextured && hasColored) break;
	}
	
	ragdolls = [[NSMutableArray alloc] init];
	
	return self;
}

- (void)dealloc
{
	if (texturedList) glDeleteLists(texturedList, 1);
	if (coloredList) glDeleteLists(coloredList, 1);
	if (alphaList) glDeleteLists(alphaList, 1);
	if (portalList) glDeleteLists(portalList, 1);
	[ragdolls release];
	[super dealloc];
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
- (unsigned)portalsDisplayList;
{
	if (!portalList) [self generatePortalDisplayList];
	return portalList;
}

- (void)renderTexturedParts;
{
	if (!texturedList && hasTextured) [self generateTexturedDisplayList];
	glCallList(texturedList);
	[ragdolls makeObjectsPerformSelector:_cmd];
}
- (void)renderColoredParts;
{
	if (!coloredList && hasColored) [self generateColoredDisplayList];
	glCallList(coloredList);
	[ragdolls makeObjectsPerformSelector:_cmd];
}
- (void)renderAlphaParts;
{
	if (!alphaList && hasAlpha) [self generateAlphaDisplayList];
	glCallList(alphaList);
	[ragdolls makeObjectsPerformSelector:_cmd];
}
- (void)renderPortals;
{
	if (!portalList) [self generatePortalDisplayList];
	glCallList(portalList);
}

- (TR1Room *)room;
{
	return room;
}

- (void)generateAlphaDisplayList;
{
	if (!hasAlpha || alphaList) return;
	
	unsigned i;
	
	unsigned staticMeshCount = [room staticMeshCount];
	TRStaticMeshInstance *staticMeshes = [room staticMeshes];
	for (i = 0; i < staticMeshCount; i++)
	{
		TRRenderMesh *renderMesh = [level renderMeshForMesh:staticMeshes[i].object->mesh];
		if ([renderMesh hasAlphaParts]) [renderMesh generateAlphaDisplayList];
	}
	
	alphaList = glGenLists(1);
	
	glNewList(alphaList, GL_COMPILE);
	
	[self _drawRoomFacesWithAlpha:YES];
	
	glEndList();
	
	[ragdolls makeObjectsPerformSelector:_cmd];
}

- (void)generateColoredDisplayList;
{
	if (!hasColored || coloredList) return;
	unsigned i;
	
	unsigned staticMeshCount = [room staticMeshCount];
	TRStaticMeshInstance *staticMeshes = [room staticMeshes];
	for (i = 0; i < staticMeshCount; i++)
	{
		TRRenderMesh *renderMesh = [level renderMeshForMesh:staticMeshes[i].object->mesh];
		if ([renderMesh hasColoredParts]) [renderMesh generateColoredDisplayList];
	}
	
	coloredList = glGenLists(1);
	
	glNewList(coloredList, GL_COMPILE);
	for (i = 0; i < staticMeshCount; i++)
	{
		TRRenderMesh *renderMesh = [level renderMeshForMesh:staticMeshes[i].object->mesh];
		if (![renderMesh hasTexturedParts]) continue;
		glPushMatrix();
		glTranslatef(staticMeshes[i].position.x - roomPoint.x, staticMeshes[i].position.y, staticMeshes[i].position.x - roomPoint.y);
		glRotatef(staticMeshes[i].rotation, 0.0f, 1.0f, 0.0f);
		[renderMesh renderColoredParts];
		glPopMatrix();
	}
	glEndList();
	
	[ragdolls makeObjectsPerformSelector:_cmd];
}

- (void)generateTexturedDisplayList;
{
	if (!hasTextured || texturedList) return;
	
	unsigned i;
	
	unsigned staticMeshCount = [room staticMeshCount];
	TRStaticMeshInstance *staticMeshes = [room staticMeshes];
	for (i = 0; i < staticMeshCount; i++)
	{
		TRRenderMesh *renderMesh = [level renderMeshForMesh:staticMeshes[i].object->mesh];
		if ([renderMesh hasTexturedParts]) [renderMesh generateTexturedDisplayList];
	}
	
	texturedList = glGenLists(1);
	
	glNewList(texturedList, GL_COMPILE);
	
	[self _drawRoomFacesWithAlpha:NO];
	
	glEndList();
	
	[ragdolls makeObjectsPerformSelector:_cmd];
}

- (void)generatePortalDisplayList;
{
	if (portalList) return;
	
	portalList = glGenLists(1);
	
	glNewList(portalList, GL_COMPILE);
	
	unsigned i;
	
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	glBegin(GL_LINES);
	for (i = 0; i < numPortals; i++)
	{
		MVec3 portalMidpoint = MVecInterpolate(portals[i].vertices, 4);
		MVec3 portalNormalTarget = MVecAdd(portalMidpoint, portals[i].normal);
		
		glVertex3fv(&portals[i].vertices[0].x);
		glVertex3fv(&portals[i].vertices[1].x);
		
		glVertex3fv(&portals[i].vertices[0].x);
		glVertex3fv(&portals[i].vertices[2].x);
		
		glVertex3fv(&portals[i].vertices[0].x);
		glVertex3fv(&portals[i].vertices[3].x);
		
		glVertex3fv(&portals[i].vertices[1].x);
		glVertex3fv(&portals[i].vertices[2].x);
		
		glVertex3fv(&portals[i].vertices[1].x);
		glVertex3fv(&portals[i].vertices[3].x);
		
		glVertex3fv(&portals[i].vertices[2].x);
		glVertex3fv(&portals[i].vertices[3].x);
		
		glVertex3fv(&portalMidpoint.x);
		glVertex3fv(&portalNormalTarget.x);
	}
	glEnd();
	
	glEndList();
}

- (void)getMidpoint:(MVec3 *)midpoint;
{
	[room getMidpoint:midpoint];
}


- (NSString *)stringValue
{
	return [self description];
}

- (TRRenderLevel *)renderLevel
{
	return level;
}

- (void)resetVisible;
{
	visible = NO;
}
- (void)makeVisible;
{
	visible = YES;
}
- (BOOL)isVisible;
{
	return visible;
}

- (void)recursiveFindVisibleRoomsWithinFrustum:(MPlane *)frustumPlanes cameraPoint:(MVec3)camPoint comingFrom:(TRRenderRoom *)previous;
{
	unsigned i;
	
	if (visible) return;
	visible = YES;
	
	for (i = 0; i < numPortals; i++)
	{	
		unsigned j;
		MVec3 globalPortalVertices[4];
		for (j = 0; j < 4; j++) globalPortalVertices[j] = MVecAdd(portals[i].vertices[j], MMakeVec3(roomPoint.x, 0.0f, roomPoint.y));

		MPlane portalPlane = MPlaneFromDirectionAndPoint(portals[i].normal, globalPortalVertices[0]);
		if (MPlaneVecMultiply(portalPlane, camPoint) < 0.0f) continue;
		
		BOOL skipPortal = NO;
		for (j = 0; j < 4; j++)
		{
			unsigned k;
			for (k = 0; k < 2; k++)
			{
				float aDot = MPlaneVecMultiply(frustumPlanes[j], globalPortalVertices[(k + 0) % 4]);
				float bDot = MPlaneVecMultiply(frustumPlanes[j], globalPortalVertices[(k + 1) % 4]);
				
				float cDot = MPlaneVecMultiply(frustumPlanes[j], globalPortalVertices[(k + 2) % 4]);
				float dDot = MPlaneVecMultiply(frustumPlanes[j], globalPortalVertices[(k + 3) % 4]);
				
				// First: Check for all out
				if (aDot < 0.f && cDot < 0.f && bDot < 0.f && dDot < 0.f) skipPortal = YES;
			}
		}
		
		if (skipPortal) continue;

		TRRenderRoom *otherRoom = [level renderRoomForRoom:portals[i].otherRoom];
		[otherRoom recursiveFindVisibleRoomsWithinFrustum:frustumPlanes cameraPoint:camPoint comingFrom:self];
	}
}

- (void)renderTexturedInLevel;
{
	if (!visible) return;
	glPushMatrix();
	glTranslatef(roomPoint.x, 0.0f, roomPoint.y);
	[self renderTexturedParts];
	glPopMatrix();
}
- (void)renderAlphaInLevel;
{
	if (!visible) return;
	glPushMatrix();
	glTranslatef(roomPoint.x, 0.0f, roomPoint.y);
	[self renderAlphaParts];
	glPopMatrix();
}
- (void)renderPortalsInLevel;
{
	if (!visible) return;
	glPushMatrix();
	glTranslatef(roomPoint.x, 0.0f, roomPoint.y);
	[self renderPortals];
	glPopMatrix();
}

- (void)renderColoredInLevel;
{
	if (!visible) return;
	glPushMatrix();
	glTranslatef(roomPoint.x, 0.0f, roomPoint.y);
	[self renderColoredParts];
	glPopMatrix();
}

- (NSMutableArray *)ragdolls;
{
	return ragdolls;
}

#pragma mark Methods that forward unsupported messages to the room.
// This way, a TRRenderRoom can be used like the room it wraps. Can be useful at times
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:room];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	NSMethodSignature *result = [super methodSignatureForSelector:aSelector];
	if (!result) result = [room methodSignatureForSelector:aSelector];	return result;
}

@end
