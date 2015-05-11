//
//  TRLevelTexture.m
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

#import "TRLevelTexture.h"
#import "NSImage_SubImage.h"

@implementation TR1Level (TRLevelTexture)

- (NSArray *)textureImages;
{
	unsigned i;
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:numTexturePages];
	for (i = 0; i < [self texturePageCount]; i++)
	{
		unsigned char *data[1];
		data[0] = [self texturePageAtIndex:i];
		NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:data pixelsWide:256 pixelsHigh:256 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bitmapFormat:NSAlphaFirstBitmapFormat | NSAlphaNonpremultipliedBitmapFormat bytesPerRow:0 bitsPerPixel:0];
		if (!rep)
		{
			NSLog(@"could not load image");
			return nil;
		}
		
		NSImage *texturePage = [[NSImage alloc] initWithSize:NSMakeSize(256.0, 256.0)];
		[texturePage addRepresentation:rep];
		[rep release];
		[result addObject:texturePage];
		[texturePage release];
	}
	
	NSArray *staticResult = [[result copy] autorelease];
	[result release];
	
	return staticResult;
}

- (NSArray *)annotatedSpriteTextures;
{
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:numSprites];
	
	NSArray *textureImages = [self textureImages];
	
	unsigned i;
	for (i = 0; i < [textureImages count]; i++)	
		[[textureImages objectAtIndex:i] setFlipped:YES];
	
	for (i = 0; i < numSprites; i++)
	{
		NSRect imageRect;
		imageRect.origin.x = (float) sprites[i].coords[0][0];
		imageRect.origin.y = (float) sprites[i].coords[0][1];
		
		imageRect.size.height = (float) (sprites[i].coords[2][1] - sprites[i].coords[0][1]) + 1.0f;
		imageRect.size.width = (float) (sprites[i].coords[2][0] - sprites[i].coords[0][0]) + 1.0f;
		
		NSImage *image = [[textureImages objectAtIndex:sprites[i].texturePageNumber] subImageWithRect:imageRect];
		
		NSNumber *width = [NSNumber numberWithUnsignedInt:imageRect.size.width];
		NSNumber *height = [NSNumber numberWithUnsignedInt:imageRect.size.height];
		NSNumber *distanceLeft = [NSNumber numberWithInt:sprites[i].distanceToEdge[0]];
		NSNumber *distanceTop = [NSNumber numberWithInt:sprites[i].distanceToEdge[1]];
		NSNumber *distanceRight = [NSNumber numberWithInt:sprites[i].distanceToEdge[2]];
		NSNumber *distanceBottom = [NSNumber numberWithInt:sprites[i].distanceToEdge[3]];
		
		NSNumber *index = [NSNumber numberWithUnsignedInt:i];
		
		NSDictionary *spriteDictionary = [NSDictionary dictionaryWithObjectsAndKeys:image, @"image", width, @"width", height, @"height", distanceTop, @"distanceTop", distanceLeft, @"distanceLeft", distanceRight, @"distanceRight", distanceBottom, @"distanceBottom", index, @"index", nil];
		
		[array addObject:spriteDictionary];
	}
	
	NSArray *result = [array copy];
	[array release];
	[result autorelease];
	return result;
}

@end
