/* Copyright © 2007-2008, The Sequential Project
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the the Sequential Project nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE SEQUENTIAL PROJECT ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE SEQUENTIAL PROJECT BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
#import "SBPController.h"

// Classes
#import "SBPDocumentRepresentation.h"
#import "SBPDocumentView.h"

// Other Sources
#import "NSMenuAdditions.h"
#import "NSObjectAdditions.h"
#import "NSViewAdditions.h"

static Class SBPUIDelegateClass;
static NSArray *(*SBPUIDelegateClass_webView_contextMenuItemsForElement_defaultMenuItems)(id, SEL, WebView *, NSDictionary *, NSArray *);

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
	return [NSArray arrayWithObjects:@"application/postscript", @"image/tiff", @"image/raw", @"image/exr", @"image/bmp", @"image/x-bmp", @"image/x-windows-bmp", @"image/ms-bmp", @"image/x-ms-bmp", @"application/bmp", @"image/gif", @"image/jpeg", @"image/jpg", @"image/pjpeg", @"image/pict", @"image/x-pict", @"image/png", @"application/png", @"application/x-png", @"image/photoshop", @"image/x-photoshop", @"image/psd", @"application/photoshop", @"application/psd", nil];
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
	NSBundle *const bundle = [NSBundle bundleForClass:self];

	if([@"com.apple.Safari" isEqualToString:ident]) {
		viewSourceSelector = @selector(viewSource:);
		SBPUIDelegateClass = NSClassFromString(@"BrowserWebView");
	} else if([@"com.omnigroup.OmniWeb5" isEqualToString:ident]) {
		viewSourceSelector = @selector(viewSource:);
		SBPUIDelegateClass = NSClassFromString(@"OWTab");
	} else if([@"jp.hmdt.shiira" isEqualToString:ident]) {
		viewSourceSelector = @selector(viewPageSourceAction:);
		SBPUIDelegateClass = NSClassFromString(@"SRPageController");
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

	SBPUIDelegateClass_webView_contextMenuItemsForElement_defaultMenuItems = (NSArray *(*)(id, SEL, WebView *, NSDictionary *, NSArray *))[SBPUIDelegateClass SBP_useImplementationFromClass:self forSelector:@selector(webView:contextMenuItemsForElement:defaultMenuItems:)];
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
	NSMutableArray *const items = [[([SBPUIDelegateClass instancesRespondToSelector:@selector(webView:contextMenuItemsForElement:defaultMenuItems:)] ? SBPUIDelegateClass_webView_contextMenuItemsForElement_defaultMenuItems(self, _cmd, sender, element, defaultMenuItems) : defaultMenuItems) mutableCopy] autorelease];
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
