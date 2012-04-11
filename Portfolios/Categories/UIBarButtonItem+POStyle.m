//
//  UIBarButtonItem+POStyle.m
//  Portfolio
//
//  Created by Adam Ernst on 2/5/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "UIBarButtonItem+POStyle.h"

typedef enum {
	POStyleButtonBack,
	POStyleButtonBackHighlighted,
	POStyleButtonBordered,
	POStyleButtonBorderedHighlighted,
	POStyleButtonDone,
	POStyleButtonDoneHighlighted
} POStyleButton;

#define kButtonMargin 18

@implementation UIBarButtonItem ( POStyle )

- (UIImage *)styledButtonImage:(POStyleButton)image withWidth:(NSInteger)width {
	NSInteger leftCapWidth = 8, rightCapWidth = 8;
	NSString *name;
	switch (image) {
		case POStyleButtonBack:
			name = @"back.png";
			leftCapWidth = 16;
			break;
		case POStyleButtonBackHighlighted:
			name = @"back_pressed.png";
			leftCapWidth = 16;
			break;
		case POStyleButtonBordered:
			name = @"button.png";
			break;
		case POStyleButtonBorderedHighlighted:
			name = @"button_pressed.png";
			break;
		case POStyleButtonDone:
			name = @"done.png";
			break;
		case POStyleButtonDoneHighlighted:
			name = @"done_pressed.png";
			break;
		default:
			return nil;
	}
	
	UIImage *baseImage = [UIImage imageNamed:name];
	UIImage *fallback = [baseImage stretchableImageWithLeftCapWidth:leftCapWidth topCapHeight:0]; /* In case of error */
	
	if ([baseImage size].width < leftCapWidth + rightCapWidth)
		return fallback;
	
	NSInteger height = [baseImage size].height;
	
	CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
	if (!rgb) return fallback;
	CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, rgb, kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(rgb);
	if (!context) return fallback;
	
	CGImageRef leftCap = CGImageCreateWithImageInRect([baseImage CGImage], CGRectMake(0, 0, leftCapWidth, height));
	CGImageRef tiledPart = CGImageCreateWithImageInRect([baseImage CGImage], CGRectMake(leftCapWidth, 0, [baseImage size].width - leftCapWidth - rightCapWidth, height));
	CGImageRef rightCap = CGImageCreateWithImageInRect([baseImage CGImage], CGRectMake([baseImage size].width - rightCapWidth, 0, rightCapWidth, height));	
	
	CGContextDrawImage(context, CGRectMake(0, 0, leftCapWidth, height), leftCap);
	CGContextDrawImage(context, CGRectMake(width - rightCapWidth, 0, rightCapWidth, height), rightCap);
	CGContextClipToRect(context, CGRectMake(leftCapWidth, 0, width - leftCapWidth - rightCapWidth, height));
	CGContextDrawTiledImage(context, CGRectMake(0, 0, CGImageGetWidth(tiledPart), height), tiledPart);
	
	CGImageRelease(leftCap);
	CGImageRelease(tiledPart);
	CGImageRelease(rightCap);
	
	CGImageRef outImage = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	if (!outImage) return fallback;
	
	UIImage *img = [UIImage imageWithCGImage:outImage];
	CGImageRelease(outImage);
	return img;
}

+ (UIButton *)finishButton:(UIButton *)button withTarget:(id)target action:(SEL)action extraMargin:(NSInteger)extraMargin {
	[button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
	
	[button setFont:[UIFont boldSystemFontOfSize:12.0]];
	[button setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.75] forState:UIControlStateDisabled];
	[button setTitleShadowColor:[UIColor colorWithRed:0.25 green:0.30 blue:0.35 alpha:1.0] forState:UIControlStateNormal];
	[button setTitleShadowOffset:CGSizeMake(0, -1)];
	[button sizeToFit];
	
	[button setAdjustsImageWhenHighlighted:NO];
		
	[button setFrame:CGRectMake([button frame].origin.x, [button frame].origin.y, [button frame].size.width + kButtonMargin + extraMargin, 31.0)];
	return button;
}

+ (UIButton *)buttonWithImage:(UIImage *)anImage target:(id)target action:(SEL)action {
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setImage:anImage forState:UIControlStateNormal];
	return [UIBarButtonItem finishButton:button withTarget:target action:action extraMargin:-6];
}

+ (UIButton *)buttonWithTitle:(NSString *)aTitle target:(id)target action:(SEL)action extraMargin:(NSInteger)extraMargin {
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setTitle:aTitle forState:UIControlStateNormal];
	return [UIBarButtonItem finishButton:button withTarget:target action:action extraMargin:extraMargin];
}

- (UIBarButtonItem *)initWithBackButtonTitle:(NSString *)aTitle target:(id)target selector:(SEL)action {
	UIButton *button = [UIBarButtonItem buttonWithTitle:aTitle target:target action:action extraMargin:6];
	[button setTitleEdgeInsets:UIEdgeInsetsMake(0, 14, 0, -14)];
	[button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
	
	[button setBackgroundImage:[self styledButtonImage:POStyleButtonBack withWidth:[button frame].size.width] forState:UIControlStateNormal];
	[button setBackgroundImage:[self styledButtonImage:POStyleButtonBackHighlighted withWidth:[button frame].size.width] forState:UIControlStateHighlighted];
	
	if (self = [self initWithCustomView:button]) {
		/* No initialization needed */
	}
	return self;
}

- (id)initWithTitle_Stylize:(NSString *)title style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
	UIButton *button = [UIBarButtonItem buttonWithTitle:title target:target action:action extraMargin:0];
	
	if (self = [self initWithCustomView:button]) {
		[self setStyle:style];
		[self setWidth:[button frame].size.width];
	}
	return self;
}

- (id)initWithImage_Stylize:(UIImage *)image style:(UIBarButtonItemStyle)style target:(id)target action:(SEL)action {
	if (style == UIBarButtonItemStylePlain) {
		return [self initWithImage_Stylize:image style:style target:target action:action];
	} else {
		UIButton *button = [UIBarButtonItem buttonWithImage:image target:target action:action];
		
		if (self = [self initWithCustomView:button]) {
			[self setStyle:style];
			[self setWidth:[button frame].size.width];
		}
		return self;
	}
}

- (id)initWithBarButtonSystemItem_Stylize:(UIBarButtonSystemItem)systemItem target:(id)target action:(SEL)action {
	switch (systemItem) {
		case UIBarButtonSystemItemDone:
			return [self initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleDone target:target action:action];
		case UIBarButtonSystemItemCancel:
			return [self initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStyleBordered target:target action:action];
		case UIBarButtonSystemItemEdit:
			return [self initWithTitle:NSLocalizedString(@"Edit", @"") style:UIBarButtonItemStyleBordered target:target action:action];
		case UIBarButtonSystemItemSave:
			return [self initWithTitle:NSLocalizedString(@"Save", @"") style:UIBarButtonItemStyleBordered target:target action:action];
		case UIBarButtonSystemItemAdd:
			return [self initWithImage:[UIImage imageNamed:@"add.png"] style:UIBarButtonItemStyleBordered target:target action:action];
	}
	
	return [self initWithBarButtonSystemItem_Stylize:systemItem target:target action:action];
}

- (void)setStyle_Stylize:(UIBarButtonItemStyle)aStyle {
	/* Call the original implementation */
	[self setStyle_Stylize:aStyle];
	
	UIButton *button = (UIButton *)[self customView];
	
	switch (aStyle) {
		case UIBarButtonItemStylePlain:
			[button setBackgroundImage:nil forState:UIControlStateNormal];
			[button setBackgroundImage:nil forState:UIControlStateHighlighted];
			break;
		case UIBarButtonItemStyleBordered:
			[button setBackgroundImage:[self styledButtonImage:POStyleButtonBordered withWidth:[button frame].size.width] forState:UIControlStateNormal];
			[button setBackgroundImage:[self styledButtonImage:POStyleButtonBorderedHighlighted withWidth:[button frame].size.width] forState:UIControlStateHighlighted];
			break;
		case UIBarButtonItemStyleDone:
			[button setBackgroundImage:[self styledButtonImage:POStyleButtonDone withWidth:[button frame].size.width] forState:UIControlStateNormal];
			[button setBackgroundImage:[self styledButtonImage:POStyleButtonDoneHighlighted withWidth:[button frame].size.width] forState:UIControlStateHighlighted];			
			break;
	}
}

- (void)setTarget_Stylize:(id)target {
	UIButton *button = (UIButton *)[self customView];
	
	/* Remove old target and re-add */
	[button removeTarget:[self target] action:[self action] forControlEvents:UIControlEventTouchUpInside];
	[button addTarget:target action:[self action] forControlEvents:UIControlEventTouchUpInside];
	
	/* Pass along to original implementation */
	[self setTarget_Stylize:target];
}

- (void)setAction_Stylize:(SEL)action {
	UIButton *button = (UIButton *)[self customView];
	
	/* Remove old action and re-add */
	[button removeTarget:[self target] action:[self action] forControlEvents:UIControlEventTouchUpInside];
	[button addTarget:[self target] action:action forControlEvents:UIControlEventTouchUpInside];
	
	/* Pass along to original implementation */
	[self setAction_Stylize:action];
}

- (void)setTitle_Stylize:(NSString *)title {
	UIButton *button = (UIButton *)[self customView];
	[button setTitle:title forState:UIControlStateNormal];
	
	[self setTitle_Stylize:title];
}

- (void)setPossibleTitles_Stylize:(NSSet *)possibleTitles {
	UIButton *button = (UIButton *)[self customView];
	NSString *currentTitle = [button titleForState:UIControlStateNormal];
	NSInteger width = 0;
	for (NSString *possibleTitle in possibleTitles) {
		[button setTitle:possibleTitle forState:UIControlStateNormal];
		width = MAX(width, [button sizeThatFits:[button frame].size].width);
	}
	[button setTitle:currentTitle forState:UIControlStateNormal];
	
	[self setWidth:width + kButtonMargin];
	
	/* Pass along to original implementation */
	[self setPossibleTitles_Stylize:possibleTitles];
}

- (void)setWidth_Stylize:(CGFloat)width {
	UIButton *button = (UIButton *)[self customView];
	[button setFrame:CGRectMake(0, 0, width, [button frame].size.height)];
	[self setStyle:[self style]];
	
	[self setWidth_Stylize:width];
}

- (void)setEnabled_Stylize:(BOOL)enabled {
	UIButton *button = (UIButton *)[self customView];
	[button setEnabled:enabled];
	
	[self setEnabled_Stylize:enabled];
}

@end
