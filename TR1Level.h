//
//  TR1Level.h
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
#import "MTypes.h"

@class TR1Mesh;
@class TR1AnimatedObject;
@class TR1Room;
@class TRLevelData;
@class TRAnimation;

enum
{
	TRNoTRFileErrorCode = 1,
	TRNoSpecificTRFileErrorCode,
	TRTooMuchTextureErrorCode,
	TRIndexOutOfBoundsErrorCode,
	TRPrematureEndOfFileErrorCode,
	TRWrongUncompressedSizeErrorCode,
	TRGenericDecompressionErrorCode,
	TRCouldNotLoadTextureErrorCode,
	TRRoomLoadingUnspecificError = 0x100,
	TRMeshLoadingUnspecificError = 0x200,
	TRMoveableLoadingUnspecificError = 0x300 // just to have some distance so I can insert subcodes there. Hex because I think it's cool. No bit-setting!
};

typedef struct
{
	unsigned objectID;
	TR1Mesh *mesh;
	MVec3 visibilityBoundingBox[2];
	MVec3 collisionBoundingBox[2];
	BOOL colliding;
} TRStaticMesh;

typedef struct
{
	unsigned coords[4][2];
	enum
	{
		TRTextureNoTransparency = 0, // No color is transparent
		TRTextureAlphaTest = 1, // One color is transparent
		TRTextureAlphaAdd = 2 // Additive color mixing (TRosetta Stone and the TR4 notes describe this as either "alpha=max(r,g,b)" or "alpha=intensity". Assuming it is additive gives good results, too, and is much cheaper, so I'm pretty certain that this is what the TR developers used.
	} transparency;
	unsigned texturePageNumber;
} TRTexture;

typedef struct
{
	unsigned coords[4][2];
	int distanceToEdge[4]; // 0 left 1 top 2 right 3 bottom
	unsigned texturePageNumber;
} TRSpriteTexture;

typedef struct
{
	unsigned objectID;
	unsigned firstSpriteTexture;
	unsigned numberOfSprites;
} TRSpriteSequence;

typedef struct
{
	unsigned minFrameIndex;
	unsigned maxFrameIndex;
	TRAnimation *animation;
	unsigned nextFrameIndex;
} TRAnimDispatch;

typedef struct
{
	unsigned stateID;
	unsigned numDispatches;
	TRAnimDispatch *dispatches;
} TRStateChange;

typedef struct
{
	bool isObject;
	union
	{
		TR1AnimatedObject *object;
		TRSpriteSequence *spriteSequence;
	} item;
	TR1Room *room;
	MVec3 position;
	float angle;
	float lightValue;
	float lightValue2;
	bool invisible;
} TRItem;

@interface TR1Level : NSObject
{
	unsigned numTexturePages;
	uint8_t *texture;
	uint8_t *palette;
	
	NSArray *rooms;
	NSArray *meshes;
	NSArray *moveables;
	
	unsigned numStaticMeshes;
	TRStaticMesh *staticMeshes;
	
	unsigned numTextures;
	TRTexture *textures;
	
	unsigned numSprites;
	TRSpriteTexture *sprites;
	
	unsigned numSpriteSequences;
	TRSpriteSequence *spriteSequences;
	
	unsigned numItems;
	TRItem *items;
}

+ (Class)subclassForLevelData:(TRLevelData *)levelData;
+ (id)levelWithData:(NSData *)data error:(NSError **)outError;

+ (Class)roomClass;
+ (Class)meshClass;
+ (Class)animatedObjectClass;
+ (unsigned)fontSpriteSequenceID;

+ (float)convertRawLightValue:(float)value;

- (unsigned)meshTextureBasePage;

- (id)initWithLevelData:(TRLevelData *)levelData error:(NSError **)outError;

- (unsigned)itemCount;
- (TRItem *)items;
- (unsigned)texturePageCount;
- (void *)texturePageAtIndex:(unsigned)pageNumber;
- (TR1AnimatedObject *)moveableWithObjectID:(unsigned)objectID;
- (NSArray *)rooms;
- (NSArray *)meshes;
- (NSArray *)moveables;

#pragma mark Methods used to read a level
- (BOOL)readMeshes:(TRLevelData *)levelData outError:(NSError **)outError;
- (BOOL)readRooms:(TRLevelData *)levelData outError:(NSError **)outError;
- (BOOL)readMoveables:(TRLevelData *)levelData outError:(NSError **)outError;
- (void)readPalette8:(TRLevelData *)levelData;
- (void)readTexture8Tiles:(unsigned)tileCount from:(TRLevelData *)levelData;
- (TRStaticMesh)readStaticMesh:(TRLevelData *)levelData;
- (TRTexture)readObjectTexture:(TRLevelData *)levelData;
- (TRSpriteTexture)readSprite:(TRLevelData *)levelData;
- (TRSpriteSequence)readSpriteSequence:(TRLevelData *)levelData;
- (TRAnimDispatch)readAnimDispatch:(TRLevelData *)levelData;
- (TRStateChange)readStateChange:(TRLevelData *)stateChange;
- (TRItem)readItem:(TRLevelData *)item;

#pragma mark Internal methods to bring a level in a canonical form
- (void)convertTexture8To32;
- (void)finalizeLoading;

#pragma mark Methods accessed by loaded objects to finalize loading
- (TRTexture *)textureAtIndex:(unsigned)index;
- (TRStaticMesh *)staticMeshWithObjectID:(unsigned)index;
- (TRSpriteTexture *)spriteTextureAtIndex:(unsigned)index;
- (TRSpriteSequence *)spriteSequenceWithObjectID:(unsigned)index;
- (void)getColor:(float [4])color forPaletteIndex:(unsigned)unalteredIndex;

@end
