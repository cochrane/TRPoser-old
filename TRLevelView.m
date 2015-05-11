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

#import "TRLevelView.h"
#import "EasyCam.h"
#import "TRRenderLevel.h"
#import "TRRenderRoom.h"
#import "TRRagdollInstance.h"
#import "TR1Room.h"
#import "TRRoomViewing.h"
#import "TR1Level.h"
#import "TRPoserDocument.h"
#import "GExtensions.h"
#import <OpenGL/gl.h>
#import <OpenGL/OpenGL.h>
#import "MFunctions.h"

@interface TRLevelView (Private)

- (void)_loadLevel;

@end

@implementation TRLevelView (Private)

- (void)_loadLevel;
{	
	[[self openGLContext] makeCurrentContext];
	
	MVec3 firstRoomMidpoint;
	TR1Room *firstRoom = [[originalLevel rooms] objectAtIndex:0];
	[firstRoom getMidpoint:&firstRoomMidpoint];
	NSPoint position = [firstRoom roomPosition];
	
	[level textureIDForPage:0];
	
	[self willChangeValueForKey:@"currentRoom"];
	cameraRoom = [level renderRoomForRoom:firstRoom];
	[self didChangeValueForKey:@"currentRoom"];
	
	float x, y, z;
	[camera getPositionX:&x y:&y z:&z];
	if (fabsf(x) < 0.0001f && fabsf(y) < 0.0001f && fabsf(z) < 0.0001f)
		[camera setDefaultLocationX:firstRoomMidpoint.x + position.x y:firstRoomMidpoint.y z:firstRoomMidpoint.z + position.y];
	
	[camera reset];
}

@end

@implementation TRLevelView

- (id)initWithFrame:(NSRect) frame
{
	NSOpenGLPixelFormatAttribute pixelFormatAttributes[] = 
	{
		NSOpenGLPFAWindow,
		NSOpenGLPFASingleRenderer,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAStencilSize, 8,
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
	
	contextCreated = NO;
	level = nil;
	camera = nil;
	
	showsRoomNumber = NO;
	rendersPortals = NO;
	
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
	glEnable(GL_CULL_FACE);
	glCullFace(GL_BACK);
	glFrontFace(GL_CW);
	glDepthFunc(GL_LEQUAL);
	
	lastTime = [NSDate timeIntervalSinceReferenceDate];
	
	[self willChangeValueForKey:@"camera"];
	
	camera = [[EasyCam alloc] init];
	
	[camera setDefaultRotationAroundX:0.0f y:0.0f];
	[camera setView:self];
	
	[self didChangeValueForKey:@"camera"];
	
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_DST_ALPHA);
	glDisable(GL_BLEND);
	
	[document finishLoading];
	if (level) [self _loadLevel];
	
	NSSize size = [self bounds].size;
	glViewport(0, 0, (GLsizei) size.width, (GLsizei) size.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(65.0, (GLfloat) size.width / (GLfloat) size.height, 0.1f, 30.0f); // TR and it's strange measurements, this should keep all rooms inside
	
	glGetFloatv(GL_PROJECTION_MATRIX, projectionMatrix.direct);
	
	glMatrixMode(GL_MODELVIEW);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self setNeedsDisplay:YES];
}

- (void)dealloc
{
	[camera release];
	[super dealloc];
}

- (EasyCam *)camera;
{
	return camera;
}

- (void)drawRect:(NSRect)aRect
{
	[[self openGLContext] makeCurrentContext];
	NSTimeInterval newTime = [NSDate timeIntervalSinceReferenceDate];
	NSTimeInterval delta = newTime - lastTime;
	lastTime = newTime;
	glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	// Render background pattern
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	gluOrtho2D(0.0, aRect.size.width, aRect.size.height, 0.0);
	
	glDisable(GL_CULL_FACE);
	glDisable(GL_DEPTH_TEST);
	glDisable(GL_TEXTURE_2D);

	glBegin(GL_QUADS);
	float x, y;
	BOOL white = YES;
	BOOL lineWhite = YES;
	for (x = 0.f; x < aRect.size.width; x += 50.f)
	{
		lineWhite = !lineWhite;
		white = lineWhite;
		for (y = 0.f; y < aRect.size.height; y += 50.f)
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
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_CULL_FACE);
	
	glPopMatrix();
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	[camera transformWithTimestep:delta];
	
	MVec3 camPoint;
	[camera getPositionX:&camPoint.x y:&camPoint.y z:&camPoint.z];
	
	if (![[cameraRoom room] isPointWithinRoom:camPoint])
	{
		[self willChangeValueForKey:@"currentRoom"];
		// First: Check among them rooms connected to the camera room
		BOOL foundRoom = false;
		unsigned numPortals = [[cameraRoom room] portalCount];
		TRRoomPortal *portals = [[cameraRoom room] portals];
		unsigned i;
		for (i = 0; i < numPortals; i++)
		{
			if ([portals[i].otherRoom isPointWithinRoom:camPoint])
			{
				cameraRoom = [level renderRoomForRoom:portals[i].otherRoom];
				foundRoom = true;
				break;
			}
		}
		
		if (!foundRoom)
		{
			// None of the neighbour rooms contain the object, so we check all rooms.
			cameraRoom = nil;
			NSEnumerator *roomsEnumerator = [[level rooms] objectEnumerator];
			id room;
			while (room = [roomsEnumerator nextObject])
			{
				if ([[room room] isPointWithinRoom:camPoint])
				{
					cameraRoom = room;
					break;
				}
			}
		}
		[self didChangeValueForKey:@"currentRoom"];
	}
	
	if (cameraRoom)
	{
		MPlane frustumPlanes[6];
		MGetOpenGLViewFrustumStoredProjectionMatrix(frustumPlanes, projectionMatrix);
		[[level rooms] makeObjectsPerformSelector:@selector(resetVisible)];
		// The first and last plane are near/far. Caring about them is just going to be trouble
		[cameraRoom recursiveFindVisibleRoomsWithinFrustum:&frustumPlanes[2] cameraPoint:camPoint comingFrom:nil];
	}
	else
		[[level rooms] makeObjectsPerformSelector:@selector(makeVisible)];
	
	// Render colored parts, and at the same time, prepare the ragdolls for rendering
	
	[[level rooms] makeObjectsPerformSelector:@selector(renderColoredInLevel)];
	
	glEnable(GL_TEXTURE_2D);
	
	[[level rooms] makeObjectsPerformSelector:@selector(renderTexturedInLevel)];
	
	glDisable(GL_ALPHA_TEST);
	glDepthMask(GL_FALSE);
	glEnable(GL_BLEND);
	
	[[level rooms] makeObjectsPerformSelector:@selector(renderAlphaInLevel)];
	if (rendersPortals) [[level rooms] makeObjectsPerformSelector:@selector(renderPortalsInLevel)];
		glDisable(GL_BLEND);
	
	// Render selected objects
	NSArray *selectedObjects = [document valueForKeyPath:@"ragdollController.selectedObjects"];
	if (showsSelection && [selectedObjects count] > 0)
	{
		glDisable(GL_DEPTH_TEST);
		glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
		glStencilFunc(GL_ALWAYS, 0x1, 0x1);
		glStencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE);
		NSEnumerator *enumerator = [selectedObjects objectEnumerator];
		NSDictionary *ragdollDict;
		while (ragdollDict = [enumerator nextObject])
			[[ragdollDict objectForKey:@"ragdoll"] renderEverythingInRoomWithScale:1.0f];
		
		glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
		glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
		glEnable(GL_DEPTH_TEST);
		
		glEnable(GL_STENCIL_TEST);
		glStencilFunc(GL_EQUAL, 0x0, 0x1);
		glPushMatrix();
		glDisable(GL_TEXTURE_2D);
		
		enumerator = [selectedObjects objectEnumerator];
		while (ragdollDict = [enumerator nextObject])
			[[ragdollDict objectForKey:@"ragdoll"] renderEverythingInRoomWithScale:1.2f];
		
		//glDisable(GL_STENCIL_TEST);
		glEnable(GL_TEXTURE_2D);
		glPopMatrix();
		
		glStencilFunc(GL_ALWAYS, 0, 0xFF);
	}
	
	glDepthMask(GL_TRUE);
	glEnable(GL_ALPHA_TEST);
	
	if (showsRoomNumber || showsPosition)
	{
		glLoadIdentity();
		glMatrixMode(GL_PROJECTION);
		glPushMatrix();
		glLoadIdentity();
		gluOrtho2D(0.0, aRect.size.width, 0.0, aRect.size.height);
		glMatrixMode(GL_MODELVIEW);
		
		
		NSString *displayString;
		if (showsRoomNumber && showsPosition)
		{	
			if (cameraRoom) displayString = [NSString stringWithFormat:NSLocalizedString(@"Room number: %@", @"number of currently rendered room"), [[cameraRoom room] numberInLevel]];
			else displayString = NSLocalizedString(@"Not in any room", @"camera outside of rooms");
			displayString = [displayString stringByAppendingString:@"\n"];
		//	displayString = [displayString stringByAppendingFormat:NSLocalizedString(@"X: %.2f Y: %.2f Z: %.2f", @"camera position"), camPoint.x, camPoint.y, camPoint.z];
			glTranslatef(10.0f, 34.0f, 0.0f);
		}
		else if (showsRoomNumber)
		{
			if (cameraRoom) displayString = [NSString stringWithFormat:NSLocalizedString(@"Room number: %@", @"number of currently rendered room"), [[cameraRoom room] numberInLevel]];
			else displayString = NSLocalizedString(@"Not in any room", @"camera outside of rooms");
			glTranslatef(10.0f, 10.0f, 0.0f);
		}
		else if (showsPosition)
		{
			//displayString = [NSString stringWithFormat:NSLocalizedString(@"X: %.2f Y: %.2f Z: %.2f", @"camera position"), camPoint.x, camPoint.y, camPoint.z];
			glTranslatef(10.0f, 10.0f, 0.0f);
		}
		[level writeText:displayString];
		//NSLog(displayString);
		
		glMatrixMode(GL_PROJECTION);
		glPopMatrix();
	}
	
	[[self openGLContext] flushBuffer];
}

- (void)reshape
{
	[[self openGLContext] makeCurrentContext];
	NSSize size = [self bounds].size;
	
	float scaleFactor = [[self window] userSpaceScaleFactor];
	
	size.width *= scaleFactor;
	size.height *= scaleFactor;
	
	glViewport(0, 0, (GLsizei) size.width, (GLsizei) size.height);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(65.0, (GLfloat) size.width / (GLfloat) size.height, 0.1f, 30.0f); // TR and it's strange measurements, this should keep all rooms inside
	
	float angleX = 65.0f * (size.width / size.height);
	cameraAngle = (angleX > 65.0f) ? angleX : 65.0f;
	
	glGetFloatv(GL_PROJECTION_MATRIX, projectionMatrix.direct);
	
	glMatrixMode(GL_MODELVIEW);
}

- (void)setLevel:(TRRenderLevel *)someLevel;
{
	if (level) return;
	[self willChangeValueForKey:@"level"];
	
	level = someLevel;
	originalLevel = [level originalLevel];
	if (contextCreated) [self _loadLevel];
	
	[self didChangeValueForKey:@"level"];
}
- (TRRenderLevel *)level;
{
	return level;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

//- (void)flagsChanged:(NSEvent *)theEvent
//{
//	[self keyDown:theEvent];
//}

- (BOOL)resignFirstResponder
{
	keepOn = NO;
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
	BOOL movement[8] = {NO, NO, NO, NO, NO, NO, NO, NO};
	BOOL faster = NO;
	keepOn = YES;
	lastTime = [NSDate timeIntervalSinceReferenceDate];
	
	[NSEvent startPeriodicEventsAfterDelay:0.0 withPeriod:1.0 / 60.0];
	while (keepOn)
	{
		switch ([theEvent type])
		{
			case NSKeyDown:
			
				switch ([[theEvent charactersIgnoringModifiers] characterAtIndex:0])
				{
					case 'w':
						movement[0] = YES;
					break;
					case 's':
						movement[1] = YES;
					break;
					case 'a':
						movement[2] = YES;
					break;
					case 'd':
						movement[3] = YES;
					break;
					case NSLeftArrowFunctionKey:
						movement[4] = YES;
					break;
					case NSRightArrowFunctionKey:
						movement[5] = YES;
					break;
					case NSUpArrowFunctionKey:
						movement[6] = YES;
					break;
					case NSDownArrowFunctionKey:
						movement[7] = YES;
					break;
				}
			
			break;
			case NSKeyUp:
			
				switch ([[theEvent charactersIgnoringModifiers] characterAtIndex:0])
				{
					case 'w':
						movement[0] = NO;
					break;
					case 's':
						movement[1] = NO;
					break;
					case 'a':
						movement[2] = NO;
					break;
					case 'd':
						movement[3] = NO;
					break;
					case NSLeftArrowFunctionKey:
						movement[4] = NO;
					break;
					case NSRightArrowFunctionKey:
						movement[5] = NO;
					break;
					case NSUpArrowFunctionKey:
						movement[6] = NO;
					break;
					case NSDownArrowFunctionKey:
						movement[7] = NO;
					break;
				}
				if (!movement[0] && !movement[1] && !movement[2] && !movement[3] && !movement[4] && !movement[5] && !movement[6] && !movement[7]) keepOn = NO;
			
			break;
			case NSPeriodic:
			break;
			case NSFlagsChanged:
				if ([theEvent modifierFlags] & NSShiftKeyMask) faster = YES;
				else faster = NO;
			break;
			default:
			break;
		}
		
		float speed = 1.0f;
		if (faster) speed = 5.0f;
		
		if (movement[0]) [camera setSpeedZ:speed];
		else if (movement[1]) [camera setSpeedZ:-speed];
		else [camera setSpeedZ:0.0f];
		
		if (movement[2]) [camera setSpeedX:speed];
		else if (movement[3]) [camera setSpeedX:-speed];
		else [camera setSpeedX:0.0f];
		
		if (movement[4]) [camera setRotationAroundY:-1.0f];
		else if (movement[5]) [camera setRotationAroundY:1.0f];
		else [camera setRotationAroundY:0.0f];
		
		if (movement[6]) [camera setRotationAroundX:1.0f];
		else if (movement[7]) [camera setRotationAroundX:-1.0f];
		else [camera setRotationAroundX:0.0f];
		
		[self setNeedsDisplay:YES];
		if (keepOn)
			theEvent = [[self window] nextEventMatchingMask:NSKeyDownMask | NSKeyUpMask | NSPeriodicMask/* | NSFlagsChangedMask*/];
	}
	[NSEvent stopPeriodicEvents];
}

- (void)cut:(id)sender
{
	[document cut:sender];
}

- (void)copy:(id)sender
{
	[document copy:sender];
}

- (void)paste:(id)sender
{
	[document paste:sender];
}

- (void)delete:(id)sender
{
	[document delete:sender];
}

- (void)selectAll:(id)sender;
{
	[document selectAll:sender];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	// This class knows nothing about this, or at least doesn't handle it.
	return [document validateUserInterfaceItem:anItem];
}

- (void)setShowsRoomNumber:(BOOL)yesorno;
{
	[self willChangeValueForKey:@"showsRoomNumber"];
	showsRoomNumber = yesorno;
	[self setNeedsDisplay:YES];
	[self didChangeValueForKey:@"showsRoomNumber"];
}
- (BOOL)showsRoomNumber;
{
	return showsRoomNumber;
}

- (void)setShowsPortals:(BOOL)yesorno;
{
	[self willChangeValueForKey:@"showsPortals"];
	rendersPortals = yesorno;
	[self setNeedsDisplay:YES];
	[self didChangeValueForKey:@"showsPortals"];
}
- (BOOL)showsPortals;
{
	return rendersPortals;
}

- (void)setShowsCameraPosition:(BOOL)yesOrNo;
{
	[self willChangeValueForKey:@"showsCameraPosition"];
	showsPosition = yesOrNo;
	[self setNeedsDisplay:YES];
	[self didChangeValueForKey:@"showsCameraPosition"];
}
- (BOOL)showsCameraPosition;
{
	return showsPosition;
}

- (void)setShowsSelection:(BOOL)yesOrNo;
{
	[self willChangeValueForKey:@"showsSelection"];
	showsSelection = yesOrNo;
	[self setNeedsDisplay:YES];
	[self didChangeValueForKey:@"showsSelection"];
}
- (BOOL)showsSelection;
{
	return showsSelection;
}

- (TRRenderRoom *)currentRoom;
{
	return cameraRoom;
}

- (BOOL)isOpaque
{
	return NO;
}

@end
