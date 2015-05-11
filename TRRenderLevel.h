//
//  TRRenderLevel.h
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

#import <Cocoa/Cocoa.h>
#import "MTypes.h"

@class TRRenderMesh;
@class TRRenderRoom;
@class TRRenderLevel;
@class TRRagdollInstance;

@class TR1Level;
@class TR1Room;
@class TR1Mesh;
@class TRLoadedLevel;
@class TR1AnimatedObject;

@protocol TRRendering

- (BOOL)hasTexturedParts;
- (BOOL)hasColoredParts;
- (BOOL)hasAlphaParts;

- (void)generateAlphaDisplayList;
- (void)generateColoredDisplayList;
- (void)generateTexturedDisplayList;

- (unsigned)texturedDisplayList;
- (unsigned)coloredDisplayList;
- (unsigned)alphaDisplayList;

- (void)renderTexturedParts;
- (void)renderColoredParts;
- (void)renderAlphaParts;

- (TRRenderLevel *)renderLevel;

- (void)getMidpoint:(MVec3 *)midpoint;

@end

@interface TRRenderLevel : NSObject
{
	TR1Level *level;
	NSDictionary *meshes;
	NSDictionary *rooms;
	NSDictionary *previewRagdolls;
	
	unsigned firstLetterSprite;
	
	NSDictionary *texturePages;
	NSArray *automaticallyPlacedRagdolls;
	
	BOOL canWrite;
	BOOL automaticallyCreate;
}

- (id)initWithLevel:(TR1Level *)level automaticallyPlaceItems:(BOOL)create;

- (TR1Level *)originalLevel;

- (NSArray *)rooms;
- (NSArray *)meshes;
- (NSArray *)previewRagdolls;

- (NSArray *)automaticallyPlacedRagdolls;

- (TRRenderMesh *)renderMeshForMesh:(TR1Mesh *)mesh;
- (TRRenderRoom *)renderRoomForRoom:(TR1Room *)room;

- (unsigned)textureIDForPage:(unsigned)pageNumber;

- (void)writeText:(NSString *)text;

- (TRRagdollInstance *)createNewRagdoll:(TR1AnimatedObject *)baseObject inRoom:(TRRenderRoom *)room;

@end
