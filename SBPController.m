#import "SBPController.h"

// Classes
#import "SBPDocumentRepresentation.h"
#import "SBPDocumentView.h"

// Other Sources
#import "NSMenuAdditions.h"
#import "NSObjectAdditions.h"
#import "NSViewAdditions.h"

static IMP SBPOriginalContextMenuIMP = NULL;

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
	return [NSArray arrayWithObjects:@"application/pdf", @"application/x-pdf", @"application/acrobat", @"applications/vnd.pdf", @"text/pdf", @"text/x-pdf", @"application/postscript", @"image/tiff", @"image/raw", @"image/exr", @"image/bmp", @"image/x-bmp", @"image/x-windows-bmp", @"image/ms-bmp", @"image/x-ms-bmp", @"application/bmp", @"image/gif", @"image/jpeg", @"image/jpg", @"image/pict", @"image/x-pict", @"image/png", @"application/png", @"application/x-png", @"image/photoshop", @"image/x-photoshop", @"image/psd", @"application/photoshop", @"application/psd", nil];
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
	NSMenu *menu = nil;
	NSUInteger index = 0;
	if([[NSApp mainMenu] SBP_getMenu:&menu index:&index ofItemWithTarget:nil action:@selector(viewSource:)]) {
		NSMenuItem *const foregroundItem = [self _menuItemWithTitle:NSLocalizedString(@"View in Sequential", @"Menu item label.") representedObject:nil action:@selector(viewCurrentPageInSequentialInForeground:)];
		[foregroundItem setKeyEquivalent:@"u"];
		[foregroundItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask];
		[menu insertItem:foregroundItem atIndex:index];

		NSMenuItem *const backgroundItem = [self _menuItemWithTitle:NSLocalizedString(@"View in Sequential in Background", @"Menu item label.") representedObject:nil action:@selector(viewCurrentPageInSequentialInBackground:)];
		[backgroundItem setKeyEquivalent:@"u"];
		[backgroundItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask | NSShiftKeyMask];
		[backgroundItem setAlternate:YES];
		[menu insertItem:backgroundItem atIndex:index + 1];
	}

	NSString *MIMEType;
	NSEnumerator *const MIMETypeEnum = [[self supportedMIMETypes] objectEnumerator];
	while((MIMEType = [MIMETypeEnum nextObject])) [WebView registerViewClass:[SBPDocumentView class] representationClass:[SBPDocumentRepresentation class] forMIMEType:MIMEType];

	Class class = NSClassFromString(@"BrowserWebView");
	if(!class) class = NSClassFromString(@"OWTab");
	SBPOriginalContextMenuIMP = [class SBP_useImplementationFromClass:self forSelector:@selector(webView:contextMenuItemsForElement:defaultMenuItems:)];
}

#pragma mark Instance Methods

- (IBAction)viewCurrentPageInSequentialInForeground:(id)sender
{
	if(![self openSequentialWithCurrentPageInBackground:NO]) NSBeep();
}
- (IBAction)viewCurrentPageInSequentialInBackground:(id)sender
{
	if(![self openSequentialWithCurrentPageInBackground:YES]) NSBeep();
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

- (BOOL)openSequentialWithCurrentPageInBackground:(BOOL)flag
{
	WebView *const webView = [[[NSApp mainWindow] contentView] SBP_subviewOfClass:[WebView class]];
	if(!webView) return NO;
	WebFrame *const frame = [webView mainFrame];
	WebDataSource *dataSource = [frame dataSource];
	if(!dataSource) dataSource = [frame provisionalDataSource];
	return [self openSequentialWithDataSource:dataSource inBackground:flag];
}
- (BOOL)openSequentialWithDataSource:(WebDataSource *)dataSource
        inBackground:(BOOL)flag
{
	return [self openSequentialWithURL:[[dataSource request] URL] inBackground:flag];
}
- (BOOL)openSequentialWithURL:(NSURL *)aURL
        inBackground:(BOOL)flag
{
	return aURL ? [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:aURL] withAppBundleIdentifier:@"com.SequentialX.Sequential" options:(flag ? NSWorkspaceLaunchWithoutActivation : kNilOptions) additionalEventParamDescriptor:nil launchIdentifiers:NULL] : NO;
}


#pragma mark NSMenuValidation Protocol

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL const action = [anItem action];
	if(@selector(viewInSequential:) == action) return [NSApp mainWindow] != nil;
	return [self respondsToSelector:action];
}

#pragma mark WebUIDelegate Protocol

- (NSArray *)webView:(WebView *)sender
             contextMenuItemsForElement:(NSDictionary *)element
             defaultMenuItems:(NSArray *)defaultMenuItems
{
	NSMutableArray *const items = [[(SBPOriginalContextMenuIMP ? SBPOriginalContextMenuIMP(self, _cmd, sender, element, defaultMenuItems) : defaultMenuItems) mutableCopy] autorelease];
	NSURL *const URL = [element objectForKey:WebElementLinkURLKey];
	if(!URL) return items;
	[items insertObject:[SBPController _menuItemWithTitle:NSLocalizedString(@"Open in Sequential", @"Contexual menu item label.") representedObject:URL action:@selector(viewLinkInSequentialInForeground:)] atIndex:0];
	[items insertObject:[SBPController _menuItemWithTitle:NSLocalizedString(@"Open in Sequential in Background", @"Contexual menu item label.") representedObject:URL action:@selector(viewLinkInSequentialInBackground:)] atIndex:1];
	[items insertObject:[NSMenuItem separatorItem] atIndex:2];
	return items;
}

@end
