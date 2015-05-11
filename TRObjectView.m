//
//  TRObjectView.m
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

#import "TRObjectView.h"
#import <OpenGL/gl.h>
#import <OpenGL/OpenGL.h>

@interface TRObjectView (Private)

- (void)_setupNewObject;

@end

@implementation TRObjectView (Private)

- (void)_setupNewObject;
{
	if (!contextCreated || !renderObject) return;
	
	[[self openGLContext] makeCurrentContext];
	
	MVec3 vMidpoint;
	[renderObject getMidpoint:&vMidpoint];
	
	midpoint[0] = (double) vMidpoint.x;
	midpoint[1] = (double) vMidpoint.y;
	midpoint[2] = (double) vMidpoint.z;
	
	[renderObject generateAlphaDisplayList];
	[renderObject generateColoredDisplayList];
	[renderObject generateTexturedDisplayList];
	
	if ([renderObject respondsToSelector:@selector(setView:)]) [renderObject setView:self];
	
	[self setNeedsDisplay:YES];
}

@end

@implementation TRObjectView

- (id)initWithFrame:(NSRect) frame
{
	NSOpenGLPixelFormatAttribute pixelFormatAttributes[] = 
	{
		NSOpenGLPFAWindow,
		NSOpenGLPFASingleRenderer,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		/*NSOpenGLPFAScreenMask,
		CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),*/
		0
	};

	long swap = 1;

	NSOpenGLPixelFormat* windowPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelFormatAttributes]; 
	if (!windowPixelFormat)
	{
		[self release];
		return nil;
	}
	
	if (![super initWithFrame:frame pixelFormat:windowPixelFormat])
	{
		[self release];
		return nil;
	}
	[[self openGLContext] setValues:&swap forParameter:kCGLCPSwapInterval];
	[windowPixelFormat release];
	
	renderObject = nil;
	angleX = angleY = 0.0f;
	zoom = 1.25;
	contextCreated = NO;
	
	return self;
}

- (void)prepareOpenGL
{
	if (contextCreated) return;
	contextCreated = YES;
	
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glShadeModel(GL_SMOOTH);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_TEXTURE_2D);
		
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glAlphaFunc(GL_GREATER, 0.5f);
	glColor3f(1.0f, 1.0f, 1.0f);
	glEnable(GL_ALPHA_TEST);
	glCullFace(GL_BACK);
	glFrontFace(GL_CCW);
	glBlendFunc(GL_SRC_ALPHA, GL_DST_ALPHA);
	
	if (renderObject) [self _setupNewObject];

	NSSize size = [self bounds].size;
	glViewport(0, 0, (GLsizei) size.width, (GLsizei) size.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(65.0, (GLfloat) size.width / (GLfloat) size.height, 0.1f, 30.0f); // TR and it's strange measurements, this should keep all rooms inside
}

- (void)drawRect:(NSRect)rect
{	
	[[self openGLContext] makeCurrentContext];
	
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	
	// Render background pattern
	glMatrixMode(GL_PROJECTION);
	
	glPushMatrix();
	
	glLoadIdentity();
	gluOrtho2D(0.0, rect.size.width, rect.size.height, 0.0);

	glDepthMask(GL_FALSE);
	glBegin(GL_QUADS);
	float x, y;
	BOOL white = YES;
	BOOL lineWhite = YES;
	for (x = 0.f; x < rect.size.width; x += 50.f)
	{
		lineWhite = !lineWhite;
		white = lineWhite;
		for (y = 0.f; y < rect.size.height; y += 50.f)
		{
			if (white)
			{
				glColor3f(1.0f, 1.0f, 1.0f);
				white = NO;
			}
			else
			{
				glColor3f(0.75f, 0.75f, 0.75f);
				white = YES;
			}
			
			glVertex2f(x, y);
			glVertex2f(x + 50.0f, y);
			glVertex2f(x + 50.0f, y + 50.0f);
			glVertex2f(x, y + 50.0f);
		}
	}
	glEnd();
	glDepthMask(GL_TRUE);
	
	glPopMatrix();
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	if (!renderObject)
	{
		[[self openGLContext] flushBuffer];
		return;
	}

	glColor4f(1.0, 1.0, 1.0, 1.0);
	
	gluLookAt(midpoint[0], midpoint[1], midpoint[2] - zoom, midpoint[0], midpoint[1], midpoint[2], 0.0, -1.0, 0.0);
	glRotatef(angleX, 1.0, 0.0, 0.0);
	glRotatef(angleY, 0.0, 1.0, 0.0);
//	glTranslatef(0.0, 0.0, zoom);
	
	glEnable(GL_ALPHA_TEST);

	[renderObject renderColoredParts];

	glEnable(GL_TEXTURE_2D);
	
	[renderObject renderTexturedParts];
	
	glDisable(GL_ALPHA_TEST);
	glDepthMask(GL_FALSE);
	glEnable(GL_BLEND);
	
	[renderObject renderAlphaParts];
	
	glDisable(GL_BLEND);
	glDisable(GL_TEXTURE_2D);
	glDepthMask(GL_TRUE);
	
	glLoadIdentity();
	
	[[self openGLContext] flushBuffer];
}

- (void)reshape
{
	[[self openGLContext] makeCurrentContext];

	NSSize size = [self bounds].size;
	glViewport(0, 0, (GLsizei) size.width, (GLsizei) size.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(65.0, (GLfloat) size.width / (GLfloat) size.height, 0.1f, 30.0f); // TR and it's strange measurements, this should keep all rooms inside
	glMatrixMode(GL_MODELVIEW);
}

- (void)setRenderObject:(id <TRRendering>)object;
{
	[self willChangeValueForKey:@"renderObject"];
	if (renderObject) [renderObject release];
	renderObject = [object retain];
	if (contextCreated) [self _setupNewObject];
	[self setNeedsDisplay:YES];
	[self didChangeValueForKey:@"renderObject"];
}
- (id <TRRendering>)renderObject;
{
	return renderObject;
}

- (void)setAngleX:(float)angle;
{
	[self willChangeValueForKey:@"angleX"];
	angleX = angle;
	[self setNeedsDisplay:YES];
	[self didChangeValueForKey:@"angleX"];
}
- (float)angleX;
{
	return angleX;
}

- (void)setAngleY:(float)angle;
{
	[self willChangeValueForKey:@"angleY"];
	angleY = angle;
	[self setNeedsDisplay:YES];
	[self didChangeValueForKey:@"angleY"];
}
- (float)angleY;
{
	return angleY;
}

- (void)setDistance:(float)distance;
{
	[self willChangeValueForKey:@"distance"];
	zoom = distance;
	[self setNeedsDisplay:YES];
	[self didChangeValueForKey:@"distance"];
}
- (float)distance;
{
	return zoom;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}
- (void)keyDown:(NSEvent *)theEvent
{
	BOOL zoomingIn = NO;
	BOOL zoomingOut = NO;
	BOOL turningLeft = NO;
	BOOL turningRight = NO;
	BOOL turningUp = NO;
	BOOL turningDown = NO;
	BOOL keepOn = YES;
	
	NSTimeInterval lastTime = [NSDate timeIntervalSinceReferenceDate];
	
	[NSEvent startPeriodicEventsAfterDelay:0.0 withPeriod:1.0 / 60.0];
	while (keepOn)
	{
		NSTimeInterval newTime = [NSDate timeIntervalSinceReferenceDate];
		NSTimeInterval delta = newTime - lastTime;
		lastTime = newTime;
		switch ([theEvent type])
		{
			case NSKeyDown:
			
				switch ([[theEvent charactersIgnoringModifiers] characterAtIndex:0])
				{
					case NSPageUpFunctionKey:
						zoomingIn = YES;
					break;
					case NSPageDownFunctionKey:
						zoomingOut = YES;
					break;
					case NSLeftArrowFunctionKey:
						turningLeft = YES;
					break;
					case NSRightArrowFunctionKey:
						turningRight = YES;
					break;
					case NSUpArrowFunctionKey:
						turningUp = YES;
					break;
					case NSDownArrowFunctionKey:
						turningDown = YES;
					break;
				}
			
			break;
			case NSKeyUp:
			
				switch ([[theEvent charactersIgnoringModifiers] characterAtIndex:0])
				{
					case NSPageUpFunctionKey:
						zoomingIn = NO;
					break;
					case NSPageDownFunctionKey:
						zoomingOut = NO;
					break;
					case NSLeftArrowFunctionKey:
						turningLeft = NO;
					break;
					case NSRightArrowFunctionKey:
						turningRight = NO;
					break;
					case NSUpArrowFunctionKey:
						turningUp = NO;
					break;
					case NSDownArrowFunctionKey:
						turningDown = NO;
					break;
				}
				if (!zoomingIn && !zoomingOut && !turningLeft && !turningRight && !turningUp && !turningDown) keepOn = NO;
			
			break;
			case NSPeriodic:
			break;
			default:
			break;
		}
		
		if (zoomingIn) zoom += 0.5f * delta;
		else if (zoomingOut) zoom -= 0.5f * delta;
		if (turningUp) angleX += delta * 30.0f;
		else if (turningDown) angleX -= delta * 30.0f;
		if (turningLeft) angleY += delta * 30.0f;
		else if (turningRight) angleY -= delta * 30.0f;
		
		[self setNeedsDisplay:YES];
		if (keepOn)
			theEvent = [[self window] nextEventMatchingMask:NSKeyDownMask | NSKeyUpMask | NSPeriodicMask];
	}
	[NSEvent stopPeriodicEvents];
}

@end
