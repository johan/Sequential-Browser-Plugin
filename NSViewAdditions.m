#import "NSViewAdditions.h"

@implementation NSView (SBPAdditions)

- (id)SBP_subviewOfClass:(Class)aClass
{
	if([self isKindOfClass:aClass]) return self;
	NSView *subview;
	NSEnumerator *const subviewEnum = [[self subviews] objectEnumerator];
	while((subview = [subviewEnum nextObject])) {
		NSView *const r = [subview SBP_subviewOfClass:aClass];
		if(r) return r;
	}
	return nil;
}

@end
