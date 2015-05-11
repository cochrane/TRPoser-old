//
//  TRRenderRoom.h
//  TRViewer
//
//  Created by Torsten on 06.06.06.
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
#import "TRRenderLevel.h"
#import "MTypes.h"
#import "TR1Room.h"

@interface TRRenderRoom : NSObject <TRRendering>
{
	TR1Room *room;
	TRRenderLevel *level;
	
	BOOL hasAlpha, hasColored, hasTextured;
	unsigned alphaList, coloredList, texturedList;
	
	unsigned portalList;
	
	unsigned numPortals;
	TRRoomPortal *portals;
	
	BOOL visible;
	NSPoint roomPoint;
	
	NSMutableArray *ragdolls;
}

- (id)initWithRoom:(TR1Room *)aRoom renderLevel:(TRRenderLevel *)aLevel;

- (TR1Room *)room;

- (BOOL)isVisible;
- (void)resetVisible;
- (void)makeVisible;
- (void)recursiveFindVisibleRoomsWithinFrustum:(MPlane *)frustumPlanes cameraPoint:(MVec3)camPoint comingFrom:(TRRenderRoom *)previous;
- (void)renderTexturedInLevel;
- (void)renderAlphaInLevel;
- (void)renderColoredInLevel;
- (void)renderPortalsInLevel;

- (void)renderPortals;
- (unsigned)portalsDisplayList;
- (void)generatePortalDisplayList;

- (NSMutableArray *)ragdolls;

@end
