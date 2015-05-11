//
//  TR3Level.m
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

#import "TR3Level.h"
#import "TR3Room.h"
#import "SimpleErrorCreation.h"
#import "TRLevelData.h"

@implementation TR3Level

+ (Class)roomClass;
{
	return [TR3Room class];
}

+ (float)convertRawLightValue:(float)value;
{
	//return 1.0f - ((float) value + 1.0f) / 8192.0f;
	return value / 32767.0f; // only possible due to the code of vt
}

+ (unsigned)fontSpriteSequenceID;
{
	// This is the objectID of the sprite sequence that contains all letters
	return 356;
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
	if ((version != 0xFF080038) && (version != 0xFF180038)) fail(TRNoSpecificTRFileErrorCode, @"The level is not a Tomb Raider 2 level", @"You ought not see this error. it only comes up when the level changed while I was reading this. If you do see this error, RUN!", @"Not TR2");


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
	
	numSprites = [levelData readUint32];
	sprites = calloc(numSprites, sizeof(TRSpriteTexture));
	for (i = 0; i < numSprites; i++)
		sprites[i] = [self readSprite:levelData];
		
	numSpriteSequences = [levelData readUint32];
	spriteSequences = calloc(numSpriteSequences, sizeof(TRSpriteTexture));
	for (i = 0; i < numSpriteSequences; i++)
		spriteSequences[i] = [self readSpriteSequence:levelData];
		
	[levelData skipField32:16]; // Cameras
	[levelData skipField32:16]; // Sound Sources
	unsigned numBoxes = [levelData readUint32];
	[levelData skipBytes:numBoxes * 8]; // Boxes
	[levelData skipField32:2]; // Overlaps
	[levelData skipBytes:numBoxes * 20]; // Zones
	[levelData skipField32:2]; // Animated textures
	
	numTextures = [levelData readUint32];
	textures = calloc(numTextures, sizeof(TRTexture));
	for (i = 0; i < numTextures; i++)
		textures[i] = [self readObjectTexture:levelData];

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

@end
