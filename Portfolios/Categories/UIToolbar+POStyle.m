//
//  UIToolbar+POStyle.m
//  Portfolio
//
//  Created by Adam Ernst on 2/6/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "UIToolbar+POStyle.h"


@implementation UIToolbar ( POStyle )

- (void)drawRect_Stylize:(CGRect)rect {
	[[UIImage imageNamed:@"bottom_bar.png"] drawInRect:CGRectMake(0, 0, [self bounds].size.width, [self bounds].size.height)];
}

@end
