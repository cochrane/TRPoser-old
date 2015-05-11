//
//  TRAnimatedObject.h
//  TRViewer
//
//  Created by Torsten on 11.06.06.
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
#import "TR1Level.h"

@class TR1Mesh;

typedef struct __TRMeshTreeNode TRMeshTreeNode;
struct __TRMeshTreeNode
{
	TR1Mesh *mesh;
	MVec3 offset;
	BOOL pushParent;
	BOOL popParent;
};

typedef struct __TRAnimationFrame TRAnimationFrame;
struct __TRAnimationFrame
{
	MVec3 boundingBox[2];
	MVec3 offset;
	MVec3 *rotations;
};

typedef struct __TRAnimation TRAnimation;
struct __TRAnimation
{
	TRAnimationFrame *firstFrame;
	TRAnimationFrame *lastFrame;
	
	float frameRate;
	uint16_t frames;
	
	unsigned stateID;
	
	TRAnimation *nextAnimation;
	TRAnimationFrame *nextFrame;
	
	unsigned numStateChanges;
	TRStateChange *stateChanges;
};

@interface TR1AnimatedObject : NSObject
{
	unsigned objectID;
	TRMeshTreeNode *meshTreeNodes;
	
	NSArray *meshes;
	
	unsigned numFrames;
	TRAnimationFrame *frames;
	
	unsigned meshTreeOffset;
	unsigned frameOffset;
	unsigned animationOffset;
	
	TR1Level *level;
}

- (id)initWithLevel:(TR1Level *)aLevel levelData:(TRLevelData *)levelData error:(NSError **)outError;

- (TR1Level *)level;

- (unsigned)objectID;

- (TRMeshTreeNode *)meshTreeNodes;
- (unsigned)meshCount;

- (TRAnimationFrame *)frames;

// Notice that for animated objects, the data isn't in convenient packages as it is for rooms or meshes. Therefore, the following methods will be called by a TRLevel

- (void)readMeshTreeFrom:(TRLevelData *)levelData;
- (void)readFramesFrom:(TRLevelData *)levelData;
- (void)readAnimationsFrom:(TRLevelData *)levelData;

// These methods get invoked by the animated object
- (TRAnimationFrame)readFrameFrom:(TRLevelData *)levelData;

@end
