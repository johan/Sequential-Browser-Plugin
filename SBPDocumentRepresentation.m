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
#import "SBPDocumentRepresentation.h"

// Classes
#import "SBPController.h"

@implementation SBPDocumentRepresentation

#pragma mark Instance Methods

- (void)undisplayInWebView:(WebView *)webView
{
	if([webView goBack]) return;
	id const UIDelegate = [webView UIDelegate];
	if([UIDelegate respondsToSelector:@selector(webViewClose:)]) [UIDelegate webViewClose:webView];
}

#pragma mark WebDocumentRepresentation Protocol

- (void)setDataSource:(WebDataSource *)dataSource
{
	WebFrame *const frame = [dataSource webFrame];
	WebView *const webView = [frame webView];
	if(frame != [webView mainFrame]) return;
	if([[SBPController sharedController] openSequentialWithDataSource:dataSource inBackground:NO]) [self performSelector:@selector(undisplayInWebView:) withObject:webView afterDelay:0 inModes:[NSArray arrayWithObject:(NSString *)kCFRunLoopCommonModes]];
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
	return NSLocalizedStringFromTableInBundle(@"Opening in Sequential...", nil, [NSBundle bundleForClass:[self class]], nil);
}

@end
