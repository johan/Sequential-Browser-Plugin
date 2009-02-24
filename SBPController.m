/* Copyright © 2007-2008 The Sequential Project. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal with the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:
1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimers.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimers in the
   documentation and/or other materials provided with the distribution.
3. Neither the name of The Sequential Project nor the names of its
   contributors may be used to endorse or promote products derived from
   this Software without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
THE CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS WITH THE SOFTWARE. */
#import "SBPController.h"

// Classes
#import "SBPDocumentRepresentation.h"
#import "SBPDocumentView.h"

// Other Sources
#import "NSMenuAdditions.h"
#import "NSObjectAdditions.h"
#import "NSViewAdditions.h"

static NSArray *(*SBPOriginalContextMenuIMP)(id, SEL, WebView *, NSDictionary *, NSArray *);

@interface SBPController (Private)

+ (NSMenuItem *)_menuItemWithTitle:(NSString *)title representedObject:(id)anObject action:(SEL)action;

@end

@implementation SBPController

#pragma mark Class Methods

+ (id)sharedController
{
	static SBPController *c = nil;
	if(!c) c = [[self alloc] init];
	return c;
}
+ (NSArray *)supportedMIMETypes
{
	return [NSArray arrayWithObjects:@"application/pdf", @"application/x-pdf", @"application/acrobat", @"applications/vnd.pdf", @"text/pdf", @"text/x-pdf", @"application/postscript", @"image/tiff", @"image/raw", @"image/exr", @"image/bmp", @"image/x-bmp", @"image/x-windows-bmp", @"image/ms-bmp", @"image/x-ms-bmp", @"application/bmp", @"image/gif", @"image/jpeg", @"image/jpg", @"image/pjpeg", @"image/pict", @"image/x-pict", @"image/png", @"application/png", @"application/x-png", @"image/photoshop", @"image/x-photoshop", @"image/psd", @"application/photoshop", @"application/psd", nil];
}

#pragma mark Private Protocol

+ (NSMenuItem *)_menuItemWithTitle:(NSString *)title
                representedObject:(id)anObject
                action:(SEL)action
{
	NSMenuItem *const item = [[[NSMenuItem alloc] init] autorelease];
	[item setTitle:title];
	[item setRepresentedObject:anObject];
	[item setTarget:[self sharedController]];
	[item setAction:action];
	return item;
}

#pragma mark NSObject

+ (void)load
{
	if(floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_4) return;

	NSString *const ident = [[NSBundle mainBundle] bundleIdentifier];
	SEL viewSourceSelector = NULL;
	Class UIDelegateClass = Nil;
	NSBundle *const bundle = [NSBundle bundleForClass:self];

	if([@"com.apple.Safari" isEqualToString:ident]) {
		viewSourceSelector = @selector(viewSource:);
		UIDelegateClass = NSClassFromString(@"BrowserWebView");
	} else if([@"com.omnigroup.OmniWeb5" isEqualToString:ident]) {
		viewSourceSelector = @selector(viewSource:);
		UIDelegateClass = NSClassFromString(@"OWTab");
	} else if([@"jp.hmdt.shiira" isEqualToString:ident]) {
		viewSourceSelector = @selector(viewPageSourceAction:);
		UIDelegateClass = NSClassFromString(@"SRPageController");
	} else return;

	NSMenu *menu = nil;
	NSUInteger index = 0;
	if([[NSApp mainMenu] SBP_getMenu:&menu index:&index ofItemWithTarget:nil action:viewSourceSelector]) {
		NSMenuItem *const foregroundItem = [self _menuItemWithTitle:NSLocalizedStringFromTableInBundle(@"View with Sequential", nil, bundle, nil) representedObject:nil action:@selector(viewCurrentPageInSequentialInForeground:)];
		[foregroundItem setKeyEquivalent:@"u"];
		[foregroundItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask];
		[menu insertItem:foregroundItem atIndex:index];

		NSMenuItem *const backgroundItem = [self _menuItemWithTitle:NSLocalizedStringFromTableInBundle(@"View with Sequential in Background", nil, bundle, nil) representedObject:nil action:@selector(viewCurrentPageInSequentialInBackground:)];
		[backgroundItem setKeyEquivalent:@"u"];
		[backgroundItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask | NSShiftKeyMask];
		[backgroundItem setAlternate:YES];
		[menu insertItem:backgroundItem atIndex:index + 1];
	}

	NSString *MIMEType;
	NSEnumerator *const MIMETypeEnum = [[self supportedMIMETypes] objectEnumerator];
	while((MIMEType = [MIMETypeEnum nextObject])) [WebView registerViewClass:[SBPDocumentView class] representationClass:[SBPDocumentRepresentation class] forMIMEType:MIMEType];

	SBPOriginalContextMenuIMP = (NSArray *(*)(id, SEL, WebView *, NSDictionary *, NSArray *))[UIDelegateClass SBP_useImplementationFromClass:self forSelector:@selector(webView:contextMenuItemsForElement:defaultMenuItems:)];
}

#pragma mark Instance Methods

- (IBAction)viewCurrentPageInSequentialInForeground:(id)sender
{
	[self openSequentialWithCurrentPageInBackground:NO];
}
- (IBAction)viewCurrentPageInSequentialInBackground:(id)sender
{
	[self openSequentialWithCurrentPageInBackground:YES];
}
- (IBAction)viewLinkInSequentialInForeground:(id)sender
{
	if(![self openSequentialWithURL:[sender representedObject] inBackground:NO]) NSBeep();
}
- (IBAction)viewLinkInSequentialInBackground:(id)sender
{
	if(![self openSequentialWithURL:[sender representedObject] inBackground:YES]) NSBeep();
}

#pragma mark -

- (void)openSequentialWithCurrentPageInBackground:(BOOL)flag
{
	WebView *const webView = [[[NSApp mainWindow] contentView] SBP_subviewOfClass:[WebView class]];
	if(!webView) return NSBeep();
	WebFrame *const frame = [webView mainFrame];
	WebDataSource *dataSource = [frame dataSource];
	if(!dataSource) dataSource = [frame provisionalDataSource];
	if(![self openSequentialWithDataSource:dataSource inBackground:flag]) NSBeep();
}
- (BOOL)openSequentialWithDataSource:(WebDataSource *)dataSource
        inBackground:(BOOL)flag
{
	return [self openSequentialWithURL:[[dataSource request] URL] inBackground:flag];
}
- (BOOL)openSequentialWithURL:(NSURL *)aURL
        inBackground:(BOOL)flag
{
	if(!aURL) return NO;
	NSString *const appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.SequentialX.Sequential"];
	if(!appPath || ![[NSFileManager defaultManager] fileExistsAtPath:appPath isDirectory:NULL]) return NO;
	return [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:aURL] withAppBundleIdentifier:@"com.SequentialX.Sequential" options:(flag ? NSWorkspaceLaunchWithoutActivation : kNilOptions) additionalEventParamDescriptor:nil launchIdentifiers:NULL];
}

#pragma mark -

// These methods are moved to application classes.
- (NSArray *)webView:(WebView *)sender
             contextMenuItemsForElement:(NSDictionary *)element
             defaultMenuItems:(NSArray *)defaultMenuItems
{
	NSMutableArray *const items = [[(SBPOriginalContextMenuIMP ? SBPOriginalContextMenuIMP(self, _cmd, sender, element, defaultMenuItems) : defaultMenuItems) mutableCopy] autorelease];
	NSURL *const imageURL = [element objectForKey:WebElementImageURLKey];
	NSBundle *const bundle = [NSBundle bundleForClass:[SBPController class]];
	if(imageURL) {
		NSMenuItem *const item = [SBPController _menuItemWithTitle:NSLocalizedStringFromTableInBundle(@"Open Image with Sequential", nil, bundle, nil) representedObject:imageURL action:@selector(viewLinkInSequentialInForeground:)];
		NSMenu *const submenu = [[[NSMenu alloc] init] autorelease];
		[item setSubmenu:submenu];
		[items insertObject:item atIndex:0];
		[items insertObject:[NSMenuItem separatorItem] atIndex:1];

		[submenu addItem:[SBPController _menuItemWithTitle:NSLocalizedStringFromTableInBundle(@"in Foreground", nil, bundle, nil) representedObject:imageURL action:@selector(viewLinkInSequentialInForeground:)]];
		[submenu addItem:[SBPController _menuItemWithTitle:NSLocalizedStringFromTableInBundle(@"in Background", nil, bundle, nil) representedObject:imageURL action:@selector(viewLinkInSequentialInBackground:)]];
	}
	NSURL *const linkURL = [element objectForKey:WebElementLinkURLKey];
	if(linkURL) {
		NSMenuItem *const item = [SBPController _menuItemWithTitle:NSLocalizedStringFromTableInBundle(@"Open Link with Sequential", nil, bundle, nil) representedObject:linkURL action:@selector(viewLinkInSequentialInForeground:)];
		NSMenu *const submenu = [[[NSMenu alloc] init] autorelease];
		[item setSubmenu:submenu];
		[items insertObject:item atIndex:0];
		if(!imageURL) [items insertObject:[NSMenuItem separatorItem] atIndex:1];

		[submenu addItem:[SBPController _menuItemWithTitle:NSLocalizedStringFromTableInBundle(@"in Foreground", nil, bundle, nil) representedObject:linkURL action:@selector(viewLinkInSequentialInForeground:)]];
		[submenu addItem:[SBPController _menuItemWithTitle:NSLocalizedStringFromTableInBundle(@"in Background", nil, bundle, nil) representedObject:linkURL action:@selector(viewLinkInSequentialInBackground:)]];
	}
	return items;
}

#pragma mark NSMenuValidation Protocol

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL const action = [anItem action];
	if(@selector(viewCurrentPageInSequentialInForeground:) == action || @selector(viewCurrentPageInSequentialInBackground:) == action) return !![[[NSApp mainWindow] contentView] SBP_subviewOfClass:[WebView class]];
	return [self respondsToSelector:action];
}

@end
