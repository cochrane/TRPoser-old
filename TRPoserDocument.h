//
//  TRPoserDocument.h
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

#import <Cocoa/Cocoa.h>

@class TRLevelView;
@class TRObjectView;
@class TR1Level;
@class TRRenderLevel;
@class TRRagdollMeshInstance;

@interface TRPoserDocument : NSDocument
{
    IBOutlet TRLevelView *mainView;
	IBOutlet NSWindow *mainWindow;
	
	NSDictionary *loadData;
	NSArrayController *ragdollController;
	
	TR1Level *environmentLevel;
	TRRenderLevel *environmentRenderLevel;
	
	NSMutableDictionary *renderLevels;
	NSMutableArray *placedRagdolls;
	
	TRRagdollMeshInstance *lastUndoTarget;
	SEL lastUndoSelector;
	
	NSIndexSet *selectedIndices;
	
	BOOL loading;
	
	id camera;
}
- (void)placeObjectWithID:(unsigned)objectID fromFile:(NSURL *)levelFile;

- (NSArray *)placedRagdolls;

- (unsigned int)countOfPlacedRagdolls;
- (NSDictionary *)objectInPlacedRagdollsAtIndex:(unsigned)index;
- (void)getPlacedRagdolls:(NSDictionary **)transactions range:(NSRange)inRange;
- (void)insertObject:(NSDictionary *)ragdoll inPlacedRagdollsAtIndex:(unsigned int)index;
- (void)removeObjectFromPlacedRagdollsAtIndex:(unsigned int)index;

- (TRLevelView *)mainView;

- (BOOL)canAddRagdoll;

- (void)finishLoading;

- (BOOL)shouldMesh:(TRRagdollMeshInstance *)instance registerForUndoWithSelector:(SEL)aSelector;

- (void)cut:(id)sender;
- (void)copy:(id)sender;
- (void)paste:(id)sender;
- (void)delete:(id)sender;
- (void)selectAll:(id)sender;

@end
