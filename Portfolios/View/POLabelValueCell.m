//
//  POLabelValueCell.m
//  Portfolios
//
//  Created by Adam Ernst on 3/14/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POLabelValueCell.h"


@implementation POLabelValueCell

+ (UIFont *)defaultLabelFont {
	return [UIFont boldSystemFontOfSize:17.0];
}

+ (UIFont *)defaultValueFont {
	return [UIFont systemFontOfSize:17.0];
}

- (id)initWithLabelWidth:(CGFloat)labelWidth reuseIdentifier:(NSString *)anIdentifier {
	
#define kCellWidth 300.0
#define kCellHeight 44.0
#define kTopMargin 9.0
	
    if (self = [super initWithFrame:CGRectMake(0.0, 0.0, kCellWidth, kCellHeight) reuseIdentifier:anIdentifier]) {
        label = [[UILabel alloc] initWithFrame:CGRectMake(kTopMargin, kTopMargin, labelWidth, kCellHeight - kTopMargin * 2.0)];
		[label setFont:[POLabelValueCell defaultLabelFont]];
		[label setBackgroundColor:[UIColor clearColor]];
		[label setOpaque:NO];
		[[self contentView] addSubview:label];
		
		CGFloat valueX = kTopMargin + labelWidth + (labelWidth > 0.0 ? kTopMargin : 0);
		value = [[UILabel alloc] initWithFrame:CGRectMake(valueX, kTopMargin, kCellWidth - valueX - kTopMargin, kCellHeight - kTopMargin * 2.0)];
		[value setFont:[POLabelValueCell defaultValueFont]];
		[value setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		[value setBackgroundColor:[UIColor clearColor]];
		[value setOpaque:NO];
		[[self contentView] addSubview:value];
		
		/* Disable selection */
		[self setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    return self;
}

- (void)dealloc {
	[label release];
	[value release];
    [super dealloc];
}

- (UIFont *)labelFont {
	return [label font];
}

- (void)setLabelFont:(UIFont *)aFont {
	[label setFont:aFont];
}

- (UIFont *)valueFont {
	return [value font];
}

- (void)setValueFont:(UIFont *)aFont {
	[value setFont:aFont];
}

- (UIColor *)labelTextColor {
	return [label textColor];
}

- (void)setLabelTextColor:(UIColor *)aTextColor {
	[label setTextColor:aTextColor];
}

- (UIColor *)valueTextColor {
	return [value textColor];
}

- (void)setValueTextColor:(UIColor *)aTextColor {
	[value setTextColor:aTextColor];
}

- (NSString *)labelText {
	return [label text];
}

- (void)setLabelText:(NSString *)aText {
	[label setText:aText];
}

- (NSString *)valueText {
	return [value text];
}

- (void)setValueText:(NSString *)aText {
	[value setText:aText];
}

@end
