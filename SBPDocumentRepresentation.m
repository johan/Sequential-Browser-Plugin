#import "SBPDocumentRepresentation.h"

// Classes
#import "SBPController.h"


@implementation SBPDocumentRepresentation

#pragma mark NSObject

+ (void)initialize
{
}

#pragma mark Instance Methods

- (void)undisplayInWebView:(WebView *)webView
{
	if([webView goBack]) return;
	id const UIDelegate = [webView UIDelegate];
	if([UIDelegate respondsToSelector:@selector(webViewClose:)]) [UIDelegate webViewClose:webView];
	else [[webView window] close];
}

#pragma mark WebDocumentRepresentation Protocol

- (void)setDataSource:(WebDataSource *)dataSource
{
	WebView *const webView = [[dataSource webFrame] webView];
	NSWindow *const hostWindow = [webView hostWindow];
	NSEvent *const currentEvent = [(hostWindow ? hostWindow : [webView window]) currentEvent];
	if([[SBPController sharedController] openSequentialWithDataSource:dataSource inBackground:!!([currentEvent modifierFlags] & NSShiftKeyMask)]) [self performSelector:@selector(undisplayInWebView:) withObject:webView afterDelay:0 inModes:[NSArray arrayWithObject:(NSString *)kCFRunLoopCommonModes]];
}
- (void)receivedData:(NSData *)data withDataSource:(WebDataSource *)dataSource {}
- (void)receivedError:(NSError *)error withDataSource:(WebDataSource *)dataSource {}
- (void)finishedLoadingWithDataSource:(WebDataSource *)dataSource {}
- (BOOL)canProvideDocumentSource
{
	return NO;
}
- (NSString *)documentSource
{
	return nil;
}
- (NSString *)title
{
	return @"";
}

@end
