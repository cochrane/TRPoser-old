/* TRPoserAppController */
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

@class TR1Level;
@class TRObjectView;
@class TRPoserDocument;

@interface TRPoserAppController : NSObject
{
    IBOutlet NSArrayController *levelPreviewArray;
    IBOutlet TRObjectView *objectPreview;
    IBOutlet NSArrayController *objectPreviewArray;
	IBOutlet NSArrayController *documentsController;
	IBOutlet NSWindow *loadDocumentWindow;
	
	NSMutableDictionary *loadedLevels;
	id frontLevel;
	id oldSavePanelDelegate;
	
	NSDictionary *fakeLevel;
}
- (IBAction)loadNewLevel:(id)sender;
- (IBAction)placeCurrentObject:(id)sender;

- (TR1Level *)levelWithURL:(NSURL *)level;
- (NSURL *)urlForLevel:(TR1Level *)level;

- (id)frontLevel;

- (NSArray *)loadedLevels;

- (void)newFrontLevel:(TRPoserDocument *)document;
- (void)removeLevel:(TRPoserDocument *)document;

- (NSArray *)documents;

@end
