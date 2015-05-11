//
//  TR4Level.m
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

#import "TR4Level.h"
#import "TR4Room.h"
#import "TR4Mesh.h"
#import "TR4AnimatedObject.h"
#import "SimpleErrorCreation.h"
#import "TRLevelData.h"

@implementation TR4Level

+ (Class)roomClass;
{
	return [TR4Room class];
}

+ (Class)meshClass;
{
	return [TR4Mesh class];
}
+ (Class)animatedObjectClass;
{
	return [TR4AnimatedObject class];
}

//+ (float)convertRawLightValue:(float)value;
//{
//	//return 1.0f - ((float) value + 1.0f) / 8192.0f;
//	return 1.0f; // only possible due to the code of vt
//}

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
	
	if (strcmp(header, "TR4") != 0) fail(TRNoSpecificTRFileErrorCode, @"The level is not a Tomb Raider 4 level", @"You ought not see this error. it only comes up when the level changed while I was reading this. If you do see this error, RUN!", @"Not TR4");
	
	BOOL success = [self readCompressedTextureFrom:levelData error:outError];
	if (!success)
	{
		[self release];
		return nil;
	}
	
	unsigned uncompressedGeomSize = [levelData readUint32];
	unsigned compressedGeomSize = [levelData readUint32];
	//NSLog(@"geometry compressed is %u, geometry uncompressed is %u", compressedGeomSize, uncompressedGeomSize);
	TRLevelData *geomData = [levelData decompressLevelDataCompressedLength:compressedGeomSize uncompressedLength:uncompressedGeomSize];
	
	[geomData skipBytes:4];
	
	success = [self readRooms:geomData outError:outError];
	if (!success)
	{
		[self release];
		return nil;
	}
	
	[geomData skipField32:2]; // floor data
	
	success = [self readMeshes:geomData outError:outError];
	if (!success)
	{
		if (outError && !*outError) *outError = [NSError trErrorWithCode:TRMeshLoadingUnspecificError description:@"The file's meshes could not be loaded" moreInfo:@"The 3D object in the level could not be read. Try opening a different level file" localizationSuffix:@"All meshes not loaded error"];
		[self release];
		return nil;
	}
	
	success = [self readMoveables:geomData outError:outError];
	if (!success)
	{
		[self release];
		return nil;
	}

	unsigned i;

	numStaticMeshes = [geomData readUint32];
	staticMeshes = calloc(numStaticMeshes, sizeof(TRStaticMesh));
	for (i = 0; i < numStaticMeshes; i++)
		staticMeshes[i] = [self readStaticMesh:geomData];
	
	
	uint8_t spriteExpected[3] = {'S', 'P', 'R'};
	uint8_t spriteActual[3];
	[geomData readUint8Array:spriteActual count:3];
	if (memcmp(spriteExpected, spriteActual, 3) != 0) fail(TRNoSpecificTRFileErrorCode, @"The level is not a Tomb Raider 4 level", @"You ought not see this error. it only comes up when the level changed while I was reading this. If you do see this error, RUN!", @"Not TR4");
	
	numSprites = [geomData readUint32];
	sprites = calloc(numSprites, sizeof(TRSpriteTexture));
	for (i = 0; i < numSprites; i++)
		sprites[i] = [self readSprite:geomData];

	numSpriteSequences = [geomData readUint32];
	spriteSequences = calloc(numSpriteSequences, sizeof(TRSpriteTexture));
	for (i = 0; i < numSpriteSequences; i++)
		spriteSequences[i] = [self readSpriteSequence:geomData];
		
	[geomData skipField32:16]; // Cameras
	[geomData skipField32:40]; // Flyby cameras
	[geomData skipField32:16]; // Sound Sources
	unsigned numBoxes = [geomData readUint32];
	[geomData skipBytes:numBoxes * 8]; // Boxes
	[geomData skipField32:2]; // Overlaps
	[geomData skipBytes:numBoxes * 20]; // Zones
	[geomData skipField32:2]; // Animated textures
	
	[geomData skipBytes:1];
	uint8_t zeroTex[3] = {'T', 'E', 'X'};
	uint8_t texIndex[3];
	[geomData readUint8Array:texIndex count:3];
	if (memcmp(zeroTex, texIndex, 3) != 0) fail(TRNoSpecificTRFileErrorCode, @"The level is not a Tomb Raider 4 level", @"You ought not see this error. it only comes up when the level changed while I was reading this. If you do see this error, RUN!", @"Not TR4");
	
	numTextures = [geomData readUint32];
	textures = calloc(numTextures, sizeof(TRTexture));
	for (i = 0; i < numTextures; i++)
		textures[i] = [self readObjectTexture:geomData];

	numItems = [geomData readUint32];
	items = calloc(numItems, sizeof(TRItem));
	for (i = 0; i < numItems; i++)
		items[i] = [self readItem:geomData];

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

- (void)readTexture32Tiles:(unsigned)tileCount from:(TRLevelData *)levelData;
{
	texture = malloc(4 * 256 * 256 * tileCount);
	[levelData readUint32Array:(void *) texture count:256*256 * tileCount]; // -2 because tileCount is compressed seperately
}

- (void)readSpriteTexture32Length:(unsigned)bytes from:(TRLevelData *)levelData;
{
	unsigned numSpritePages = bytes / (256*256*4);
	texture = realloc(texture, 256*256*4 * (numSpritePages + numTexturePages));
	void *texturePointer = &texture[256*256*4*numTexturePages];
	numTexturePages += numSpritePages;
	[levelData readUint32Array:texturePointer count:256 * 256 * numSpritePages];
}

- (BOOL)readCompressedTextureFrom:(TRLevelData *)levelData error:(NSError **)outError;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	#define fail(ecode, description, suggestion, localizableKey) \
	do \
	{ \
		if (outError) *outError = [NSError errorWithDomain:@"TR Level loading domain" code:(ecode) userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(description, [@"Error: " stringByAppendingString:(localizableKey)]), NSLocalizedDescriptionKey, NSLocalizedString(suggestion, [@"Suggestion: " stringByAppendingString:(localizableKey)]), NSLocalizedRecoverySuggestionErrorKey, nil]]; \
		[*outError retain]; \
		[pool release]; \
		[*outError autorelease]; \
		return NO; \
	} \
	while (0)
	unsigned numRoomTiles = [levelData readUint16];
	unsigned numObjectTiles = [levelData readUint16];
	unsigned numBumpedRoomTiles = [levelData readUint16];
	numTexturePages = numRoomTiles + numObjectTiles + numBumpedRoomTiles; // +2 for misc texture
	
	meshTexturePageOffset = numRoomTiles;
	bumpTexturePageOffset = numRoomTiles + numObjectTiles;
	
	unsigned uncompressedTex1Length = [levelData readUint32];
	if (uncompressedTex1Length != (numTexturePages)*4*256*256) fail(TRWrongUncompressedSizeErrorCode, @"The level does not contain the right amount of texture data.", @"The level does not contain the right amount of texture data. It is likely that the level is corrupt.", @"Too much texture");
	
	//if (numTextiles > 16) fail(TRTooMuchTextureErrorCode, @"The level contains too much texture data", @"The original Tomb Raider engine cannot handle so much texture data. It is likely that the level is corrupt.", @"Too much texture");
	
	unsigned compressedTex1Length = [levelData readUint32];
	TRLevelData *texture32Data = nil;
	@try
	{
		texture32Data = [levelData decompressLevelDataCompressedLength:compressedTex1Length uncompressedLength:uncompressedTex1Length];
	}
	@catch (NSException *exception)
	{
		DebugLog(@"%@ caught exception: %@", self, exception);
		fail(TRGenericDecompressionErrorCode, @"The texture data could not be decompressed", @"The textures could not be decoded. The file is apparently broken", @"Could not decompress");
	}
	if (!texture32Data) fail(TRGenericDecompressionErrorCode, @"The texture data could not be decompressed", @"The textures could not be decoded. The file is apparently broken", @"Could not decompress");
	
	[self readTexture32Tiles:numTexturePages from:texture32Data];
	if (![texture32Data isAtEnd]) fail(TRCouldNotLoadTextureErrorCode, @"The texture data could not be loaded", @"The textures could not be loaded. The file is apparently broken", @"Could not decompress");

	[levelData skipBytes:4]; // Uncompressed size of 16 bit texture
	[levelData skipField32:1];
	
	unsigned uncompressedMiscSize = [levelData readUint32];
	if ((uncompressedMiscSize % 4*256*256) != 0) fail(TRWrongUncompressedSizeErrorCode, @"The level does not contain the right amount of texture data.", @"The level does not contain the right amount of texture data. It is likely that the level is corrupt.", @"Too much texture");
	unsigned compressedMiscSize = [levelData readUint32];
	
	TRLevelData *spriteTextureData = nil;
	@try
	{
		spriteTextureData = [levelData decompressLevelDataCompressedLength:compressedMiscSize uncompressedLength:uncompressedMiscSize];
	}
	@catch (NSException *exception)
	{
		DebugLog(@"%@ caught exception: %@", self, exception);
		fail(TRGenericDecompressionErrorCode, @"The texture data could not be decompressed", @"The textures could not be decoded. The file is apparently broken", @"Could not decompress");
	}
	if (!texture32Data) fail(TRGenericDecompressionErrorCode, @"The texture data could not be decompressed", @"The textures could not be decoded. The file is apparently broken", @"Could not decompress");
	
	[self readSpriteTexture32Length:uncompressedMiscSize from:spriteTextureData];
	if (![spriteTextureData isAtEnd]) fail(TRCouldNotLoadTextureErrorCode, @"The texture data could not be loaded", @"The textures could not be loaded. The file is apparently broken", @"Could not decompress");
	
	[pool release];
	
	return YES;
}

- (TRTexture)readObjectTexture:(TRLevelData *)levelData;
{
	TRTexture result;
	
	result.transparency = (unsigned) [levelData readUint16];
	if (result.transparency > TRTextureAlphaAdd) NSLog(@"Out of range ot t value %u", (unsigned) result.transparency);
	
	result.texturePageNumber = (unsigned) [levelData readUint16];
	
	result.texturePageNumber = result.texturePageNumber & 0x7FFF;
	
	[levelData skipBytes:2]; // Flags
	if (result.texturePageNumber >= numTexturePages) NSLog(@"texture page number is %u, ought to be smaller than %u", result.texturePageNumber, numTexturePages);
	
	unsigned i;
	for (i = 0; i < 4; i++)
	{	
		uint8_t pixelLocation[2];
		int8_t offset[2];
		offset[0] = [levelData readInt8];
		pixelLocation[0] = [levelData readUint8];
		offset[1] = [levelData readInt8];
		pixelLocation[1] = [levelData readUint8];
		
		if (offset[0] >= 0) pixelLocation[0]++;
		else pixelLocation[0]--;
		
		if (offset[1] >= 0) pixelLocation[1]++;
		else pixelLocation[1]--;
		
		result.coords[i][0] = (unsigned) pixelLocation[0];
		result.coords[i][1] = (unsigned) pixelLocation[1];
	}
	
	[levelData skipBytes:4*4]; // Two unknowns and height/width
	
	return result;
}

- (BOOL)readMoveables:(TRLevelData *)levelData outError:(NSError **)outError;
{	
	unsigned i;
	unsigned positionBeforeAnimations = [levelData position];
	unsigned animations = [levelData readUint32];
	DebugLog(@"Level has %u animations");
	[levelData skipBytes:animations * 40];
	//[levelData skipField32:40]; // Animations
	
	unsigned numStateChanges;
	TRStateChange *stateChanges;
	
	unsigned numAnimDispatches;
	TRAnimDispatch *dispatches;
	
	numStateChanges = [levelData readUint32];
	stateChanges = calloc(numStateChanges, sizeof(TRStateChange));
	for (i = 0; i < numStateChanges; i++)
		stateChanges[i] = [self readStateChange:levelData];
	
	numAnimDispatches = [levelData readUint32];
	dispatches = calloc(numAnimDispatches, sizeof(TRAnimDispatch));
	for (i = 0; i < numAnimDispatches; i++)
		dispatches[i] = [self readAnimDispatch:levelData];
	
	[levelData skipField32:2]; // Anim commands
	unsigned positionBeforeMeshTrees = [levelData position];
	[levelData skipField32:4]; // Mesh trees (will be parsed later)
	unsigned positionBeforeFrames = [levelData position];
	[levelData skipField32:2]; // Frames
	
	// Finalize loading state changes
	for(i = 0; i < numStateChanges; i++)
	{
		unsigned animDispatchIndex = (unsigned) stateChanges[i].dispatches;
		if (animDispatchIndex >= numAnimDispatches) [NSException raise:NSRangeException format:@"First dispatch of state change %u has index %u. NumAnimDispatches is %u", i, animDispatchIndex, numAnimDispatches];
		
		if ((animDispatchIndex + stateChanges[i].numDispatches - 1) >= numAnimDispatches) [NSException raise:NSRangeException format:@"Last dispatch of state change %u has index %u. NumAnimDispatches is %u", i, animDispatchIndex + stateChanges[i].numDispatches - 1, numAnimDispatches];
		
		stateChanges[i].dispatches = &dispatches[animDispatchIndex];
	}
	
	Class moveableClass = [[self class] animatedObjectClass];
	unsigned numMoveables = [levelData readUint32];
	NSMutableArray *mutableMoveables = [[NSMutableArray alloc] initWithCapacity:numMoveables];
	for (i = 0; i < numMoveables; i++)
	{
		TR4AnimatedObject *moveable = [[moveableClass alloc] initWithLevel:self levelData:levelData error:outError];
		if (!moveable)
		{
			if (outError && !*outError) *outError = [NSError trErrorWithCode:TRMeshLoadingUnspecificError description:@"A mesh could not be loaded" moreInfo:@"A 3D object from the file could not be loaded. The file is possibly corrupt." localizationSuffix:@"Generic mesh not loaded error"];
			[mutableMoveables release];
			free(stateChanges);
			free(dispatches);
			return NO;
		}
		
		unsigned levelDataPosition = [levelData position];
		
		[levelData setPosition:positionBeforeMeshTrees];
		[moveable readMeshTreeFrom:levelData];
		
		[levelData setPosition:positionBeforeAnimations];
		[moveable readAnimationsFrom:levelData];
		
		[levelData setPosition:positionBeforeFrames];
		[moveable readFramesFrom:levelData];
		
		[levelData setPosition:levelDataPosition];
		
		[mutableMoveables addObject:moveable];
	}
	
	moveables = [mutableMoveables copy];
	[mutableMoveables release];
	
	free(stateChanges);
	free(dispatches);
	
	return YES;
}

- (TRSpriteTexture)readSprite:(TRLevelData *)levelData;
{
	TRSpriteTexture result;
	
	result.texturePageNumber = (unsigned) [levelData readUint16];
	
	[levelData skipBytes:2]; // Unknown
	
	uint16_t width = [levelData readUint16];
	uint16_t height = [levelData readUint16];
	uint16_t coords[2][2];
	[levelData readUint16Array:coords[0] count:2];
	[levelData readUint16Array:coords[1] count:2];
	
	width = width / 256 + 1;
	height = height / 256 + 1;

	result.coords[0][0] = coords[0][0];
	result.coords[0][1] = coords[0][1];
	
	result.coords[1][0] = coords[1][0];
	result.coords[1][1] = coords[0][1];
	
	result.coords[2][0] = coords[1][0];
	result.coords[2][1] = coords[1][1];
	
	result.coords[3][0] = coords[0][0];
	result.coords[3][1] = coords[1][1];
	
	unsigned i;
	for (i = 0; i < 4; i++)
		result.distanceToEdge[i] = 0;
	
	return result;
}

@end
