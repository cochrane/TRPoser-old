//
//  TRLevelTexture.h
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
#import "TR1Level.h"

@interface TR1Level (TRLevelTexture)

- (NSArray *)textureImages;

- (NSArray *)annotatedSpriteTextures;	// Annotated sprite textures returns an array of NSDictionarys with the keys:
										// image - NSImage representing the sprite
										// width - width of image
										// height - height of image
										// distanceTop - distance to top
										// distanceLeft
										// distanceRight
										// distanceBottom

@end
