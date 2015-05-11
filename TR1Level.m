//
//  TR1Level.m
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

#import "TR1Level.h"
#import "TR2Level.h"
#import "TR3Level.h"
#import "TR4Level.h"

#import "TR1Room.h"
#import "TR1Mesh.h"

#import "TRLevelData.h"
#import "TR1AnimatedObject.h"

#import "SimpleErrorCreation.h"

@implementation TR1Level

+ (Class)subclassForLevelData:(TRLevelData *)levelData;
{
	unsigned version = [levelData readUint32];
	[levelData setPosition:0];
	switch(version)
	{
		case 0x00000020:
			return [TR1Level class];
		break;
		case 0x0000002d:
			return [TR2Level class];
		break;
		case 0xFF080038:
		case 0xFF180038:
			return [TR3Level class];
		break;
		default:
		{
			char header[4];
			[levelData readUint8Array:(void *)header count:4];
			[levelData setPosition:0];
			if (strcmp(header, "TR4") == 0) return [TR4Level class];
		}
		break;
	}
	
	return Nil;
}


+ (id)levelWithData:(NSData *)data error:(NSError **)outError;
{
	TRLevelData *levelData = [[TRLevelData alloc] initWithData:data];
	
	Class subclass = [self subclassForLevelData:levelData];
	id result = nil;
	if (subclass) result = [[subclass alloc] initWithLevelData:levelData error:outError];
	else if (outError) *outError = [NSError errorWithDomain:@"TR Level loading domain" code:TRNoTRFileErrorCode userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Could not find out type of level", @"Error: Wrong header"), NSLocalizedDescriptionKey, NSLocalizedString(@"The file is probably not a valid Tomb Raider file, or from an unsupported version of Tomb Raider. It could be a demo file", @"Reason: Wrong header"), NSLocalizedFailureReasonErrorKey, NSLocalizedString(@"The file is not of a supported type. Only levels from the full versions of Tomb Raider 1 till 4 can be opened.", @"Recovery: Wrong header"), NSLocalizedRecoverySuggestionErrorKey, nil]];
	
	[levelData release];
	return result;
}

+ (Class)roomClass;
{
	return [TR1Room class];
}

+ (Class)meshClass;
{
	return [TR1Mesh class];
}

+ (Class)animatedObjectClass;
{
	return [TR1AnimatedObject class];
}

+ (unsigned)fontSpriteSequenceID;
{
	// This is the objectID of the sprite sequence that contains all letters
	return 190;
}

+ (float)convertRawLightValue:(float)value;
{
	return 1.0f - ((float) value + 1.0f) / 8192.0f;
}

- (unsigned)meshTextureBasePage;
{
	return 0;
}

- (id)initWithLevelData:(TRLevelData *)levelData error:(NSError **)outError;
{
	if (![super init])
	{
		[self release];
		return nil;
	}
	
	#define fail(ecode, edescription, suggestion, localizableKey) \
	do \
	{ \
		if (outError) *outError = [NSError trErrorWithCode:ecode description:edescription moreInfo:suggestion localizationSuffix:localizableKey]; \
		[self release]; \
		return nil; \
	} \
	while (0)
	
	unsigned i;
	
	// Check for correct header
	unsigned version = [levelData readUint32];
	if (version != 0x00000020) fail(TRNoSpecificTRFileErrorCode, @"The level is not a Tomb Raider 1 level", @"You ought not see this error. it only comes up when the level changed while I was reading this. If you do see this error, RUN!", @"Not TR1");
	
	numTexturePages = [levelData readUint32];
	[self readTexture8Tiles:numTexturePages from:levelData];
	
	[levelData skipBytes:4];
	BOOL success = [self readRooms:levelData outError:outError];
	if (!success)
	{
		[self release];
		return nil;
	}
	
	[levelData skipField32:2]; // Floor data
	
	success = [self readMeshes:levelData outError:outError];
	if (!success)
	{
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
	[levelData skipField32:16]; // Sound Sources
	unsigned numBoxes = [levelData readUint32];
	[levelData skipBytes:numBoxes * 20]; // Boxes
	[levelData skipField32:2]; // Overlaps
	[levelData skipBytes:numBoxes * 12]; // Zones
	[levelData skipField32:2]; // Animated textures
	
	numItems = [levelData readUint32];
	items = calloc(numItems, sizeof(TRItem));
	for (i = 0; i < numItems; i++)
		items[i] = [self readItem:levelData];
	
	[levelData skipBytes:8192]; // Light map
	[self readPalette8:levelData];
	[self convertTexture8To32];
	
	// We ignore the rest of the level file
	
	@try
	{
		[self finalizeLoading];
	}
	@catch (NSException *exception)
	{
		DebugLog(@"TR1Level caught exception %@", exception);
		// The only kind of exception we could see is something is out of bounds, so…
		fail(TRIndexOutOfBoundsErrorCode, @"An interal index is out of bounds", @"A part of the file points to wrong other parts of the file. The level is likely corrupt", @"Generic index out of bounds");
	}
	
	return self;
}

- (void)dealloc
{
	if (texture) free(texture);
	if (palette) free(palette);
	
	if (rooms) [rooms release];
	if (meshes) [meshes release];
	
	if (staticMeshes) free(staticMeshes);
	if (textures) free(textures);
	if (sprites) free(sprites);
	if (spriteSequences) free(spriteSequences);
	if (items) free(items);
	
	[super dealloc];
}

- (unsigned)texturePageCount;
{
	return numTexturePages;
}
- (void *)texturePageAtIndex:(unsigned)pageNumber;
{
	if (pageNumber >= numTexturePages) return NULL;
	return &texture[256 * 256 * 4 * pageNumber];
}

- (NSArray *)rooms;
{
	return rooms;
}
- (NSArray *)meshes;
{
	return meshes;
}
- (NSArray *)moveables;
{
	return moveables;
}
- (unsigned)itemCount
{
	return numItems;
}
- (TRItem *)items
{
	return items;
}

#pragma mark Methods used to read a level

- (void)readTexture8Tiles:(unsigned)tileCount from:(TRLevelData *)levelData;
{
	// We treat the level as having 16 texture tiles all the time -- not any longer
	texture = malloc(256 * 256 * tileCount);
	memset(texture, 0, 256 * 256 * tileCount);
	[levelData readUint8Array:texture count:256 * 256 * tileCount];
}

- (void)readPalette8:(TRLevelData *)levelData;
{
	// This method will transform the palette into the ARGB palette while reading
	// ARGB because we don't really need it very often to get single colors, mainly just for texture data lookup on TR1
	uint8_t *paletteRGB = malloc(768);
	[levelData readUint8Array:paletteRGB count:768];
	palette = malloc(1024);
	unsigned i;
	for (i = 0; i < 256; i++)
	{
		palette[i*4 + 0] = 255;
		palette[i*4 + 1] = paletteRGB[i*3 + 0] * 4;
		palette[i*4 + 2] = paletteRGB[i*3 + 1] * 4;
		palette[i*4 + 3] = paletteRGB[i*3 + 2] * 4;
	}
	palette[0] = 0; // Index 0 is transparent color.
	
	free(paletteRGB);
}

- (BOOL)readMoveables:(TRLevelData *)levelData outError:(NSError **)outError;
{
	unsigned i;
	unsigned positionBeforeAnimations = [levelData position];
	[levelData skipField32:32]; // Animations
	
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
	unsigned frameCount = [levelData readUint32];
	[levelData skipBytes:frameCount * 2];// Frames (will be parsed later)
	
	
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
		TR1AnimatedObject *moveable = [[moveableClass alloc] initWithLevel:self levelData:levelData error:outError];
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

- (BOOL)readMeshes:(TRLevelData *)levelData outError:(NSError **)outError;
{
	Class meshClass = [[self class] meshClass];
	
	unsigned numMeshData = [levelData readUint32];
	TRLevelData *meshData = [levelData subdataWithLength:numMeshData * 2];
	
	unsigned numMeshes = [levelData readUint32];
	unsigned *meshPointers = malloc(sizeof(uint32_t) * numMeshes);
	[levelData readUint32Array:meshPointers count:numMeshes];
	
	NSMutableArray *mutableMeshes = [[NSMutableArray alloc] initWithCapacity:numMeshes];
	unsigned i;
	for (i = 0; i < numMeshes; i++)
	{
		[meshData setPosition:0];
		[meshData skipBytes:meshPointers[i]];
		TR1Mesh *mesh = [[meshClass alloc] initWithLevelData:meshData error:outError];
		if (!mesh)
		{
			if (outError && !*outError) *outError = [NSError trErrorWithCode:TRMeshLoadingUnspecificError description:@"A mesh could not be loaded" moreInfo:@"A 3D object from the file could not be loaded. The file is possibly corrupt." localizationSuffix:@"Generic mesh not loaded error"];
			[mutableMeshes release];
			free(meshPointers);
			return NO;
		}
		[mutableMeshes addObject:mesh];
		[mesh release];
	}
	free(meshPointers);
	meshes = [mutableMeshes copy];
	[mutableMeshes release];
	
	return YES;
}
- (BOOL)readRooms:(TRLevelData *)levelData outError:(NSError **)outError;
{
	Class roomClass = [[self class] roomClass];
	unsigned numRooms = (unsigned) [levelData readUint16];
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

#pragma mark Internal methods to bring a level in a canonical form

- (void)convertTexture8To32;
{
	uint8_t *textureARGB = malloc(256*256*numTexturePages*4);
	unsigned i;
	for (i = 0; i < (256*256*numTexturePages); i++)
		memcpy(&textureARGB[i*4], &palette[texture[i] * 4], 4);
	
	free(texture);
	texture = textureARGB;
}

- (void)finalizeLoading;
{
	NSEnumerator *enumerator = [meshes objectEnumerator];
	TR1Mesh *mesh;
	while (mesh = [enumerator nextObject])
		[mesh setLevel:self];
	
	TR1Mesh *room;
	enumerator = [rooms objectEnumerator];
	while (room = [enumerator nextObject])
		[room setLevel:self];
}

- (TRStaticMesh)readStaticMesh:(TRLevelData *)levelData;
{
	TRStaticMesh result;
	
	result.objectID = [levelData readUint32];
	unsigned meshIndex = (unsigned) [levelData readUint16];
	result.mesh = [meshes objectAtIndex:meshIndex];
	
	int16_t boundingBox[6];
	[levelData readUint16Array:(uint16_t *) boundingBox count:6];
	
	result.visibilityBoundingBox[0].x = (float) boundingBox[0] / 1024.0f;
	result.visibilityBoundingBox[0].y = (float) boundingBox[1] / 1024.0f;
	result.visibilityBoundingBox[0].z = (float) boundingBox[2] / 1024.0f;
	result.visibilityBoundingBox[1].x = (float) boundingBox[3] / 1024.0f;
	result.visibilityBoundingBox[1].y = (float) boundingBox[4] / 1024.0f;
	result.visibilityBoundingBox[1].z = (float) boundingBox[5] / 1024.0f;
	
	
	[levelData readUint16Array:(uint16_t *) boundingBox count:6];
	
	result.collisionBoundingBox[0].x = (float) boundingBox[0] / 1024.0f;
	result.collisionBoundingBox[0].y = (float) boundingBox[1] / 1024.0f;
	result.collisionBoundingBox[0].z = (float) boundingBox[2] / 1024.0f;
	result.collisionBoundingBox[1].x = (float) boundingBox[3] / 1024.0f;
	result.collisionBoundingBox[1].y = (float) boundingBox[4] / 1024.0f;
	result.collisionBoundingBox[1].z = (float) boundingBox[5] / 1024.0f;
	
	uint16_t flags = [levelData readUint16];
	if (flags == 3) result.colliding = NO;
	else result.colliding = YES;
	
	return result;
}

- (TRTexture)readObjectTexture:(TRLevelData *)levelData;
{
	TRTexture result;
	
	result.transparency = [levelData readUint16];
	if (result.transparency > TRTextureAlphaAdd) NSLog(@"Out of range ot t value %u", (unsigned) result.transparency);
	result.texturePageNumber = (unsigned) [levelData readUint16];
	
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
	
	return result;
}

- (TRAnimDispatch)readAnimDispatch:(TRLevelData *)levelData;
{
	TRAnimDispatch result;
	
	result.minFrameIndex = (unsigned) [levelData readUint16];
	result.maxFrameIndex = (unsigned) [levelData readUint16];
	
	//unsigned animationIndex = (unsigned) [levelData readUint16];
	[levelData skipBytes:2];
	// Notice that I don't check the bounds. The reason: If this is really out of bounds, the NSArray will throw an exception. If I checked the bounds, I'd throw the exception. Pointless
	//result.animation = [animations objectAtIndex:animationIndex];
	
	result.nextFrameIndex = (unsigned) [levelData readUint16];
	
	return result;
}

- (TRStateChange)readStateChange:(TRLevelData *)levelData;
{
	TRStateChange result;
	
	result.stateID = (unsigned) [levelData readUint16];
	result.numDispatches = (unsigned) [levelData readUint16];
	
	unsigned firstDispatch = (unsigned) [levelData readUint16];
	// We load the true dispatch pointer as soon as the dispatches are loaded
	result.dispatches = (TRAnimDispatch *) firstDispatch;
	
	return result;
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
	result.position.x = (float) position[0] / 1024.0f;
	result.position.y = (float) position[1] / 1024.0f;
	result.position.z = (float) position[2] / 1024.0f;
	
	result.angle = ((float) [levelData readInt16]) / 16384.0f * -90.0f;
	float lightValue1 = (float) [levelData readInt16];
	result.lightValue = [[self class] convertRawLightValue:lightValue1];
	result.lightValue2 = result.lightValue;
	uint16_t flags = [levelData readUint16];
	result.invisible = flags & 0x0100;
	
	return result;
}

- (void)getColor:(float [4])color forPaletteIndex:(unsigned)unalteredIndex;
{
	unsigned palette8index = unalteredIndex & 0xff;
	
	uint8_t colorARGB[4];
	memcpy(colorARGB, &palette[palette8index * 4], 4);
	
	color[0] = (float) colorARGB[1] / 255.0f;
	color[1] = (float) colorARGB[2] / 255.0f;
	color[2] = (float) colorARGB[3] / 255.0f;
	color[3] = (float) colorARGB[0] / 255.0f;
}

- (TRSpriteTexture)readSprite:(TRLevelData *)levelData;
{
	TRSpriteTexture result;
	
	result.texturePageNumber = (unsigned) [levelData readUint16];
	uint8_t coords[2];
	[levelData readUint8Array:coords count:2];
	uint16_t width = [levelData readUint16];
	uint16_t height = [levelData readUint16];
	
	width = (width - 255) / 256;
	height = (height - 255) / 256;

	result.coords[0][0] = coords[0];
	result.coords[0][1] = coords[1];
	
	result.coords[1][0] = coords[0] + width;
	result.coords[1][1] = coords[1];
	
	result.coords[2][0] = coords[0] + width;
	result.coords[2][1] = coords[1] + height;
	
	result.coords[3][0] = coords[0];
	result.coords[3][1] = coords[1] + height;
	
	unsigned i;
	for (i = 0; i < 4; i++)
		result.distanceToEdge[i] = (int) [levelData readInt16];
	
	return result;
}

- (TRSpriteSequence)readSpriteSequence:(TRLevelData *)levelData;
{
	TRSpriteSequence result;
	
	result.objectID = [levelData readUint32];
	result.numberOfSprites = (unsigned) (-1 * [levelData readInt16]);
	result.firstSpriteTexture = (unsigned) [levelData readUint16];
	
	return result;
}

- (TRTexture *)textureAtIndex:(unsigned)index;
{
	index = index & 0x0fff;
	if (index > numTextures) return NULL;
	return &textures[index];
}
- (TRStaticMesh *)staticMeshWithObjectID:(unsigned)index;
{	
	unsigned i;
	for (i = 0; i < numStaticMeshes; i++)
	{
		if (staticMeshes[i].objectID == index)
			return &staticMeshes[i];
	}
	
	return NULL;
}
- (TRSpriteTexture *)spriteTextureAtIndex:(unsigned)index;
{
	if (index > numSprites) return NULL;
	return &sprites[index];
}
- (TRSpriteSequence *)spriteSequenceWithObjectID:(unsigned)index;
{
	unsigned i;
	for (i = 0; i < numSpriteSequences; i++)
		if (spriteSequences[i].objectID == index) return &spriteSequences[i];
	
	return NULL;
}

- (TR1AnimatedObject *)moveableWithObjectID:(unsigned)objectID;
{
	NSEnumerator *enumerator = [moveables objectEnumerator];
	TR1AnimatedObject *object;
	while (object = [enumerator nextObject])
	{
		if ([object objectID] == objectID) return object;
	}
	return nil;
}

@end
