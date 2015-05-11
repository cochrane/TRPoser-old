/* TRLevelView */
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

@class EasyCam;
@class TRRenderLevel;
@class TR1Level;
@class TRRenderRoom;
@class TRPoserDocument;

@interface TRLevelView : NSOpenGLView
{
	IBOutlet TRPoserDocument *document;
	TRRenderLevel *level;
	TR1Level *originalLevel;
	NSArrayController *controller;
	
	EasyCam *camera;
	BOOL contextCreated;
	
	NSTimeInterval lastTime;
	
	MMatrix projectionMatrix;
	
	TRRenderRoom *cameraRoom;
	
	BOOL showsRoomNumber;
	BOOL rendersPortals;
	BOOL showsPosition;
	BOOL showsSelection;
	float cameraAngle;
	BOOL keepOn;
}

- (EasyCam *)camera;

- (void)setLevel:(TRRenderLevel *)someLevel;
- (TRRenderLevel *)level;

- (void)setShowsRoomNumber:(BOOL)yesorno;
- (BOOL)showsRoomNumber;

- (void)setShowsPortals:(BOOL)yesorno;
- (BOOL)showsPortals;

- (void)setShowsCameraPosition:(BOOL)yesOrNo;
- (BOOL)showsCameraPosition;

- (void)setShowsSelection:(BOOL)yesorno;
- (BOOL)showsSelection;

- (TRRenderRoom *)currentRoom;

@end
