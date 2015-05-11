//
//  TRPoserDocument.m
//  TR Poser
//
//  Created by Torsten Kammer on 11.05.07.
//  Copyright 2007 Ferroequinologist.de. All rights reserved.
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

#import "TRPoserDocument.h"
#import "TRPoserAppController.h"
#import "TRLevelView.h"
#import "EasyCam.h"

#import "TR1Level.h"
#import "TR1Room.h"
#import "TR1AnimatedObject.h"

#import "TRRenderLevel.h"
#import "TRRenderRoom.h"
#import "TRRagdollInstance.h"

#import "SimpleErrorCreation.h"

/*

The TR Poser file format:
=========================

A TR Poser file is just a standard Apple property list, usually in binary format (though XML will work just as well). It can easily be edited with the Property List Editor included in the Developer's Tools.

The root is a dictionary, containing two keys:
- environmentLevel : An NSURL, here as a String, pointing to the environment level (i.e. the setting level)
- ragdolls : An Array of ragdoll description dictionaries. If not present at all, then the items placed in the environmentLevel will be automatically placed.
- camera : A dictionary describing where the camera is at. If not present, the default camera position (middle of bounding box of room 0) will be used. It has the following keys:
	- x, y, z : (float) position, giving the location of the item in TR Poser coordinates (inverted Y like Tomb Raider, but all TR coordinates divided by 1024)
	- rot1, rot2 : (float) rotation
	- frozen : (bool) whether it is frozen
	
	Notice that changes to the camera do not get registered in the undo manager, so even though a changed position will be saved when asked to, it will not trigger the "you have unsaved changes" field on its own.

The ragdoll description dictionaries have the following keys:
- level : An NSURL as string, pointing to the level the ragdoll comes from
- objectID : An (unsigned) integer, the object's ID in the level file.
- room : The room in the environment level where this thing is placed.
- position : A dictionary with the keys x, y and z (all float), giving the location of the item in TR Poser coordinates (inverted Y like Tomb Raider, but all TR coordinates divided by 1024)
- rotationSets : An array of dictionaries with the keys x, y and z (all float), giving the rotation of the various meshes (in degrees), in the order they are in the mesthree
	
*/

@interface TRPoserDocument (UndoSupport)

- (void)_clearUndoData:(NSNotification *)notification;
- (void)_levelPreviewOpenPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
- (void)_loadDocument;
- (NSDictionary *)_plistFromRagdoll:(TRRagdollInstance *)ragdoll containsRoomAndPosition:(BOOL)contains;
- (void)_placeRagdollFromPlist:(NSDictionary *)plist inRoom:(TRRenderRoom *)room;

@end

@implementation TRPoserDocument

- (id)init
{
	if (![super init]) return nil;
	renderLevels = [[NSMutableDictionary alloc] init];
	placedRagdolls = [[NSMutableArray alloc] init];
	
	loading = YES;
	lastUndoTarget = nil;
	lastUndoSelector = NULL;
	selectedIndices = [[NSIndexSet alloc] init];
	ragdollController = [[NSArrayController alloc] init];
	[ragdollController setObjectClass:[NSDictionary class]];
	[ragdollController setAutomaticallyPreparesContent:NO];
	[ragdollController setEditable:NO];
	[ragdollController setPreservesSelection:YES];
	[ragdollController setAvoidsEmptySelection:NO];
	[ragdollController bind:@"contentArray" toObject:self withKeyPath:@"placedRagdolls" options:nil];
	[ragdollController bind:@"selectionIndexes" toObject:self withKeyPath:@"selectedRagdollIndices" options:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_clearUndoData:) name:NSUndoManagerDidUndoChangeNotification object:[self undoManager]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_clearUndoData:) name:NSUndoManagerDidRedoChangeNotification object:[self undoManager]];
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[selectedIndices release];
	[renderLevels release];
	[placedRagdolls release];
	[super dealloc];
}

- (NSString *)windowNibName {
    // Implement this to return a nib to load OR implement -makeWindowControllers to manually create your controllers.
    return @"TRPoserDocument";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	if (![typeName isEqual:@"trpscene"])
	{
		if (outError != nil)
		{
			*outError = [NSError trErrorWithCode:-1 description:@"Type not supported" moreInfo:@"TR Poser doesn't support writing documents in the specified type. In fact, you shouldn't be seeing this message at all." localizationSuffix:@"document writing error"];
		}
		return nil;
	}
	
	TRPoserAppController *controller = [NSApp delegate];
	NSString *environmentLevelString = [[controller urlForLevel:environmentLevel] absoluteString];
	
	NSMutableArray *ragdollPlistArray = [NSMutableArray arrayWithCapacity:[placedRagdolls count]];
	NSEnumerator *enumerator = [placedRagdolls objectEnumerator];
	NSDictionary *ragdoll;
	while (ragdoll = [enumerator nextObject])
	{
		[ragdollPlistArray addObject:[self _plistFromRagdoll:[ragdoll valueForKey:@"ragdoll"] containsRoomAndPosition:YES]];
	}
	
	NSDictionary *camDict = [NSDictionary dictionaryWithObjectsAndKeys:[camera valueForKey:@"positionX"], @"x", [camera valueForKey:@"positionY"], @"y", [camera valueForKey:@"positionZ"], @"z", [camera valueForKey:@"frozen"], @"frozen", [camera valueForKey:@"rotation1"], @"rot1", [camera valueForKey:@"rotation2"], @"rot2", nil];
	
	NSDictionary *resultDict = [NSDictionary dictionaryWithObjectsAndKeys:environmentLevelString, @"environmentLevel", ragdollPlistArray, @"ragdolls", camDict, @"camera", nil];
	
	NSString *errorString = nil;
	NSData *resultData = [NSPropertyListSerialization dataFromPropertyList:resultDict format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorString];
	if (!resultData)
	{
		if (outError) *outError = [NSError trErrorWithCode:-3 description:@"Could not write file" moreInfo:errorString localizationSuffix:@"document writing error"];
		return nil;
	}
	
	return resultData;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	if ([typeName isEqual:@"trpscene"])
	{
		NSString *errorString = nil;
		loadData = [[NSDictionary alloc] initWithContentsOfURL:absoluteURL];
		if (!loadData)
		{
			*outError = [NSError trErrorWithCode:-2 description:@"The file is invalid and cannot be opened" moreInfo:errorString localizationSuffix:@"document reading error"];
			[errorString release];
			return NO;
		}
	}
	else if ([typeName isEqual:@"trlevel"])
	{
		loadData = [[NSDictionary dictionaryWithObject:absoluteURL forKey:@"environmentLevel"] retain];
	}
	else return NO;
	
    return YES;
}

- (void)close;
{
	[(TRPoserAppController *) [NSApp delegate] removeLevel:self];
	[super close];
}

- (void)placeObjectWithID:(unsigned)objectID fromFile:(NSURL *)levelURL;
{
	TRRenderRoom *currentRoom = [mainView currentRoom];
	if (!currentRoom)
	{
		NSBeep();
		return;
	}	
	[self willChangeValueForKey:@"placedRagdolls"];

	TR1Level *dataLevel = [(TRPoserAppController *) [NSApp delegate] levelWithURL:levelURL];
	TR1AnimatedObject *currentObject = [dataLevel moveableWithObjectID:objectID];
	
	TRRenderLevel *renderLevel = [renderLevels objectForKey:levelURL];
	if (!renderLevel)
	{
		renderLevel = [[TRRenderLevel alloc] initWithLevel:dataLevel automaticallyPlaceItems:NO];
		[renderLevels setObject:renderLevel forKey:levelURL];
		[renderLevel release];
	}

	TRRagdollInstance *ragdoll = [renderLevel createNewRagdoll:currentObject inRoom:currentRoom];
	[ragdoll setView:mainView];
	[ragdoll setDocument:self];
	[(NSMutableArray *) [currentRoom ragdolls] addObject:ragdoll];
	
	NSDictionary *ragdollDict = [NSDictionary dictionaryWithObjectsAndKeys:ragdoll, @"ragdoll", levelURL, @"level", nil];
	[self insertObject:ragdollDict inPlacedRagdollsAtIndex:[self countOfPlacedRagdolls]];
		
	[self didChangeValueForKey:@"placedRagdolls"];
}

- (NSArray *)placedRagdolls;
{
	return placedRagdolls;
}

- (BOOL)canAddRagdoll;
{
	return [mainView currentRoom] != nil;
}

- (void)setCamera:(id)someCam
{
	[self willChangeValueForKey:@"camera"];
	camera = someCam;
	[self didChangeValueForKey:@"camera"];
}

- (id)camera
{
	return camera;
}

- (void)cut:(id)sender
{
	[self copy:sender];
	[self delete:sender];
	[[self undoManager] setActionName:NSLocalizedString(@"Cut", @"undo")];
}

- (void)copy:(id)sender
{
	NSArray *selectedRagdolls = [ragdollController selectedObjects];
	NSMutableArray *ragdollCopyArray = [[NSMutableArray alloc] initWithCapacity:[selectedRagdolls count]];
	
	NSEnumerator *selectionEnumerator = [selectedRagdolls objectEnumerator];
	NSDictionary *selectedRagdoll;
	while (selectedRagdoll = [selectionEnumerator nextObject])
	{
		[ragdollCopyArray addObject:[self _plistFromRagdoll:[selectedRagdoll valueForKey:@"ragdoll"] containsRoomAndPosition:NO]];
	}
	
	NSArray *pasteboardTypes = [NSArray arrayWithObject:@"de.ferroequinologist.trposer.ragdoll"];
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard declareTypes:pasteboardTypes owner:self];
	[pasteboard setPropertyList:ragdollCopyArray forType:@"de.ferroequinologist.trposer.ragdoll"];
	[ragdollCopyArray release];
}

- (void)paste:(id)sender
{
	NSArray *pasteData = [[NSPasteboard generalPasteboard] propertyListForType:@"de.ferroequinologist.trposer.ragdoll"];
	if (!pasteData || [pasteData count] == 0) return;
	TRRenderRoom *theRoom = [mainView currentRoom];
	if (!theRoom) return;
	
	NSEnumerator *pasteEnumerator = [pasteData objectEnumerator];
	NSDictionary *ragdollDict;
	while (ragdollDict = [pasteEnumerator nextObject])
		[self _placeRagdollFromPlist:ragdollDict inRoom:theRoom];
	
	[[self undoManager] setActionName:NSLocalizedString(@"Paste", @"undo")];
}

- (void)delete:(id)sender;
{
	[ragdollController remove:sender];
}

- (void)selectAll:(id)sender;
{
	[ragdollController setSelectionIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [placedRagdolls count])]];
}

- (void)finishLoading;
{
	if (!loading) return;
	
	// Set up connections
	[mainView bind:@"showsPortals" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.showPortalOutlines" options:nil];
	[mainView bind:@"showsSelection" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.rendersSelection" options:nil];
	
	if (!loadData)
	{
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setAllowsMultipleSelection:YES];
		NSArray *types = [NSArray arrayWithObjects:@"tr2", @"phd", @"tr4", nil];
		[openPanel setTitle:NSLocalizedString(@"Open environment level", @"Title for open panel for choosing the level that is used as environment.")];
		[openPanel beginSheetForDirectory:nil file:nil types:types modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(_levelPreviewOpenPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
		return;
	}
	else
	{
		[self _loadDocument];
	}
}

- (void)showWindows
{
	[super showWindows];
	[(TRPoserAppController *) [NSApp delegate] newFrontLevel:self];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	[(TRPoserAppController *) [NSApp delegate] newFrontLevel:self];
}

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
	[(TRPoserAppController *) [NSApp delegate] newFrontLevel:self];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender
{
	return [self undoManager];
}

- (unsigned int)countOfPlacedRagdolls;
{
	return [placedRagdolls count];
}
- (NSDictionary *)objectInPlacedRagdollsAtIndex:(unsigned)index;
{
	return [placedRagdolls objectAtIndex:index];
}
- (void)getPlacedRagdolls:(NSDictionary **)ragdolls range:(NSRange)inRange;
{
	[placedRagdolls getObjects:ragdolls range:inRange];
}
- (void)insertObject:(NSDictionary *)ragdoll inPlacedRagdollsAtIndex:(unsigned int)index;
{
	NSIndexSet *setWithOneIndex = [NSIndexSet indexSetWithIndex:index];
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:setWithOneIndex forKey:@"placedRagdolls"];
	
	[placedRagdolls insertObject:ragdoll atIndex:index];
	TRRenderRoom *room = [ragdoll valueForKeyPath:@"ragdoll.room"];
	[[room ragdolls] addObject:[ragdoll valueForKey:@"ragdoll"]];
	
	[[[self undoManager] prepareWithInvocationTarget:self] removeObjectFromPlacedRagdollsAtIndex:index];
	[[self undoManager] setActionName:NSLocalizedString(@"Insert Object", @"undo")];
	
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:setWithOneIndex forKey:@"placedRagdolls"];
	lastUndoTarget = nil;
	lastUndoSelector = NULL;
	[mainView setNeedsDisplay:YES];
}
- (void)removeObjectFromPlacedRagdollsAtIndex:(unsigned int)index;
{
	NSIndexSet *setWithOneIndex = [NSIndexSet indexSetWithIndex:index];
	[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:setWithOneIndex forKey:@"placedRagdolls"];

	NSDictionary *objectAtIndex = [placedRagdolls objectAtIndex:index];
	TRRenderRoom *room = [objectAtIndex valueForKeyPath:@"ragdoll.room"];
	
	[[room ragdolls] removeObject:[objectAtIndex valueForKey:@"ragdoll"]];
	
	[placedRagdolls removeObjectAtIndex:index];
	
	[[[self undoManager] prepareWithInvocationTarget:self] insertObject:objectAtIndex inPlacedRagdollsAtIndex:index];
	[[self undoManager] setActionName:NSLocalizedString(@"Remove Object", @"undo")];
	
	[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:setWithOneIndex forKey:@"placedRagdolls"];
	lastUndoTarget = nil;
	lastUndoSelector = NULL;
	[mainView setNeedsDisplay:YES];
}

- (NSArrayController *)ragdollController
{
	return ragdollController;
}

- (void)setSelectedRagdollIndices:(NSIndexSet *)set;
{
	// I don't really need to track the selection indices, but I have to avoid an empty selection, because otherwise that goddamn NSArrayController will reset the selection every time one switches to another document. Which sucks. Also, I use this to inform the view that it needs to redraw. A normal addObserver:thingy: would work too, but this method already exists, so why not use it?
	if ([set count] == 0) return;
	[self willChangeValueForKey:@"selectedRagdollIndices"];
	[selectedIndices release];
	selectedIndices = [set copy];
	[self didChangeValueForKey:@"selectedRagdollIndices"];
	[mainView setNeedsDisplay:YES];
}
- (NSIndexSet *)selectedRagdollIndices;
{
	return selectedIndices;
}

- (BOOL)shouldMesh:(TRRagdollMeshInstance *)instance registerForUndoWithSelector:(SEL)aSelector;
{
	if ((lastUndoTarget == instance) && (lastUndoSelector == aSelector)) return NO;
	lastUndoTarget = instance;
	lastUndoSelector = aSelector;
	return YES;
}

- (TRLevelView *)mainView
{
	return mainView;
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	NSArray *pasteboardTypes = [NSArray arrayWithObject:@"de.ferroequinologist.trposer.ragdoll"];
	SEL theAction = [anItem action];
	if (theAction == @selector(cut:) || theAction == @selector(delete:) || theAction == @selector(copy:))
		return ([[self valueForKey:@"selectedRagdollIndices"] count] != 0) && ([placedRagdolls count] != 0);
	else if (theAction == @selector(paste:))
		return ([mainView currentRoom] != nil) && ([[NSPasteboard generalPasteboard] availableTypeFromArray:pasteboardTypes] != nil);
	else return [super validateUserInterfaceItem:anItem];
}

@end

@implementation TRPoserDocument (UndoSupport)

- (void)_clearUndoData:(NSNotification *)notification;
{
	lastUndoTarget = nil;
	lastUndoSelector = NULL;
}

- (void)_levelPreviewOpenPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
{
	if (returnCode != NSOKButton)
	{
		[self close];
		return;
	}
	NSURL *levelURL = [panel URL];
	if (!levelURL)
	{
		[self close];
		return;
	}
	
	loadData = [NSDictionary dictionaryWithObject:levelURL forKey:@"environmentLevel"];
	[loadData retain];
	
	[self _loadDocument];
}

- (void)_loadDocument
{
	[self willChangeValueForKey:@"placedRagdolls"];
	[self willChangeValueForKey:@"camera"];
	
	[[self undoManager] disableUndoRegistration];
	
	id environmentLevelURL = [loadData objectForKey:@"environmentLevel"];
	if ([environmentLevelURL isKindOfClass:[NSString class]]) environmentLevelURL = [NSURL URLWithString:environmentLevelURL];
	
	environmentLevel = [(TRPoserAppController *) [NSApp delegate] levelWithURL:environmentLevelURL];
	if (!environmentLevel) return;
	
	NSArray *posedRagdolls = [loadData objectForKey:@"ragdolls"];
	BOOL loadItemsFromObjectFile = (posedRagdolls == nil);
	environmentRenderLevel = [[TRRenderLevel alloc] initWithLevel:environmentLevel automaticallyPlaceItems:loadItemsFromObjectFile];
	[mainView setLevel:environmentRenderLevel];
	[renderLevels setObject:environmentRenderLevel forKey:environmentLevelURL];
	[environmentRenderLevel release];
	
	if (loadItemsFromObjectFile)
	{
		NSArray *loadedRagdolls = [environmentRenderLevel automaticallyPlacedRagdolls];
		NSEnumerator *ragdollEnumerator = [loadedRagdolls objectEnumerator];
		TRRagdollInstance *ragdoll;
		while (ragdoll = [ragdollEnumerator nextObject])
		{
			[ragdoll setView:mainView];
			[ragdoll setDocument:self];
			[placedRagdolls addObject:[NSDictionary dictionaryWithObjectsAndKeys:ragdoll, @"ragdoll", environmentLevelURL, @"level", nil]];
		}
	}
	
	NSArray *ragdolls = [loadData objectForKey:@"ragdolls"];
	if (!ragdolls) ragdolls = [NSArray array];
	NSEnumerator *enumerator = [ragdolls objectEnumerator];
	NSDictionary *ragdollDict;
	while (ragdollDict = [enumerator nextObject])
		[self _placeRagdollFromPlist:ragdollDict inRoom:nil];	

	camera = [mainView camera];
	
	NSDictionary *camDict = [loadData objectForKey:@"camera"];
	if (camDict)
	{
		float x = [[camDict valueForKey:@"x"] floatValue];
		float y = [[camDict valueForKey:@"y"] floatValue];
		float z = [[camDict valueForKey:@"z"] floatValue];
		
		[camera setDefaultLocationX:x y:y z:z];
		
		float rot1 = [[camDict valueForKey:@"rot1"] floatValue];
		float rot2 = [[camDict valueForKey:@"rot2"] floatValue];
		
		[camera setDefaultRotationAroundX:rot2 y:rot1];
		
		BOOL frozen = [[camDict valueForKey:@"frozen"] boolValue];
		[camera setFrozen:frozen];
	}
	
	[loadData release];
	loadData = nil;
	
	loading = NO;
	
	[mainView setNeedsDisplay:YES];
	
	[[self undoManager] enableUndoRegistration];
	
	[self didChangeValueForKey:@"placedRagdolls"];
	[self didChangeValueForKey:@"camera"];
}

- (NSDictionary *)_plistFromRagdoll:(TRRagdollInstance *)ragdoll containsRoomAndPosition:(BOOL)contains;
{
	NSMutableArray *rotationArray = [[NSMutableArray alloc] initWithCapacity:[[ragdoll valueForKeyPath:@"meshes"] count]];
	
	NSEnumerator *rotationEnumerator = [[ragdoll valueForKeyPath:@"meshes"] objectEnumerator];
	TRRagdollMeshInstance *mesh;
	while (mesh = [rotationEnumerator nextObject])
	{
		NSDictionary *rotationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[mesh valueForKey:@"rotationX"], @"x", [mesh valueForKey:@"rotationY"], @"y", [mesh valueForKey:@"rotationZ"], @"z", nil];
		[rotationArray addObject:rotationDictionary];
	}
	
	NSString *levelString = [[(TRPoserAppController *) [NSApp delegate] urlForLevel:[ragdoll valueForKeyPath:@"renderLevel.originalLevel"]] absoluteString];
	NSNumber *objectID = [ragdoll valueForKeyPath:@"objectID"];
	
	NSDictionary *result;
	if (contains)
	{
		NSNumber *room = [ragdoll valueForKeyPath:@"room.room.numberInLevel"];
		NSDictionary *location = [NSDictionary dictionaryWithObjectsAndKeys:[ragdoll valueForKeyPath:@"rootMesh.locationX"], @"x", [ragdoll valueForKeyPath:@"rootMesh.locationY"], @"y", [ragdoll valueForKeyPath:@"rootMesh.locationZ"], @"z", nil];
		
		result = [NSDictionary dictionaryWithObjectsAndKeys:levelString, @"level", objectID, @"objectID", room, @"room", location, @"position", rotationArray, @"rotationSets", nil];
	}
	else
		result = [NSDictionary dictionaryWithObjectsAndKeys:levelString, @"level", objectID, @"objectID", rotationArray, @"rotationSets", nil];
	
	[rotationArray release];
	
	return result;
}

- (void)_placeRagdollFromPlist:(NSDictionary *)ragdollDict inRoom:(TRRenderRoom *)room;
{
	NSURL *levelURL = [NSURL URLWithString:[ragdollDict objectForKey:@"level"]];
	
	unsigned objectID = [[ragdollDict objectForKey:@"objectID"] unsignedIntValue];
	
	TR1Level *dataLevel = [(TRPoserAppController *) [NSApp delegate] levelWithURL:levelURL];
	TR1AnimatedObject *currentObject = [dataLevel moveableWithObjectID:objectID];
	
	TRRenderLevel *renderLevel = [renderLevels objectForKey:levelURL];
	if (!renderLevel)
	{
		renderLevel = [[TRRenderLevel alloc] initWithLevel:dataLevel automaticallyPlaceItems:NO];
		[renderLevels setObject:renderLevel forKey:levelURL];
		[renderLevel release];
	}
	
	TRRagdollInstance *ragdoll;
	if (!room)
	{
		unsigned roomNumber = [[ragdollDict objectForKey:@"room"] unsignedIntValue];
		TR1Room *dataroom = [[environmentLevel rooms] objectAtIndex:roomNumber];
	
		TRRenderRoom *renderRoom = [environmentRenderLevel renderRoomForRoom:dataroom];
		ragdoll = [renderLevel createNewRagdoll:currentObject inRoom:renderRoom];
		[(NSMutableArray *) [renderRoom ragdolls] addObject:ragdoll];
		// Set position and rotation
		NSNumber *positionX = [ragdollDict valueForKeyPath:@"position.x"];
		NSNumber *positionY = [ragdollDict valueForKeyPath:@"position.y"];
		NSNumber *positionZ = [ragdollDict valueForKeyPath:@"position.z"];
		TRRagdollMeshInstance *root = [ragdoll rootMesh];
		[root setLocationX:[positionX floatValue]];
		[root setLocationY:[positionY floatValue]];
		[root setLocationZ:[positionZ floatValue]];
	}
	else
	{
		ragdoll = [renderLevel createNewRagdoll:currentObject inRoom:room];
		[(NSMutableArray *) [room ragdolls] addObject:ragdoll];
	}

	[ragdoll setView:mainView];
	[ragdoll setDocument:self];
	
	// This way, KVO notifications will be sent.
	NSMutableArray *placedRagdollArray = [self mutableArrayValueForKey:@"placedRagdolls"];
	[placedRagdollArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:ragdoll, @"ragdoll", levelURL, @"level", nil]];
	
	unsigned i, count = [[ragdollDict valueForKey:@"rotationSets"] count];
	for (i = 0; i < count; i++)
	{
		[[[ragdoll meshes] objectAtIndex:i] setRotationX:[[[[ragdollDict valueForKey:@"rotationSets"] objectAtIndex:i] valueForKey:@"x"] floatValue]];
		[[[ragdoll meshes] objectAtIndex:i] setRotationY:[[[[ragdollDict valueForKey:@"rotationSets"] objectAtIndex:i] valueForKey:@"y"] floatValue]];
		[[[ragdoll meshes] objectAtIndex:i] setRotationZ:[[[[ragdollDict valueForKey:@"rotationSets"] objectAtIndex:i] valueForKey:@"z"] floatValue]];
	}
}

@end