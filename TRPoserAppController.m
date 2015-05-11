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
 #import "TRPoserAppController.h"
#import "TR1Level.h"
#import "TRObjectView.h"
#import "TRPoserDocument.h"
#import "TRRenderLevel.h"

@interface TRPoserAppController (Private)

- (void)_levelLoadOpenPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;

@end

@implementation TRPoserAppController

- (id)init
{
	if (![super init]) return nil;
	
	loadedLevels = [[NSMutableDictionary alloc] init];
	frontLevel = nil;
	fakeLevel = [NSDictionary dictionaryWithObjectsAndKeys:[NSURL fileURLWithPath:@"/"], @"url", nil, @"level", nil, @"camera", [NSArray array], @"placedRagdolls", nil];
	[fakeLevel retain];
	
	return self;
}

- (void)dealloc
{
	[NSApp setDelegate:nil];
	[fakeLevel release];
	fakeLevel = nil;
	[loadedLevels release];
	loadedLevels = nil;
	frontLevel = nil;
	[super dealloc];
}

- (void)awakeFromNib
{	
	[objectPreview bind:@"renderObject" toObject:objectPreviewArray withKeyPath:@"selection.self" options:nil];
	
	[[NSDocumentController sharedDocumentController] addObserver:self forKeyPath:@"currentDocument" options:NSKeyValueObservingOptionNew context:NULL];
	[[NSDocumentController sharedDocumentController] addObserver:self forKeyPath:@"documents" options:NSKeyValueObservingOptionNew context:NULL];
}

- (IBAction)loadNewLevel:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:YES];
	NSArray *types = [NSArray arrayWithObjects:@"tr2", @"phd", @"tr4", nil];
	[openPanel setTitle:NSLocalizedString(@"Open environment level", @"Title for open panel for choosing the level that is used as environment.")];
	oldSavePanelDelegate = [openPanel delegate];
	[openPanel setDelegate:self];
	[openPanel beginSheetForDirectory:nil file:nil types:types modalForWindow:loadDocumentWindow modalDelegate:self didEndSelector:@selector(_levelLoadOpenPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)placeCurrentObject:(id)sender
{
	unsigned objectID = [[objectPreviewArray valueForKeyPath:@"selection.objectID"] unsignedIntValue];
	NSURL *levelURL = [levelPreviewArray valueForKeyPath:@"selection.url"];
	
	TRPoserDocument *frontDocument = [[NSDocumentController sharedDocumentController] currentDocument];
	if (frontDocument != nil)
		[frontDocument placeObjectWithID:objectID fromFile:levelURL];
}

- (TR1Level *)levelWithURL:(NSURL *)url;
{
	NSDictionary *resultDict = [loadedLevels objectForKey:url];
	if (!resultDict)
	{
		[self willChangeValueForKey:@"loadedLevels"];
		NSData *data = [NSData dataWithContentsOfURL:url];
		TR1Level *newLevel = [TR1Level levelWithData:data error:nil];
		TRRenderLevel *previewRenderLevel = [[TRRenderLevel alloc] initWithLevel:newLevel automaticallyPlaceItems:NO];
		resultDict = [NSDictionary dictionaryWithObjectsAndKeys:newLevel, @"level", url, @"url", previewRenderLevel, @"graphics", nil];
		[loadedLevels setObject:resultDict forKey:url];
		[previewRenderLevel release];
		[self didChangeValueForKey:@"loadedLevels"];
	}
	return [resultDict objectForKey:@"level"];
}
- (NSURL *)urlForLevel:(TR1Level *)level;
{
	NSEnumerator *levelEnumerator = [loadedLevels objectEnumerator];
	NSDictionary *levelDict;
	while (levelDict = [levelEnumerator nextObject])
	{
		if ([levelDict objectForKey:@"level"] == level) return [levelDict objectForKey:@"url"];
	}
	return nil;
}

- (id)frontLevel;
{
	return frontLevel;
}

- (NSArray *)loadedLevels;
{
	return [loadedLevels allValues];
}

- (void)newFrontLevel:(TRPoserDocument *)aDocument;
{
	if (![[documentsController content] containsObject:aDocument]) [documentsController addObject:aDocument];
	[documentsController setSelectedObjects:[NSArray arrayWithObject:aDocument]];
}

- (void)removeLevel:(TRPoserDocument *)document;
{
	[documentsController removeObject:document];
	if ([[documentsController content] count] == 0) [documentsController setSelectedObjects:[NSArray array]];
}

- (NSArray *)documents
{
	return [[NSDocumentController sharedDocumentController] documents];
}

- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename
{
	NSURL *levelURL = [NSURL fileURLWithPath:filename];
	if ([loadedLevels objectForKey:levelURL]) return NO;
	return YES;
}

@end

@implementation TRPoserAppController (Private)

- (void)_levelLoadOpenPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
{
	if (returnCode != NSOKButton) return;
	NSURL *levelURL = [panel URL];
	if (!levelURL) return;
	
	[panel setDelegate:oldSavePanelDelegate];
	
	[self levelWithURL:levelURL];
}

@end
