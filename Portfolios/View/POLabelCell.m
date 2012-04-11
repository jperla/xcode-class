//
//  POLabelCell.m
//  Portfolio
//
//  Created by Adam Ernst on 11/21/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POLabelCell.h"


@implementation POLabelCell

- (id)initWithText:(NSString *)newText style:(POLabelCellStyle)aStyle {
	
#define kDefaultWidth 304.0
#define kDefaultHeight 44.0
	
    if (self = [super initWithFrame:CGRectMake(0.0, 0.0, kDefaultWidth, kDefaultHeight) reuseIdentifier:nil]) {
		style = aStyle;
		
		CGRect frame = CGRectMake(8.0, 0.0, [[self contentView] frame].size.width - 16.0, [[self contentView] frame].size.height);
		if (style == POLabelCellStyleCardTop) {
			frame.origin.y += 3.0f;
		} else if (style == POLabelCellStyleCardBottom) {
			frame.origin.y -= 10.0f;
		}
		
		label = [[UILabel alloc] initWithFrame:frame];
		[label setTextAlignment:UITextAlignmentCenter];
		[label setNumberOfLines:0];
		[label setLineBreakMode:UILineBreakModeWordWrap];
		[label setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
		[label setText:newText];
		
		[self setStyle:aStyle];
		[[self contentView] addSubview:label];
		[[self contentView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
		
		[self setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    return self;
}

- (void)dealloc {
	[label release];
    [super dealloc];
}

- (CGFloat)height {	
	CGFloat margins, ret;
	switch (style) {
		case POLabelCellStyleGrouped:
			margins = [[self contentView] frame].size.height - [label frame].size.height;
			ret = margins + [[label text] sizeWithFont:[label font] constrainedToSize:CGSizeMake([label frame].size.width, 1000) lineBreakMode:UILineBreakModeWordWrap].height;
			return ret;
		case POLabelCellStyleCardTop:
		case POLabelCellStyleCardBottom:
			return [[self backgroundView] frame].size.height;
	}
	return 44.0;
}

- (void)setText:(NSString *)text {
	[label setText:text];
	[self setStyle:style]; // Update images
}

- (NSString *)text {
	return [label text];
}

- (void)setFont:(UIFont *)font {
	[label setFont:font];
}

- (UIFont *)font {
	return [label font];
}

- (void)setTextColor:(UIColor *)col {
	[label setTextColor:col];
}

- (UIColor *)textColor {
	return [label textColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	/* Ignore */
}

- (void)setSelected:(BOOL)selected {
	/* Ignore */
}

- (UIView *)backgroundView {
	if (style == POLabelCellStyleGrouped) return nil;
	return [super backgroundView];
}

- (POLabelCellStyle)style {
	return style;
}

- (void)setStyle:(POLabelCellStyle)aStyle {
	if (aStyle == POLabelCellStyleCardTop) {
		[self setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:([[self text] length] ? @"card_top.png" : @"card_textless_top.png")]] autorelease]];
		[label setFont:[UIFont boldSystemFontOfSize:14.0]];
		[label setTextColor:[UIColor colorWithRed:0.627 green:0.388 blue:0.247 alpha:1.0]];
		[label setBackgroundColor:[UIColor clearColor]];
	} else if (aStyle == POLabelCellStyleCardBottom) {
		[self setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:([[self text] length] ? @"card_bottom.png" : @"card_textless_bottom.png")]] autorelease]];
		[label setFont:[UIFont systemFontOfSize:11.0]];
		[label setTextColor:[UIColor colorWithWhite:0.0 alpha:0.50]];
		[label setBackgroundColor:[UIColor clearColor]];
	} else {
		[label setFont:[UIFont boldSystemFontOfSize:17.0]];
		[label setBackgroundColor:[UIColor clearColor]];
		[label setTextColor:[UIColor colorWithRed:0.10 green:0.14 blue:0.20 alpha:1.0]];
		[label setShadowOffset:CGSizeMake(0.0, 1.0)];
		[label setShadowColor:[UIColor colorWithRed:0.88 green:0.90 blue:0.92 alpha:1.0]];		
	}
	style = aStyle;
}

@end
