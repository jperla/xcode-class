//
//  POPromptEditCell.m
//  Portfolio
//
//  Created by Adam Ernst on 11/20/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POPromptEditCell.h"


@implementation POPromptEditCell

+ (UIFont *)defaultPromptFont {
	return [UIFont boldSystemFontOfSize:17.0];
}

+ (UIFont *)defaultFieldFont {
	return [UIFont systemFontOfSize:17.0];
}

- (id)initWithPrompt:(NSString *)promptText promptWidth:(CGFloat)promptWidth placeholder:(NSString *)placeholder isSecure:(BOOL)isSecure leftMargin:(CGFloat)leftMargin {
	
#define kCellWidth 300.0
#define kCellHeight 44.0
#define kTopMargin 9.0
	
    if (self = [super initWithFrame:CGRectMake(0.0, 0.0, kCellWidth, kCellHeight) reuseIdentifier:nil]) {
        prompt = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, kTopMargin - 1.0, promptWidth, kCellHeight - kTopMargin * 2.0)];
		[prompt setFont:[POPromptEditCell defaultPromptFont]];
		[prompt setText:promptText];
		[prompt setBackgroundColor:[UIColor clearColor]];
		[[self contentView] addSubview:prompt];
		
		CGFloat fieldX = leftMargin + promptWidth + (promptWidth > 0.0 ? kTopMargin : 0);
		field = [[UITextField alloc] initWithFrame:CGRectMake(fieldX, kTopMargin + 3.0, kCellWidth - fieldX - leftMargin, kCellHeight - kTopMargin * 2.0)];
		[field setFont:[POPromptEditCell defaultFieldFont]];
		[field setPlaceholder:placeholder];
		[field setSecureTextEntry:isSecure];
		[field setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		[field addTarget:self action:@selector(returnKey:) forControlEvents:UIControlEventEditingDidEndOnExit];
		[[self contentView] addSubview:field];
		
		/* Disable selection */
		[self setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    return self;
}

- (id)initWithPrompt:(NSString *)promptText promptWidth:(CGFloat)promptWidth placeholder:(NSString *)placeholder isSecure:(BOOL)isSecure {
	/* Default to same as top margin */
	return [self initWithPrompt:promptText promptWidth:promptWidth placeholder:placeholder isSecure:isSecure leftMargin:kTopMargin];
}

- (void)dealloc {
	[prompt release];
	[field release];
    [super dealloc];
}

- (void)setAutocorrects:(BOOL)autocorrects {
	[field setAutocorrectionType:(autocorrects ? UITextAutocorrectionTypeDefault : UITextAutocorrectionTypeNo)];
	[field setAutocapitalizationType:(autocorrects ? UITextAutocapitalizationTypeSentences : UITextAutocapitalizationTypeNone)];
}

- (void)setReturnKeyType:(UIReturnKeyType)returnKeyType {
	[field setReturnKeyType:returnKeyType];
}

- (void)setFieldAction:(SEL)action {
	fieldAction = action;
}

- (void)returnKey:(id)sender {
	if (fieldAction && [self target]) {
		NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[[[self target] class] instanceMethodSignatureForSelector:fieldAction]];
		[inv setTarget:[self target]];
		[inv setSelector:fieldAction];
		[inv setArgument:&sender atIndex:2];
		[inv retainArguments];
		[inv invoke];
	}
}

- (BOOL)becomeFirstResponder {
	return [field becomeFirstResponder];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	/* Ignore selection */
}

- (void)setSelected:(BOOL)selected {
	/* Ignore selection */
}

- (void)setEnabled:(BOOL)enabled {
	[field setEnabled:enabled];
}

- (BOOL)isEnabled {
	return [field isEnabled];
}

- (NSString *)fieldText {
	return [field text];
}

- (void)setFieldText:(NSString *)newText {
	[field setText:newText];
}

- (void)setFieldAutocapitalizationType:(UITextAutocorrectionType)type {
	[field setAutocapitalizationType:type];
}

- (UITextAutocorrectionType)fieldAutocapitalizationType {
	return [field autocapitalizationType];
}

- (void)setPromptFont:(UIFont *)f {
	[prompt setFont:f];
}

- (UIFont *)promptFont {
	return [prompt font];
}

- (void)setFieldFont:(UIFont *)f {
	[field setFont:f];
}

- (UIFont *)fieldFont {
	return [field font];
}

- (void)setPromptTextColor:(UIColor *)c {
	[prompt setTextColor:c];
}

- (UIColor *)promptTextColor {
	return [prompt textColor];
}

- (void)setFieldTextColor:(UIColor *)c {
	[field setTextColor:c];
}

- (UIColor *)fieldTextColor {
	return [field textColor];
}

@end
