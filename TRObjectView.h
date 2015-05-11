//
//  TRObjectView.h
//  TRViewer
//
//  Created by Torsten on 08.06.06.
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

// A TRObjectView is a subclass of NSOpenGLView. It can display anything that implements the TRRendering protocol, currenlty raw meshes and rooms (with static meshes).

@interface TRObjectView : NSOpenGLView
{
	unsigned globalTexture;
	
	float angleX, angleY;
	float zoom;
	
	double midpoint[3];
	
	BOOL contextCreated;
	
	id <TRRendering> renderObject;
}

- (void)setRenderObject:(id <TRRendering>)object;
- (id <TRRendering>)renderObject;

- (void)setAngleX:(float)angle;
- (float)angleX;

- (void)setAngleY:(float)angle;
- (float)angleY;

- (void)setDistance:(float)distance;
- (float)distance;

@end
