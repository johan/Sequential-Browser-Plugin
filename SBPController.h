#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface SBPController : NSObject

+ (id)sharedController;
+ (NSArray *)supportedMIMETypes;

- (IBAction)viewCurrentPageInSequentialInForeground:(id)sender;
- (IBAction)viewCurrentPageInSequentialInBackground:(id)sender;
- (IBAction)viewLinkInSequentialInForeground:(id)sender;
- (IBAction)viewLinkInSequentialInBackground:(id)sender;

- (BOOL)openSequentialWithCurrentPageInBackground:(BOOL)flag;
- (BOOL)openSequentialWithDataSource:(WebDataSource *)dataSource inBackground:(BOOL)flag;
- (BOOL)openSequentialWithURL:(NSURL *)aURL inBackground:(BOOL)flag;

@end
