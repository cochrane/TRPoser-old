//
//  TR2Level.m
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

#import "TR2Level.h"
#import "TR2Room.h"
#import "TR2AnimatedObject.h"
#import "SimpleErrorCreation.h"
#import "TRLevelData.h"

#import <Accelerate/Accelerate.h>

@implementation TR2Level

+ (Class)roomClass;
{
	return [TR2Room class];
}
+ (Class)animatedObjectClass;
{
	return [TR2AnimatedObject class];
}

+ (unsigned)fontSpriteSequenceID;
{
	// This is the objectID of the sprite sequence that contains all letters
	return 255;
}

- (id)initWithLevelData:(TRLevelData *)levelData error:(NSError **)outError;
{
	if (![super init])
	{
		[self release];
		return nil;
	}
	
	#define fail(ecode, description, suggestion, localizableKey) \
	do \
	{ \
		if (outError) *outError = [NSError errorWithDomain:@"TR Level loading domain" code:(ecode) userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(description, [@"Error: " stringByAppendingString:(localizableKey)]), NSLocalizedDescriptionKey, NSLocalizedString(suggestion, [@"Suggestion: " stringByAppendingString:(localizableKey)]), NSLocalizedRecoverySuggestionErrorKey, nil]]; \
		[self release]; \
		return nil; \
	} \
	while (0)

	unsigned i;

	unsigned version = [levelData readUint32];
	if (version != 0x0000002d) fail(TRNoSpecificTRFileErrorCode, @"The level is not a Tomb Raider 2 level", @"You ought not see this error. it only comes up when the level changed while I was reading this. If you do see this error, RUN!", @"Not TR2");

	[self readPalette8:levelData];
	[levelData skipBytes:1024]; // 16 Bit palette. You'll notice that I ignore this and only use the 8 bit one, even though that might give me worse results. The reason is that I don't really give a damn about palettes. TR1 needs it for anything, but TR2 and TR3 only need it for colored faces, which are few and far between. So I guess writing just a single palette reading routine is easier
	
	numTexturePages = [levelData readUint32];
	[levelData skipBytes:65536 * numTexturePages]; // 8 Bit texture
	[self readTexture16Tiles:numTexturePages from:levelData];

	[levelData skipBytes:4]; // Unused
	
	BOOL success = [self readRooms:levelData outError:outError];
	if (!success)
	{
		[self release];
		return nil;
	}
	
	[levelData skipField32:2]; // floor data
	
	success = [self readMeshes:levelData outError:outError];
	if (!success)
	{
		if (outError && !*outError) *outError = [NSError trErrorWithCode:TRMeshLoadingUnspecificError description:@"The file's meshes could not be loaded" moreInfo:@"The 3D object in the level could not be read. Try opening a different level file" localizationSuffix:@"All meshes not loaded error"];
		[self release];
		return nil;
	}

	success = [self readMoveables:levelData outError:outError];
	if (!success)
	{
		[self release];
		return nil;
	}

	numStaticMeshes = [levelData readUint32];
	staticMeshes = calloc(numStaticMeshes, sizeof(TRStaticMesh));
	for (i = 0; i < numStaticMeshes; i++)
		staticMeshes[i] = [self readStaticMesh:levelData];
	
	numTextures = [levelData readUint32];
	textures = calloc(numTextures, sizeof(TRTexture));
	for (i = 0; i < numTextures; i++)
		textures[i] = [self readObjectTexture:levelData];

	numSprites = [levelData readUint32];
	sprites = calloc(numSprites, sizeof(TRSpriteTexture));
	for (i = 0; i < numSprites; i++)
		sprites[i] = [self readSprite:levelData];

	numSpriteSequences = [levelData readUint32];
	spriteSequences = calloc(numSpriteSequences, sizeof(TRSpriteTexture));
	for (i = 0; i < numSpriteSequences; i++)
		spriteSequences[i] = [self readSpriteSequence:levelData];

	[levelData skipField32:16]; // Cameras
	[levelData skipField32:16]; // Sound sources
	
	unsigned numBoxes = [levelData readUint32];
	[levelData skipBytes:numBoxes * 8]; // Boxes
	[levelData skipField32:2]; // Overlaps
	[levelData skipBytes:numBoxes * 20]; // Zones
	
	[levelData skipField32:2]; // Animated Textures
	
	numItems = [levelData readUint32];
	items = calloc(numItems, sizeof(TRItem));
	for (i = 0; i < numItems; i++)
		items[i] = [self readItem:levelData];

	// We ignore the rest of the level file
	
	[self convertTexture16To32];
	
	@try
	{
		[self finalizeLoading];
	}
	@catch (NSException *exception)
	{
		DebugLog(@"TR2Level caught exception %@", exception);
		// The only kind of exception we could see is something is out of bounds, so…
		fail(TRIndexOutOfBoundsErrorCode, @"An interal index is out of bounds", @"A part of the file points to wrong other parts of the file. The level is likely corrupt", @"Generic index out of bounds");
	}

	return self;
}

- (TRItem)readItem:(TRLevelData *)levelData
{
	TRItem result;
	uint16_t objectID = [levelData readUint16];
	result.item.spriteSequence = [self spriteSequenceWithObjectID:objectID];
	if (result.item.spriteSequence) result.isObject = NO;
	else
	{
		NSEnumerator *moveablesEnumerator = [moveables objectEnumerator];
		TR1AnimatedObject *object;
		while (object = [moveablesEnumerator nextObject])
		{
			if ([object objectID] == objectID) break;
		}
		result.item.object = object;
		result.isObject = YES;
	}
	
	uint16_t roomNumber = [levelData readUint16];
	result.room = [rooms objectAtIndex:roomNumber];
	
	int32_t position[3];
	[levelData readUint32Array:(uint32_t *) position count:3];
	result.position.x = position[0] / 1024.0f;
	result.position.y = position[1] / 1024.0f;
	result.position.z = position[2] / 1024.0f;
	
	result.angle = ((float) [levelData readInt16]) / 16384.0f * 90.0f;
	float lightValue1 = (float) [levelData readInt16];
	result.lightValue = [[self class] convertRawLightValue:lightValue1];
	
	float lightValue2 = (float) [levelData readInt16];
	result.lightValue2 = [[self class] convertRawLightValue:lightValue2];
	uint16_t flags = [levelData readUint16];
	result.invisible = flags & 0x0100;
	
	return result;
}

- (void)readTexture16Tiles:(unsigned)tileCount from:(TRLevelData *)levelData;
{
	texture = malloc(2 * 256 * 256 * tileCount);
	[levelData readUint16Array:(void *) texture count:256*256 * tileCount];
}

- (void)convertTexture16To32;
{
	vImage_Buffer argb1555Buffer, argb8888Buffer;
	
	argb1555Buffer.data = texture;
	argb1555Buffer.height = 256 * numTexturePages;
	argb1555Buffer.width = 256;
	argb1555Buffer.rowBytes = 256*2;
	
	uint8_t *texture32 = calloc(256 * 256 * numTexturePages, sizeof(uint8_t [4]));
	argb8888Buffer.data = texture32;
	argb8888Buffer.height = 256 * numTexturePages;
	argb8888Buffer.width = 256;
	argb8888Buffer.rowBytes = 256*4;
	
	vImage_Error result = vImageConvert_ARGB1555toARGB8888(&argb1555Buffer, &argb8888Buffer, kvImageNoFlags);
	if (result != kvImageNoError) NSLog(@"Could not convert image format");
	
	free(texture);
	texture = texture32;
}

@end
