//
//  TRRenderLevel.m
//  TRViewer
//
//  Created by Torsten on 07.06.06.
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

#import "TRRenderLevel.h"
#import "TRRenderRoom.h"
#import "TRRenderMesh.h"
#import "TR1Level.h"
#import "TR1Room.h"
#import "TR1Mesh.h"
#import "TRRagdollInstance.h"

#import "MFunctions.h"

#import <OpenGL/gl.h>

unsigned TRSpriteIndexForCharacter(int character)
{	
	if ((character >= 'A') && (character <= 'Z'))
		return character - 'A';
	else if ((character >= 'a') && (character <= 'z'))
		return 26 + character - 'a';
	else if ((character >= '0') && (character <= '9'))
		return 52 + character - '0';
	else
	{
		switch (character)
		{
			case '.':
				return 62;
			break;
			case ',':
				return 63;
			break;
			case '!':
				return 64;
			break;
			case '?':
				return 65;
			break;
			case '"':
//				case '“':
//					return 66;
//				break;
//				case '”':
//					return 67;
//				break;
			case '/':
				return 68;
			break;
			case '-':
				return 71;
			break;
			case '=':
				return 72;
			break;
			case ':':
				return 73;
			break;
//				case 'ß':
//					return 74;
//				break;
			case '+':
				return 75;
			break;
//				case '©':
//					return 76;
//				break;
			case '&':
				return 78;
			break;
			case '\'':
				return 78;
			break;
			default:
				return 65; // Question mark
			break;
		}
	}
}

@interface TRRenderLevel (Private)

- (void)_generateRoomList;
- (void)_generateMeshList;
- (void)_generateOpenGLTexture;
- (void)_generateRagdollList;
- (void)_placeRoomItems;

@end

@implementation TRRenderLevel (Private)

- (void)_placeRoomItems
{
	if (!automaticallyCreate) return;
	
	unsigned numItems = [level itemCount];
	TRItem *item = [level items];
	NSMutableArray *automaticallPlacedMutable = [[NSMutableArray alloc] initWithCapacity:numItems];
	unsigned i;
	for (i = 0; i < numItems; i++)
	{
		if (!item[i].isObject) continue;
		
		TRRenderRoom *renderRoom = [self renderRoomForRoom:item[i].room];
		TRRagdollInstance *object = [self createNewRagdoll:item[i].item.object inRoom:renderRoom];
		NSPoint roomPoint = [item[i].room roomPosition];
		TRRagdollMeshInstance *root = [object rootMesh];
		TRAnimationFrame *frames = [item[i].item.object frames];
		
		MVec3 offset = MVecMatrixTransform(frames[0].offset, MMatrixYaw(item[i].angle));
		
		[root setLocationX:offset.x + item[i].position.x - roomPoint.x];
		[root setLocationY:offset.y + item[i].position.y];
		[root setLocationZ:offset.z + item[i].position.z - roomPoint.y];
		[root setRotationY:[root rotationY] + item[i].angle];
		[(NSMutableArray *) [renderRoom ragdolls] addObject:object];
		[automaticallPlacedMutable addObject:object];
	}
	
	automaticallyPlacedRagdolls = [automaticallPlacedMutable copy];
	[automaticallPlacedMutable release];
}

- (void)_generateRoomList;
{
	if (rooms) return;
	if (!meshes) [self _generateMeshList];
	NSMutableDictionary *mutableRooms = [[NSMutableDictionary alloc] init];
	
	TR1Room *room;
	NSEnumerator *enumerator = [[level rooms] objectEnumerator];
	while (room = [enumerator nextObject])
	{
		NSValue *pointerValue = [NSValue valueWithPointer:room];
		TRRenderRoom *renderRoom = [[TRRenderRoom alloc] initWithRoom:room renderLevel:self];
		[mutableRooms setObject:renderRoom forKey:pointerValue];
		[renderRoom release];
	}
	
	rooms = [mutableRooms copy];
	[mutableRooms release];
	
	[self _placeRoomItems];
}
- (void)_generateRagdollList;
{
	if (previewRagdolls) return;
	if (!meshes) [self _generateMeshList];
	
	NSMutableDictionary *mutableRagdolls = [[NSMutableDictionary alloc] init];
	
	TR1AnimatedObject *moveable;
	NSEnumerator *enumerator = [[level moveables] objectEnumerator];
	while (moveable = [enumerator nextObject])
	{
		NSNumber *objectID = [NSNumber numberWithUnsignedInt:[moveable objectID]];
		TRRagdollInstance *ragdoll = [[TRRagdollInstance alloc] initWithAnimatedObject:moveable renderLevel:self];
		[mutableRagdolls setObject:ragdoll forKey:objectID];
	}
	
	previewRagdolls = [mutableRagdolls copy];
	[mutableRagdolls release];
}

- (void)_generateMeshList;
{
	if (meshes) return;
	NSMutableDictionary *mutableMeshes = [[NSMutableDictionary alloc] init];
	
	TR1Mesh *mesh;
	NSEnumerator *enumerator = [[level meshes] objectEnumerator];
	while (mesh = [enumerator nextObject])
	{
		NSValue *pointerValue = [NSValue valueWithPointer:mesh];
		TRRenderMesh *renderMesh = [[TRRenderMesh alloc] initWithMesh:mesh renderLevel:self];
		[mutableMeshes setObject:renderMesh forKey:pointerValue];
		[renderMesh release];
	}
	
	meshes = [mutableMeshes copy];
	[mutableMeshes release];
}

- (void)_generateOpenGLTexture;
{
	if (texturePages) return;
	
	unsigned texturePageCount = [level texturePageCount];
	unsigned i;
	NSMutableDictionary *mutablePages = [[NSMutableDictionary alloc] initWithCapacity:texturePageCount];
	for (i = 0; i < texturePageCount; i++)
	{
		GLuint texture;
		
		glGenTextures(1, &texture);
		
		glBindTexture(GL_TEXTURE_2D, texture);
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 256, 256, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8_REV, [level texturePageAtIndex:i]);	
		
		[mutablePages setObject:[NSNumber numberWithUnsignedInt:texture] forKey:[NSNumber numberWithUnsignedInt:i]];
	}
	
	texturePages = [mutablePages copy];
	[mutablePages release];
}

@end

@implementation TRRenderLevel

- (id)initWithLevel:(TR1Level *)aLevel automaticallyPlaceItems:(BOOL)create;
{
	if (![super init])
	{
		[self release];
		return nil;
	}
	
	level = aLevel;
	
	meshes = nil;
	rooms = nil;
	texturePages = nil;
	automaticallyPlacedRagdolls = nil;
	automaticallyCreate = create;
	
	canWrite = YES;
	TRSpriteSequence *letterSpriteSequence = [level spriteSequenceWithObjectID:[[level class] fontSpriteSequenceID]];
	if (letterSpriteSequence) firstLetterSprite = letterSpriteSequence->firstSpriteTexture;
	else canWrite = NO;
	
	return self;
}

- (TR1Level *)originalLevel;
{
	return level;
}

- (NSArray *)rooms;
{
	if (!meshes) [self _generateMeshList];
	if (!rooms) [self _generateRoomList];
	
	return [rooms allValues];
}
- (NSArray *)meshes;
{
	if (!meshes) [self _generateMeshList];
	return [meshes allValues];
}
- (NSArray *)previewRagdolls;
{
	if (!meshes) [self _generateMeshList];
	if (!previewRagdolls) [self _generateRagdollList];
	return [previewRagdolls allValues];
}
- (NSArray *)automaticallyPlacedRagdolls;
{
	if (!rooms || !automaticallyPlacedRagdolls) [self _generateRoomList];
	return automaticallyPlacedRagdolls;
}

- (TRRenderMesh *)renderMeshForMesh:(TR1Mesh *)mesh;
{
	if (!meshes) [self _generateMeshList];
	NSValue *pointerValue = [NSValue valueWithPointer:mesh];
	return [meshes objectForKey:pointerValue];
}
- (TRRenderRoom *)renderRoomForRoom:(TR1Room *)room;
{
	if (!meshes) [self _generateMeshList];
	if (!rooms) [self _generateRoomList];
	NSValue *pointerValue = [NSValue valueWithPointer:room];
	return [rooms objectForKey:pointerValue];
}

- (unsigned)textureIDForPage:(unsigned)pageNumber;
{
	if (!texturePages) [self _generateOpenGLTexture];
	return [[texturePages objectForKey:[NSNumber numberWithUnsignedInt:pageNumber]] unsignedIntValue];
}

- (void)writeText:(NSString *)text;
{
	if (!canWrite)
	{
		NSLog(text);
		return;
	}
	
	const char *cText = [text UTF8String];
	unsigned i;
	float widthSoFar = 0.0f;
	float depth = 0.0;
	
	glColor3f(1.0f, 1.0f, 1.0f);
	BOOL glBegun = NO;
	
	unsigned boundTexture = 1000;
	
	while(*cText != '\0')
	{
		if (*cText == ' ')
		{
			widthSoFar += 16.f;
			cText++;
			continue;
		}
		if (*cText == '\n')
		{
			widthSoFar = 0.0f;
			depth += 24.0f;
			cText++;
			continue;
		}
		
		unsigned glyphIndex = TRSpriteIndexForCharacter((int) *cText);
		TRSpriteTexture *glyph = [level spriteTextureAtIndex:firstLetterSprite + glyphIndex];
		
		if (glyph->texturePageNumber != boundTexture)
		{
			if (glBegun) glEnd();
			boundTexture = glyph->texturePageNumber;
			glBindTexture(GL_TEXTURE_2D, [self textureIDForPage:boundTexture]);
			glBegun = YES;
			glBegin(GL_QUADS);
		}
		
		float texCoords[4][2];
		for (i = 0; i < 4; i++)
		{
			texCoords[i][0] = (float) glyph->coords[i][0] / 256.0f;
			texCoords[i][1] = (float) glyph->coords[i][1] / 256.0f;
		}
		
		float left = (float) glyph->distanceToEdge[0];
		float top = (float) glyph->distanceToEdge[1];
		float right = (float) glyph->distanceToEdge[2];
		float bottom = (float) glyph->distanceToEdge[3];
		
		glTexCoord2fv(texCoords[0]);
		glVertex2f(widthSoFar + left, -1.f * top - depth);
		glTexCoord2fv(texCoords[1]);
		glVertex2f(widthSoFar + right, -1.f * top - depth);	
		glTexCoord2fv(texCoords[2]);
		glVertex2f(widthSoFar + right, -1.f * bottom - depth);
		glTexCoord2fv(texCoords[3]);
		glVertex2f(widthSoFar + left, -1.f * bottom - depth);
		
		widthSoFar += right - 2.0f; // Guessed figure. For some letters, this is too short, while for others, it is too long
		
		cText++;
	}
	
	glEnd();
}

- (TRRagdollInstance *)createNewRagdoll:(TR1AnimatedObject *)baseObject inRoom:(TRRenderRoom *)room;
{
	if (!meshes) [self _generateMeshList];
	
	TRRagdollInstance *ragdoll = [[TRRagdollInstance alloc] initWithAnimatedObject:baseObject renderLevel:self room:room];
	
	MVec3 midpoint;
	[room getMidpoint:&midpoint];	
	TRRagdollMeshInstance *rootMesh = [ragdoll rootMesh];
	[rootMesh setLocationX:midpoint.x];
	[rootMesh setLocationY:midpoint.y];
	[rootMesh setLocationZ:midpoint.z];
	
	[ragdoll autorelease];
	
	return ragdoll;
}

@end
