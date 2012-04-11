//
//  POChangeLabel.m
//  Portfolio
//
//  Created by Adam Ernst on 2/6/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POChangeLabel.h"
#import "PONumberFormatters.h"
#import "POSettings.h"


@implementation POChangeLabel

@synthesize glowing;

+ (UIFont *)font {
	return [UIFont boldSystemFontOfSize:16.0];
}

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self setTextColor:[UIColor whiteColor]];
		[self setFont:[POChangeLabel font]];
		[self setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.38]];
		[self setShadowOffset:CGSizeMake(0.0, -1.0)];
		[self setTextAlignment:UITextAlignmentRight];
		[self setBackgroundColor:[UIColor clearColor]];
	}
	return self;
}

static UIImage *greenImage = nil;
static UIImage *greenGlowImage = nil;
static UIImage *redImage = nil;
static UIImage *redGlowImage = nil;

+ (UIImage *)greenImage {
	@synchronized(self) {
		if (greenImage == nil) {
			greenImage = [[[UIImage imageNamed:@"green.png"] stretchableImageWithLeftCapWidth:8 topCapHeight:0] retain];
		}
	}
	return greenImage;
}

+ (UIImage *)greenGlowImage {
	@synchronized(self) {
		if (greenGlowImage == nil) {
			greenGlowImage = [[[UIImage imageNamed:@"greenglow.png"] stretchableImageWithLeftCapWidth:35 topCapHeight:0] retain];
		}
	}
	return greenGlowImage;
}

+ (UIImage *)redImage {
	@synchronized(self) {
		if (redImage == nil) {
			redImage = [[[UIImage imageNamed:@"red.png"] stretchableImageWithLeftCapWidth:8 topCapHeight:0] retain];
		}
	}
	return redImage;
}

+ (UIImage *)redGlowImage {
	@synchronized(self) {
		if (redGlowImage == nil) {
			redGlowImage = [[[UIImage imageNamed:@"redglow.png"] stretchableImageWithLeftCapWidth:35 topCapHeight:0] retain];
		}
	}
	return redGlowImage;
}

- (UIImage *)backgroundImage {
	switch (color) {
		case POChangeLabelStyleGreen:
			return glowing ? [POChangeLabel greenGlowImage] : [POChangeLabel greenImage];
		case POChangeLabelStyleRed:
			return glowing ? [POChangeLabel redGlowImage] : [POChangeLabel redImage];
	}
	return nil;
}

- (void)drawRect:(CGRect)rect {
	float textWidth = [self textRectForBounds:[self bounds] limitedToNumberOfLines:1].size.width;
	if (glowing) textWidth += (kGlowLeftMargin + kGlowRightMargin);
	float unusedSpace = [self bounds].size.width - 12 - textWidth;
	
	CGRect bounds = [self bounds];
	if (unusedSpace > 0) {
		/* Don't let width fall below 70 for glowing images. */
		if (glowing && bounds.size.width - unusedSpace < 70) {
			unusedSpace = bounds.size.width - 70;
		}
		bounds.origin.x += unusedSpace;
		bounds.size.width -= unusedSpace;
	}
	
	[[self backgroundImage] drawInRect:bounds];
	[super drawRect:rect];
}

- (void)drawTextInRect:(CGRect)rect {
	rect.origin.x += 6.0;
	rect.size.width -= 12.0;
	
	if (glowing) {
		rect.origin.x += kGlowLeftMargin;
		rect.origin.y += kGlowTopMargin;
		rect.size.width -= (kGlowLeftMargin + kGlowRightMargin);
		rect.size.height -= (kGlowTopMargin + kGlowBottomMargin);
	}
	
	[super drawTextInRect:rect];
}

- (void)setChange:(NSDecimalNumber *)aChange withValue:(NSDecimalNumber *)aValue {
	color = ([aChange compare:[NSDecimalNumber zero]] == NSOrderedAscending) ? POChangeLabelStyleRed : POChangeLabelStyleGreen;
	[self setText:[PONumberFormatters stringForChange:aChange withValue:aValue inPercent:[[POSettings sharedSettings] showsChangeAsPercent]]];
}

+ (NSInteger)widthForChange:(NSDecimalNumber *)aChange withValue:(NSDecimalNumber *)aValue {
	return MAX([[PONumberFormatters stringForChange:aChange withValue:aValue inPercent:[[POSettings sharedSettings] showsChangeAsPercent]] sizeWithFont:[POChangeLabel font]].width + 12.0, 38.0);
}

@end
