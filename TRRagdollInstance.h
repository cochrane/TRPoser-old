//
//  TRRagdollInstance.h
//  TRViewer
//
//  Created by Torsten on 13.06.06.
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
#import "TRRenderLevel.h"
#import "TR1AnimatedObject.h"
#import "MTypes.h"

@class TRRenderMesh;
@class TRRagdollInstance;
@class TRPoserDocument;

@interface TRRagdollMeshInstance : NSObject <TRRendering>
{	
	MVec3 rotation;
	MVec3 location;
	
	TRRenderMesh *renderMesh;
	TRRenderLevel *renderLevel;
	
	BOOL hasAlpha, hasColored, hasTextured;
	
	BOOL pushParent, popParent;
	
	TRRagdollInstance *ragdoll;
	
	NSMutableArray *children;
}

- (id)initWithMeshTreeNode:(TRMeshTreeNode)meshTreeNode renderLevel:(TRRenderLevel *)level ragdoll:(TRRagdollInstance *)parent;

- (NSMutableArray *)children;

- (void)setRotationX:(float)angle;
- (float)rotationX;
- (void)setRotationY:(float)angle;
- (float)rotationY;
- (void)setRotationZ:(float)angle;
- (float)rotationZ;

- (void)setLocationX:(float)position;
- (float)locationX;
- (void)setLocationY:(float)position;
- (float)locationY;
- (void)setLocationZ:(float)position;
- (float)locationZ;

- (void)renderEverythingWithScale:(float)scaling;

// Hit testing (not yet implemented)
- (TRRagdollMeshInstance *)firstObjectOnLineFrom:(MVec3)start to:(MVec3)end;

@end

@interface TRRagdollInstance : NSObject <TRRendering>
{
	TRRenderLevel *renderLevel;
	NSArray *meshes;
	TR1AnimatedObject *object;
	NSView *displayView;
	TRPoserDocument *document;
	
	TRRenderRoom *room; // Notice that room is used only for bookkeeping. It can be from a different level.
	
	BOOL hasAlpha, hasColored, hasTextured;
}

- (id)initWithAnimatedObject:(TR1AnimatedObject *)object renderLevel:(TRRenderLevel *)level;
- (id)initWithAnimatedObject:(TR1AnimatedObject *)object renderLevel:(TRRenderLevel *)level room:(TRRenderRoom *)aRoom;

- (void)setDocument:(TRPoserDocument *)manager;
- (TRPoserDocument *)document;

- (int)objectID;

- (TR1AnimatedObject *)moveable;

- (TRRagdollMeshInstance *)rootMesh;

- (NSArray *)meshes;

- (void)renderEverythingInRoomWithScale:(float)scale;

// Hit testing (not yet implemented)

- (TRRagdollMeshInstance *)firstObjectOnLineFrom:(MVec3)start to:(MVec3)end;

- (void)setView:(NSView *)view;
- (NSView *)view;

- (TRRenderRoom *)room;

@end
