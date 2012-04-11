//
//  UINavigationController+POStyle.m
//  Portfolios
//
//  Created by Adam Ernst on 11/18/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "UINavigationController+POStyle.h"


@implementation UINavigationController ( POStyle )

- (id)initWithRootViewController_Stylize:(UIViewController *)controller {
	id ret = [self initWithRootViewController_Stylize:controller];
	if (ret) {
		[[ret navigationBar] setTintColor:[UIColor colorWithRed:0.7 green:0.5 blue:0.3 alpha:1.0]];
	}
	return ret;
}

@end
