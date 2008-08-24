#import "NSMenuAdditions.h"

@implementation NSMenu (SBPAdditions)

- (BOOL)SBP_getMenu:(out NSMenu **)outMenu
        index:(out NSUInteger *)outIndex
        ofItemWithTarget:(id)target
        action:(SEL)action
{
	NSUInteger i = 0;
	for(; i < [self numberOfItems]; i++) {
		NSMenuItem *const item = [self itemAtIndex:i];
		if([item target] == target && [item action] == action) {
			if(outMenu) *outMenu = self;
			if(outIndex) *outIndex = i;
			return YES;
		}
		if([[item submenu] SBP_getMenu:outMenu index:outIndex ofItemWithTarget:target action:action]) return YES;
	}
	return NO;
}

@end
