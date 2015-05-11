//
//  EasyCam.m
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

#import "MFunctions.h"
#import "EasyCam.h"

@implementation EasyCam

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		[self setDefaultLocationX:0.0 y:0.0 z:0.0];
		[self setDefaultRotationAroundX:0.0 y:0.0];
		[self reset];
	}
	return self;
}


- (void)reset:(id)should
{
	if ([should floatValue] > 0.5)
		[self reset];
}

- (void)reset
{
	rotAroundX = defaultRotX;
	rotAroundY = defaultRotY;
	eye.x = defaultLocation.x;
	eye.y = defaultLocation.y;
	eye.z = defaultLocation.z;
	up.x = 0.0;
	up.y = 1.0;
	up.z = 0.0;
	speed.x = 0.0;
	speed.y = 0.0;
	speed.z = 0.0;
	center.x = eye.x;
	center.y = eye.y;
	center.z = eye.z - 1.0;
}
- (void)setDefaultLocationX:(float)x y:(float)y z:(float)z
{
	defaultLocation.x = x;
	defaultLocation.y = y;
	defaultLocation.z = z;
}
- (void)setDefaultRotationAroundX:(float)x y:(float)y
{
	defaultRotX = x * (M_PI / 180.0f);
	defaultRotY = y * (M_PI / 180.0f);
}

- (void)transformWithTimestep:(NSTimeInterval)timedelta
{
	MVec3 diff;
	MVec3 speedTransformed;
	MQuaternion quat;
	if (!frozen)
	{
		[self willChangeValueForKey:@"positionX"];
		[self willChangeValueForKey:@"positionY"];
		[self willChangeValueForKey:@"positionZ"];
		
		[self willChangeValueForKey:@"rotation1"];
		[self willChangeValueForKey:@"rotation2"];
	}
	rotAroundX += rotAroundXspeed * timedelta;
	rotAroundY += rotAroundYspeed * timedelta;
	
//	if (rotAroundX > 1.0) rotAroundX = 1.0;
//	else if (rotAroundX < -1.0) rotAroundX = -1.0;
	
	speedTransformed.x = speed.x * timedelta;
	speedTransformed.y = speed.y * timedelta;
	speedTransformed.z = speed.z * timedelta;
	
	diff.x = 0.0;
	diff.y = 0.0;
	diff.z = -1.0;
	
	screenRight = MVecCross(diff, up);
	MVecNormalize(&screenRight);
	
	// I'm not exactly sure why I'm using quaternions here. Probably because it looked cool at the time.
	quat				= MQuaternionFromAxisAngle(screenRight, rotAroundX);
	center				= MQuaternionVecMultiply(&quat, &diff);
	speedTransformed	= MQuaternionVecMultiply(&quat, &speedTransformed);
	quat				= MQuaternionFromAxisAngle(up, rotAroundY);
	center				= MQuaternionVecMultiply(&quat, &center);
	speedTransformed	= MQuaternionVecMultiply(&quat, &speedTransformed);
	
	eye.x += speedTransformed.x;
	eye.y += speedTransformed.y;
	eye.z += speedTransformed.z;
	
	// Mainly for particles
	screenUp = MVecCross(screenRight, center);
	MVecNormalize(&screenUp);
	
	center.x += eye.x;
	center.y += eye.y;
	center.z += eye.z;
	
	direction.x = center.x - eye.x;
	direction.y = center.y - eye.y;
	direction.z = center.z - eye.z;
	
	gluLookAt(eye.x, eye.y, eye.z,
				center.x, center.y, center.z,
				-up.x, -up.y, -up.z);
	
	if (!frozen)
	{
		[self didChangeValueForKey:@"positionX"];
		[self didChangeValueForKey:@"positionY"];
		[self didChangeValueForKey:@"positionZ"];
		
		[self didChangeValueForKey:@"rotation1"];
		[self didChangeValueForKey:@"rotation2"];
	}
}

- (void)setRotationAroundX:(float)rot
{
	if (frozen) return;
	rotAroundXspeed = rot;
}
- (void)setRotationAroundY:(float)rot
{
	if (frozen) return;
	rotAroundYspeed = rot;
}

- (void)setSpeedX:(float)somespeed
{
	if (frozen) return;
	speed.x = somespeed * -1.0f;
}
- (void)setSpeedY:(float)somespeed
{
	if (frozen) return;
	speed.y = somespeed * -1.0f;
}
- (void)setSpeedZ:(float)somespeed
{
	if (frozen) return;
	speed.z = somespeed * -1.0f;
}

- (void)getPositionX:(float *)x y:(float *)y z:(float *)z
{
	if (x != NULL) *x = eye.x;
	if (y != NULL) *y = eye.y;
	if (z != NULL) *z = eye.z;
}

- (MVec3)screenUp
{
	return screenUp;
}
- (MVec3)screenRight
{
	return screenRight;
}

- (float)positionX;
{
	return eye.x;
}
- (void)setPositionX:(float)position;
{
	[self willChangeValueForKey:@"positionX"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedX"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedY"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedZ"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"rotationAroundX"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"rotationAroundY"];
	
	float diff = position - eye.x;
	eye.x += diff;
	center.x += diff;
	
	[self didChangeValueForKey:@"positionX"];

	[view setNeedsDisplay:YES];
}
- (float)positionY;
{
	return eye.y;
}
- (void)setPositionY:(float)position;
{
	[self willChangeValueForKey:@"positionY"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedX"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedY"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedZ"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"rotationAroundX"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"rotationAroundY"];
	
	float diff = position - eye.y;
	eye.y += diff;
	center.y += diff;
	
	[self didChangeValueForKey:@"positionY"];
	
	[view setNeedsDisplay:YES];
}
- (float)positionZ;
{
	return eye.z;
}
- (void)setPositionZ:(float)position;
{
	[self willChangeValueForKey:@"positionZ"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedX"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedY"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedZ"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"rotationAroundX"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"rotationAroundY"];
	
	float diff = position - eye.z;
	eye.z += diff;
	center.z += diff;
	
	[self didChangeValueForKey:@"positionZ"];
	
	[view setNeedsDisplay:YES];
}

- (void)setRotation1:(float)absoluteRotation;
{
	[self willChangeValueForKey:@"rotation1"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedX"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedY"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedZ"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"rotationAroundX"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"rotationAroundY"];
	
	rotAroundY = absoluteRotation * (M_PI / 180.0f);
	
	if (fabsf(rotAroundY) > M_PI) rotAroundY = fmodf(rotAroundY, M_PI);
	
	[self didChangeValueForKey:@"rotation1"];
	
	[view setNeedsDisplay:YES];
}
- (float)rotation1;
{
	return rotAroundY * (180.0f / M_PI);
}

- (void)setRotation2:(float)absoluteRotation;
{
	[self willChangeValueForKey:@"rotation2"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedX"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedY"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedZ"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"rotationAroundX"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"rotationAroundY"];
	
	rotAroundX = absoluteRotation * (M_PI / 180.0f);
	
	if (fabsf(rotAroundX) > M_PI) rotAroundX = fmodf(rotAroundX, M_PI);
	
	[self didChangeValueForKey:@"rotation2"];
	
	[view setNeedsDisplay:YES];
}
- (float)rotation2;
{
	return rotAroundX * (180.0f / M_PI);
}

- (void)setFrozen:(BOOL)freeze;
{
	[self willChangeValueForKey:@"frozen"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedX"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedY"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"speedZ"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"rotationAroundX"];
	[self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"rotationAroundY"];
	
	frozen = freeze;
	
	[self didChangeValueForKey:@"frozen"];
	
	[view setNeedsDisplay:YES];
}
- (BOOL)frozen;
{
	return frozen;
}

- (float)directionX;
{
	return direction.x;
}
- (float)directionY;
{
	return direction.y;
}
- (float)directionZ;
{
	return direction.z;
}

- (void)setView:(NSView *)aView;
{
	view = aView;
}
- (NSView *)view;
{
	return view;
}

@end
