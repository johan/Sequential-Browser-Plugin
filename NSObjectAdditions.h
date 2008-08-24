#import <Cocoa/Cocoa.h>

@interface NSObject (SBPAdditions)

+ (IMP)SBP_useImplementationFromClass:(Class)class forSelector:(SEL)aSel;

@end
