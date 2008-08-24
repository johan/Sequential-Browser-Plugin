#import "NSObjectAdditions.h"
#import <objc/runtime.h>

@implementation NSObject (SBPAdditions)

+ (IMP)SBP_useImplementationFromClass:(Class)class
       forSelector:(SEL)aSel
{
	Method newMethod = class_getInstanceMethod(class, aSel);
	return newMethod ? class_replaceMethod(self, aSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)) : NULL;
}

@end
