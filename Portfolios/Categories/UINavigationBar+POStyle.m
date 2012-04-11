//
//  UINavigationBar+POStyle.m
//  Portfolio
//
//  Created by Adam Ernst on 2/4/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "UINavigationBar+POStyle.h"
#import "UIBarButtonItem+POStyle.h"

@implementation UINavigationBar ( POStyle )

- (void)didAddSubview_Stylize:(UIView *)subview {
#define kStyleImageTag 439853 /* Random value to identify */
	
	UIView *styleImage = nil;
	for (UIView *view in [self subviews]) {
		if ([view tag] == kStyleImageTag) {
			styleImage = view;
			break;
		}
	}
	
	/* Create it if it doesn't exist yet */
	if (styleImage == nil) {
		styleImage = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navigation_bar.png"]] autorelease];
		[styleImage setTag:kStyleImageTag];
		[self insertSubview:styleImage atIndex:0];
	}
	
	/* Move to back */
	NSUInteger idx = [[self subviews] indexOfObject:styleImage];
	if (idx != 0) [self exchangeSubviewAtIndex:0 withSubviewAtIndex:idx];
	
	/* Call the original method */
	[self didAddSubview_Stylize:subview];
}

@end
