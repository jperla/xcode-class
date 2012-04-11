//
//  POOverlay.m
//  Portfolio
//
//  Created by Adam Ernst on 11/20/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POOverlay.h"


@implementation POOverlay

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor clearColor]];
		[self setUserInteractionEnabled:NO];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	[[UIColor colorWithWhite:0.0 alpha:0.70] setFill];
#define CORNER_RADIUS 16.0
	CGContextAddArc(context, CORNER_RADIUS, CORNER_RADIUS, CORNER_RADIUS, M_PI, 3.0 * M_PI / 2.0, 0);
	CGContextAddArc(context, [self frame].size.width - CORNER_RADIUS, CORNER_RADIUS, CORNER_RADIUS, 3.0 * M_PI / 2.0, 0.0, 0);
	CGContextAddArc(context, [self frame].size.width - CORNER_RADIUS, [self frame].size.height - CORNER_RADIUS, CORNER_RADIUS, 0.0, M_PI / 2.0, 0);
	CGContextAddArc(context, CORNER_RADIUS, [self frame].size.height - CORNER_RADIUS, CORNER_RADIUS, M_PI / 2.0, M_PI, 0);
	CGContextClosePath(context);
	CGContextFillPath(context);
}

@end
