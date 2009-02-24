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
#import "SBPDocumentView.h"

@implementation SBPDocumentView

#pragma mark WebDocumentView Protocol

- (void)setDataSource:(WebDataSource *)dataSource {}
- (void)dataSourceUpdated:(WebDataSource *)dataSource {}
- (void)setNeedsLayout:(BOOL)flag {}
- (void)layout
{
	[self setFrame:[[self superview] bounds]];
}
- (void)viewWillMoveToHostWindow:(NSWindow *)hostWindow {}
- (void)viewDidMoveToHostWindow {}

#pragma mark NSView

- (BOOL)isOpaque
{
	return YES;
}
- (void)drawRect:(NSRect)aRect
{
	[[NSColor whiteColor] set];
	NSRectFill(aRect);

	NSAttributedString *const str = [[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTableInBundle(@"Opening in Sequential...", nil, [NSBundle bundleForClass:[self class]], nil) attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:20.0f], NSFontAttributeName, [NSColor grayColor], NSForegroundColorAttributeName, nil]] autorelease];
	NSSize const s = [str size];
	NSRect const b = [self bounds];
	[str drawInRect:NSInsetRect(b, NSWidth(b) / 2.0f - s.width / 2.0f, NSHeight(b) / 2.0f - s.height / 2.0f)];
}

@end
