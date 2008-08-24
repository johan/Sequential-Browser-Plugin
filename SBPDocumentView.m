#import "SBPDocumentView.h"

@implementation SBPDocumentView

#pragma mark WebDocumentView Protocol

- (void)setDataSource:(WebDataSource *)dataSource {}
- (void)dataSourceUpdated:(WebDataSource *)dataSource {}
- (void)setNeedsLayout:(BOOL)flag {}
- (void)layout {}
- (void)viewWillMoveToHostWindow:(NSWindow *)hostWindow {}
- (void)viewDidMoveToHostWindow {}

@end
