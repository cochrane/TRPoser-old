//
//  TR5Level.m
//  TRViewer
//
//  Created by Torsten on 08.07.06.
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

#import "TR5Level.h"
#import "TR5Room.h"
#import "TR5AnimatedObject.h"
#import "TRLevelData.h"
#import "SimpleErrorCreation.h"

#warning TR5 is not supported, and attempting to load it will fail!

@implementation TR5Level

+ (Class)roomClass;
{
	return [TR5Room class];
}

+ (Class)animatedObjectClass;
{
	return [TR5AnimatedObject class];
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

	char header[4];
	[levelData readUint8Array:(uint8_t *)header count:4];
	
	if (strcmp(header, "TR4") != 0) fail(TRNoSpecificTRFileErrorCode, @"The level is not a Tomb Raider 4 or 5 level", @"You ought not see this error. it only comes up when the level changed while I was reading this. If you do see this error, RUN!", @"Not TR5");
	
	BOOL success = [self readCompressedTextureFrom:levelData error:outError];
	if (!success)
	{
		[self release];
		return nil;
	}
	
	[levelData skipBytes:32]; // Practically unknown (vt has info, but that is not relevant to this app yet)
	[levelData readUint32]; // Level Data Size 1
	[levelData readUint32]; // Level Data Size 2
	unsigned seperator = [levelData readUint32];
	if (seperator != 0) fail(TRIndexOutOfBoundsErrorCode, @"The seperator is wrong", @"The level is corrupt.", @"seperator wrong");
	
	success = [self readRooms:levelData outError:outError];
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
	
	unsigned i;

	numStaticMeshes = [levelData readUint32];
	staticMeshes = calloc(numStaticMeshes, sizeof(TRStaticMesh));
	for (i = 0; i < numStaticMeshes; i++)
		staticMeshes[i] = [self readStaticMesh:levelData];
	
	
	uint8_t spriteExpected[3] = {'S', 'P', 'R'};
	uint8_t spriteActual[3];
	[levelData readUint8Array:spriteActual count:3];
	if (memcmp(spriteExpected, spriteActual, 3) != 0) fail(TRNoSpecificTRFileErrorCode, @"The level is not a Tomb Raider 4 level", @"You ought not see this error. it only comes up when the level changed while I was reading this. If you do see this error, RUN!", @"Not TR4");
	
	uint8_t temp = [levelData readUint8];
	NSLog(@"for alignment, there ought to be a char here: %u = '%c'", temp, temp);
	
	numSprites = [levelData readUint32];
	sprites = calloc(numSprites, sizeof(TRSpriteTexture));
	for (i = 0; i < numSprites; i++)
		sprites[i] = [self readSprite:levelData];

	numSpriteSequences = [levelData readUint32];
	spriteSequences = calloc(numSpriteSequences, sizeof(TRSpriteTexture));
	for (i = 0; i < numSpriteSequences; i++)
		spriteSequences[i] = [self readSpriteSequence:levelData];
		
	[levelData skipField32:16]; // Cameras
	[levelData skipField32:40]; // Flyby cameras
	[levelData skipField32:16]; // Sound Sources
	unsigned numBoxes = [levelData readUint32];
	[levelData skipBytes:numBoxes * 8]; // Boxes
	[levelData skipField32:2]; // Overlaps
	[levelData skipBytes:numBoxes * 20]; // Zones
	[levelData skipField32:2]; // Animated textures
	
	[levelData skipBytes:1];
	uint8_t zeroTex[3] = {'T', 'E', 'X'};
	uint8_t texIndex[3];
	[levelData readUint8Array:texIndex count:3];
	if (memcmp(zeroTex, texIndex, 3) != 0) fail(TRNoSpecificTRFileErrorCode, @"The level is not a Tomb Raider 4 level", @"You ought not see this error. it only comes up when the level changed while I was reading this. If you do see this error, RUN!", @"Not TR4");
	
	numTextures = [levelData readUint32];
	textures = calloc(numTextures, sizeof(TRTexture));
	for (i = 0; i < numTextures; i++)
		textures[i] = [self readObjectTexture:levelData];

	// We ignore the rest of the level file
	
	@try
	{
		[self finalizeLoading];
	}
	@catch (NSException *exception)
	{
		DebugLog(@"TR4Level caught exception %@", exception);
		// The only kind of exception we could see is something is out of bounds, so…
		fail(TRIndexOutOfBoundsErrorCode, @"An interal index is out of bounds", @"A part of the file points to wrong other parts of the file. The level is likely corrupt", @"Generic index out of bounds");
	}
	#undef fail

	return self;
}

- (BOOL)readRooms:(TRLevelData *)levelData outError:(NSError **)outError;
{
	Class roomClass = [[self class] roomClass];
	unsigned numRooms = (unsigned) [levelData readUint32];
	NSMutableArray *mutableRooms = [[NSMutableArray alloc] initWithCapacity:numRooms];
	unsigned i;
	for (i = 0; i < numRooms; i++)
	{
		TR1Room *room = [[roomClass alloc] initWithLevelData:levelData error:outError];
		if (!room)
		{
			if (outError && !*outError)  *outError = [NSError trErrorWithCode:TRRoomLoadingUnspecificError description:@"A room could not be loaded" moreInfo:@"A room from the file could not be loaded. The file is possibly corrupt." localizationSuffix:@"Generic room not loaded error"];
			
			[mutableRooms release];
			return NO;
		}
		[mutableRooms addObject:room];
		[room release];
	}
	rooms = [mutableRooms copy];
	[mutableRooms release];
	return YES;
}


@end
