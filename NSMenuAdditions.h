#import <Cocoa/Cocoa.h>

@interface NSMenu (SBPAdditions)

- (BOOL)SBP_getMenu:(out NSMenu **)outMenu index:(out NSUInteger *)outIndex ofItemWithTarget:(id)target action:(SEL)aSEL;

@end
