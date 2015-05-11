//
//  EasyCam.h
//  Snow
//
//  Created by Torsten on 22.08.05.
//  Copyright 2005 Ferroequinologist.de. All rights reserved.
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

// An old camera I wrote once for a different project. Needs major improvements (for example, it uses it's own math library that is distinct from the one used in the rest of the application). Still, it works, and as long as it continues to do so, I'm unlikely to really do much with it.

@interface EasyCam : NSObject
{

/*	The idea behind this camera implementation: When the mouse is moved, we get a translation on the screen, a vector. The cross product between the vector and the cameras direction vector is the axis to rotate about, while the angle can be found out by using the camera direction vector and the new camera direction vector (= camera direction + camera movement). This can be directly used for glRotate, so everything is fine (as long as we don't use rotation around the z axis)	*/

	float rotAroundXspeed, rotAroundYspeed;
	float rotAroundX, rotAroundY;
	
	MVec3 speed;
	
	MVec3 eye;
	MVec3 center;
	MVec3 up;
	
	MVec3 defaultLocation;
	float defaultRotX, defaultRotY;
	
	MVec3 screenUp;
	MVec3 screenRight;
	MVec3 direction;
	
	NSView *view;
	
	BOOL frozen;
}

- (void)reset;
- (void)reset:(id)should;
- (void)setDefaultLocationX:(float)x y:(float)y z:(float)z;
- (void)setDefaultRotationAroundX:(float)x y:(float)y;

- (void)setRotationAroundX:(float)rot;
- (void)setRotationAroundY:(float)rot;

- (void)setSpeedX:(float)speed;
- (void)setSpeedY:(float)speed;
- (void)setSpeedZ:(float)speed;

- (void)getPositionX:(float *)x y:(float *)y z:(float *)z;

- (void)transformWithTimestep:(NSTimeInterval)timedelta;

- (MVec3)screenUp;
- (MVec3)screenRight;

- (float)positionX;
- (void)setPositionX:(float)position;
- (float)positionY;
- (void)setPositionY:(float)position;
- (float)positionZ;
- (void)setPositionZ:(float)position;

- (void)setRotation1:(float)absoluteRotation;
- (float)rotation1;

- (void)setRotation2:(float)absoluteRotation;
- (float)rotation2;

- (void)setFrozen:(BOOL)freeze;
- (BOOL)frozen;

- (float)directionX;
- (float)directionY;
- (float)directionZ;

- (void)setView:(NSView *)aView;
- (NSView *)view;

@end
