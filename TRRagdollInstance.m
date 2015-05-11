//
//  TRRagdollInstance.m
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

#import "TRRagdollInstance.h"
#import "TR1Mesh.h"
#import "TRRenderMesh.h"
#import "TRPoserDocument.h"
#import "MFunctions.h"
#import "TR1Room.h"
#import <OpenGL/gl.h>

/*! @category TRRagdollMeshInstance (TRRagdollMeshCommunication)
 *	@abstract Methods of TRRagdollMeshInstance that get called by the parent TRRagdollMesh
 */

@interface TRRagdollMeshInstance (TRRagdollMeshCommunication)

- (BOOL)_pushParent;
- (BOOL)_popParent;

@end

@implementation TRRagdollMeshInstance

- (id)initWithMeshTreeNode:(TRMeshTreeNode)meshTreeNode renderLevel:(TRRenderLevel *)level ragdoll:(TRRagdollInstance *)parent;
{
	if (![super init])
	{
		[self release];
		return nil;
	}
	
	ragdoll = parent;
	renderLevel = level;
	renderMesh = [renderLevel renderMeshForMesh:meshTreeNode.mesh];
	
	pushParent = meshTreeNode.pushParent;
	popParent = meshTreeNode.popParent;
	
	hasAlpha = [renderMesh hasAlphaParts];
	hasColored = [renderMesh hasColoredParts];
	hasTextured = [renderMesh hasTexturedParts];
	
	location = meshTreeNode.offset;
	rotation = MMakeVec3(0.0f, 0.0f, 0.0f);
	
	children = [[NSMutableArray alloc] init];
	
	return self;
}

- (void)dealloc
{
	[children release];
	[super dealloc];
}

- (void)setRotationX:(float)angle;
{
	TRPoserDocument *document = [ragdoll document];
	if (document)
	{
		if ([document shouldMesh:self registerForUndoWithSelector:_cmd])
		{
			[[[document undoManager] prepareWithInvocationTarget:self] setRotationX:rotation.x];
			[[document undoManager] setActionName:NSLocalizedString(@"Rotation around X", @"undo")];
		}
	}
	[self willChangeValueForKey:@"rotationX"];
	rotation.x = angle;
	[self didChangeValueForKey:@"rotationX"];
	NSView *view = [ragdoll view];
	if (view) [view setNeedsDisplay:YES];
}
- (float)rotationX;
{
	return rotation.x;
}
- (void)setRotationY:(float)angle;
{
	TRPoserDocument *document = [ragdoll document];
	if (document)
	{
		if ([document shouldMesh:self registerForUndoWithSelector:_cmd])
		{
			[[[document undoManager] prepareWithInvocationTarget:self] setRotationY:rotation.y];
			[[document undoManager] setActionName:NSLocalizedString(@"Rotation around Y", @"undo")];
		}
	}
	[self willChangeValueForKey:@"rotationY"];
	rotation.y = angle;
	[self didChangeValueForKey:@"rotationY"];
	NSView *view = [ragdoll view];
	if (view) [view setNeedsDisplay:YES];
}
- (float)rotationY;
{
	return rotation.y;
}
- (void)setRotationZ:(float)angle;
{
	TRPoserDocument *document = [ragdoll document];
	if (document)
	{
		if ([document shouldMesh:self registerForUndoWithSelector:_cmd])
		{
			[[[document undoManager] prepareWithInvocationTarget:self] setRotationZ:rotation.z];
			[[document undoManager] setActionName:NSLocalizedString(@"Rotation around Z", @"undo")];
		}
	}
	[self willChangeValueForKey:@"rotationZ"];
	rotation.z = angle;
	[self didChangeValueForKey:@"rotationZ"];
	NSView *view = [ragdoll view];
	if (view) [view setNeedsDisplay:YES];
}
- (float)rotationZ;
{
	return rotation.z;
}

- (void)setLocationX:(float)position;
{
	TRPoserDocument *document = [ragdoll document];
	if (document)
	{
		if ([document shouldMesh:self registerForUndoWithSelector:_cmd])
		{
			[[[document undoManager] prepareWithInvocationTarget:self] setLocationX:location.x];
			[[document undoManager] setActionName:NSLocalizedString(@"Move along X", @"undo")];
		}
	}
	[self willChangeValueForKey:@"locationX"];
	location.x = position;
	[self didChangeValueForKey:@"locationX"];
	NSView *view = [ragdoll view];
	if (view) [view setNeedsDisplay:YES];
}
- (float)locationX;
{
	return location.x;
}
- (void)setLocationY:(float)position;
{
	TRPoserDocument *document = [ragdoll document];
	if (document)
	{
		if ([document shouldMesh:self registerForUndoWithSelector:_cmd])
		{
			[[[document undoManager] prepareWithInvocationTarget:self] setLocationY:location.y];
			[[document undoManager] setActionName:NSLocalizedString(@"Move along Y", @"undo")];
		}
	}
	[self willChangeValueForKey:@"locationY"];
	location.y = position;
	[self didChangeValueForKey:@"locationY"];
	NSView *view = [ragdoll view];
	if (view) [view setNeedsDisplay:YES];
}
- (float)locationY;
{
	return location.y;
}
- (void)setLocationZ:(float)position;
{
	TRPoserDocument *document = [ragdoll document];
	if (document)
	{
		if ([document shouldMesh:self registerForUndoWithSelector:_cmd])
		{
			[[[document undoManager] prepareWithInvocationTarget:self] setLocationZ:location.z];
			[[document undoManager] setActionName:NSLocalizedString(@"Move along Z", @"undo")];
		}
	}
	[self willChangeValueForKey:@"locationZ"];
	location.z = position;
	[self didChangeValueForKey:@"locationZ"];
	NSView *view = [ragdoll view];
	if (view) [view setNeedsDisplay:YES];
}
- (float)locationZ;
{
	return location.z;
}

- (TRRagdollMeshInstance *)firstObjectOnLineFrom:(MVec3)start to:(MVec3)end;
{
	return nil;
}

#pragma mark From TRRendering Protocol

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

- (void)generateAlphaDisplayList;
{
	if (!hasAlpha) return;
	[renderMesh generateAlphaDisplayList];
}
- (void)generateColoredDisplayList;
{
	if (!hasColored) return;
	[renderMesh generateColoredDisplayList];
}
- (void)generateTexturedDisplayList;
{
	if (!hasTextured) return;
	[renderMesh generateTexturedDisplayList];
}

- (unsigned)texturedDisplayList;
{
	return [renderMesh texturedDisplayList]; // Meaningless for this
}
- (unsigned)coloredDisplayList;
{
	return [renderMesh coloredDisplayList]; // Meaningless for this
}
- (unsigned)alphaDisplayList;
{
	return [renderMesh alphaDisplayList]; // Meaningless for this
}

- (void)renderTexturedParts;
{	
	glPushMatrix();
	
	glTranslatef(location.x, location.y, location.z);
	glRotatef(rotation.y, 0.0f, 1.0f, 0.0f);
	glRotatef(rotation.x, 1.0f, 0.0f, 0.0f);
	glRotatef(rotation.z, 0.0f, 0.0f, 1.0f);
	[renderMesh renderTexturedParts];
	
	[children makeObjectsPerformSelector:_cmd];
	
	glPopMatrix();
}
- (void)renderColoredParts;
{
	glPushMatrix();
	
	glTranslatef(location.x, location.y, location.z);
	glRotatef(rotation.y, 0.0f, 1.0f, 0.0f);
	glRotatef(rotation.x, 1.0f, 0.0f, 0.0f);
	glRotatef(rotation.z, 0.0f, 0.0f, 1.0f);
	[renderMesh renderColoredParts];
	
	[children makeObjectsPerformSelector:_cmd];
	
	glPopMatrix();
}
- (void)renderAlphaParts;
{
	glPushMatrix();
	
	glTranslatef(location.x, location.y, location.z);
	glRotatef(rotation.y, 0.0f, 1.0f, 0.0f);
	glRotatef(rotation.x, 1.0f, 0.0f, 0.0f);
	glRotatef(rotation.z, 0.0f, 0.0f, 1.0f);
	[renderMesh renderAlphaParts];
	
	[children makeObjectsPerformSelector:_cmd];
	
	glPopMatrix();
}

- (void)renderEverythingWithScale:(float)scaling;
{
	glPushMatrix();
	
	glTranslatef(location.x, location.y, location.z);
	glRotatef(rotation.y, 0.0f, 1.0f, 0.0f);
	glRotatef(rotation.x, 1.0f, 0.0f, 0.0f);
	glRotatef(rotation.z, 0.0f, 0.0f, 1.0f);
	glPushMatrix();
	glScalef(scaling, scaling, scaling);
	[renderMesh renderColoredParts];
	[renderMesh renderTexturedParts];
	[renderMesh renderAlphaParts];
	
	glPopMatrix();
	
	unsigned i, count = [children count];
	for (i = 0; i < count; i++)
		[[children objectAtIndex:i] renderEverythingWithScale:scaling];
	
	glPopMatrix();
}

- (TRRenderLevel *)renderLevel;
{
	return renderLevel;
}

- (void)getMidpoint:(MVec3 *)midpoint;
{
	[renderMesh getMidpoint:midpoint];
}

- (NSMutableArray *)children;
{
	return children;
}

#pragma mark Convenience functions
// Because I always confuse location/position

- (id)valueForUndefinedKey:(NSString *)key
{
	if ([key isEqual:@"positionX"]) return [self valueForKey:@"locationX"];
	else if ([key isEqual:@"positionY"]) return [self valueForKey:@"locationY"];
	else if ([key isEqual:@"positionZ"]) return [self valueForKey:@"locationZ"];
	else return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	if ([key isEqual:@"positionX"]) [self setValue:value forKey:@"locationX"];
	else if ([key isEqual:@"positionY"]) [self setValue:value forKey:@"locationY"];
	else if ([key isEqual:@"positionZ"]) [self setValue:value forKey:@"locationZ"];
	else [super setValue:value forUndefinedKey:key];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"M: %@", [[renderMesh mesh] numberInLevel]];
}

@end

@implementation TRRagdollMeshInstance (TRRagdollMeshCommunication)

- (BOOL)_pushParent;
{
	return pushParent;
}
- (BOOL)_popParent;
{
	return popParent;
}

@end

@implementation TRRagdollInstance

- (id)initWithAnimatedObject:(TR1AnimatedObject *)anObject renderLevel:(TRRenderLevel *)level;
{
	if (![super init])
	{
		[self release];
		return nil;
	}
	
	object = anObject;
	renderLevel = level;
	
	hasAlpha = NO;
	hasTextured = NO;
	hasColored = NO;
	
	room = nil;
	
	NSMutableArray *meshStack = [[NSMutableArray alloc] initWithCapacity:3];
	
	unsigned i;
	unsigned meshCount = [anObject meshCount];
	NSMutableArray *mutableMeshes = [[NSMutableArray alloc] initWithCapacity:meshCount];
	TRMeshTreeNode *nodes = [anObject meshTreeNodes];
	
	displayView = nil;
	
	static unsigned maxTreeDepth = 3;
	
	for (i = 0; i < meshCount; i++)
	{
		TRRagdollMeshInstance *mesh = [[TRRagdollMeshInstance alloc] initWithMeshTreeNode:nodes[i] renderLevel:renderLevel ragdoll:self];
		[mutableMeshes addObject:mesh];
		if ([mesh hasAlphaParts]) hasAlpha = YES;
		if ([mesh hasTexturedParts]) hasTextured = YES;
		if ([mesh hasColoredParts]) hasColored = YES;
		
		if (i > 0)
		{
			TRRagdollMeshInstance *parent = [mutableMeshes objectAtIndex:i - 1];
			
			if ([mesh _popParent] && [meshStack count])
			{
				parent = [meshStack lastObject];
				[meshStack removeLastObject];
			}
			
			[[parent children] addObject:mesh];
			
			if ([mesh _pushParent])
			{
				[meshStack addObject:parent];
			}
			
			if ([meshStack count] > maxTreeDepth)
			{
				maxTreeDepth = [meshStack count];
			}
		}
		
		[mesh release];
	}
	meshes = [mutableMeshes copy];
	[mutableMeshes release];
	
	[meshStack release];
	
	return self;
}

- (id)initWithAnimatedObject:(TR1AnimatedObject *)anObject renderLevel:(TRRenderLevel *)level room:(TRRenderRoom *)aRoom;
{
	[self initWithAnimatedObject:anObject renderLevel:level];
	room = aRoom;
	
	TRAnimationFrame *frames = [anObject frames];
	
	// Set offset
	TRRagdollMeshInstance *rootMesh = [meshes objectAtIndex:0];
	[rootMesh setLocationX:frames[0].offset.x];
	[rootMesh setLocationX:frames[0].offset.y];
	[rootMesh setLocationX:frames[0].offset.z];
	
	unsigned i;
	for (i = 0; i < [meshes count]; i++)
	{
		TRRagdollMeshInstance *mesh = [meshes objectAtIndex:i];
		[mesh setRotationX:frames[0].rotations[i].x];
		[mesh setRotationY:frames[0].rotations[i].y];
		[mesh setRotationZ:frames[0].rotations[i].z];
	}

	return self;
}

- (TRRenderRoom *)room;
{
	return room;
}

- (void)dealloc
{
	[meshes release];
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (displayView) [displayView setNeedsDisplay:YES];
}

- (int)objectID
{
	return (int) [object objectID];
}

- (void)setView:(NSView *)view;
{
	displayView = view;
}
- (NSView *)view;
{
	return displayView;
}

- (TRRagdollMeshInstance *)firstObjectOnLineFrom:(MVec3)start to:(MVec3)end;
{
	return nil;
}

#pragma mark From TRRendering Protocol

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

- (void)generateAlphaDisplayList;
{
	[meshes makeObjectsPerformSelector:_cmd];
}
- (void)generateColoredDisplayList;
{
	[meshes makeObjectsPerformSelector:_cmd];
}
- (void)generateTexturedDisplayList;
{
	[meshes makeObjectsPerformSelector:_cmd];
}

- (unsigned)texturedDisplayList;
{
	return 0; // Meaningless for this
}
- (unsigned)coloredDisplayList;
{
	return 0; // Meaningless for this
}
- (unsigned)alphaDisplayList;
{
	return 0; // Meaningless for this
}

- (void)renderTexturedParts;
{
	[[meshes objectAtIndex:0] renderTexturedParts];
}
- (void)renderColoredParts;
{
	[[meshes objectAtIndex:0] renderColoredParts];
}
- (void)renderAlphaParts;
{
	[[meshes objectAtIndex:0] renderAlphaParts];
}

- (void)renderEverythingInRoomWithScale:(float)scale;
{
	NSPoint roomPoint = [[room room] roomPosition];
	glPushMatrix();
	glTranslatef(roomPoint.x, 0.0f, roomPoint.y);
	[[meshes objectAtIndex:0] renderEverythingWithScale:scale];
	glPopMatrix();
}

- (TRRenderLevel *)renderLevel;
{
	return renderLevel;
}

- (void)getMidpoint:(MVec3 *)midpoint;
{
	[[meshes objectAtIndex:0] getMidpoint:midpoint]; // Certainly not the best possible implementation, but ought to work well enough
}

- (TRRagdollMeshInstance *)rootMesh;
{
	return [meshes objectAtIndex:0];
}

- (TR1AnimatedObject *)moveable;
{
	return object;
}

- (NSArray *)meshes
{
	return meshes;
}

- (void)setDocument:(TRPoserDocument *)aDocument;
{
	document = aDocument;
}
- (TRPoserDocument *)document;
{
	return document;
}

#pragma mark Methods that forward unsupported messages to the object.
// This way, a TRRenderRoom can be used like the room it wraps. Can be useful at times
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	[anInvocation invokeWithTarget:object];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	NSMethodSignature *result = [super methodSignatureForSelector:aSelector];
	if (!result) result = [object methodSignatureForSelector:aSelector];
	return result;
}

@end
