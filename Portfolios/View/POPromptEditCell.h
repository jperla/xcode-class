//
//  POPromptEditCell.h
//  Portfolio
//
//  Created by Adam Ernst on 11/20/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface POPromptEditCell : UITableViewCell {
	UILabel     *prompt;
	UITextField *field;
	SEL          fieldAction;
}

+ (UIFont *)defaultPromptFont;
+ (UIFont *)defaultFieldFont;

@property (nonatomic, copy) NSString *fieldText;
@property (nonatomic, getter=isEnabled) BOOL enabled;

@property(nonatomic, retain) UIFont *promptFont;
@property(nonatomic, retain) UIFont *fieldFont;

@property(nonatomic, retain) UIColor *promptTextColor;
@property(nonatomic, retain) UIColor *fieldTextColor;

- (id)initWithPrompt:(NSString *)promptText promptWidth:(CGFloat)promptWidth placeholder:(NSString *)placeholder isSecure:(BOOL)isSecure leftMargin:(CGFloat)leftMargin;
- (id)initWithPrompt:(NSString *)promptText promptWidth:(CGFloat)promptWidth placeholder:(NSString *)placeholder isSecure:(BOOL)isSecure;
- (void)setAutocorrects:(BOOL)autocorrects;
- (void)setReturnKeyType:(UIReturnKeyType)returnKeyType;
- (void)setFieldAction:(SEL)action;
- (void)setFieldAutocapitalizationType:(UITextAutocorrectionType)type;
- (UITextAutocorrectionType)fieldAutocapitalizationType;	

@end
