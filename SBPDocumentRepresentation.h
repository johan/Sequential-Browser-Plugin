#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface SBPDocumentRepresentation : NSObject <WebDocumentRepresentation>

- (void)undisplayInWebView:(WebView *)webView;

@end
