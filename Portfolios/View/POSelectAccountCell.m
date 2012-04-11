//
//  POSelectAccountCell.m
//  Portfolio
//
//  Created by Adam Ernst on 11/25/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POSelectAccountCell.h"


@implementation POSelectAccountCell

- (id)initWithText:(NSString *)text {
    if (self = [super initWithFrame:CGRectMake(0, 0, 300, 45) reuseIdentifier:nil]) {
		CGRect contentRect = [[self contentView] frame];
		
		checkbox = [[UIButton alloc] initWithFrame:CGRectMake(22.0, 10.0, 25.0, 25.0)];
		[checkbox setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
		[checkbox setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
		[checkbox setImage:[UIImage imageNamed:@"disabledchecked.png"] forState:UIControlStateDisabled|UIControlStateSelected];
		[checkbox addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
		[checkbox setSelected:YES];
		[[self contentView] addSubview:checkbox];
		
		field = [[UITextField alloc] initWithFrame:CGRectMake(54.0, 15, lroundf(contentRect.size.width - 54.0 - 8.0), 35)];
		[field setText:text];
		[field setFont:[UIFont boldSystemFontOfSize:14.0]];
		[field setTextColor:[UIColor colorWithWhite:0.29 alpha:1.0]];
		[field setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
		[field setAdjustsFontSizeToFitWidth:YES];
		[field setMinimumFontSize:10.0];
        [[self contentView] addSubview:field];
		
		[self setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    return self;
}

- (void)dealloc {
	[field release];
	[checkbox release];
    [super dealloc];
}

- (void)buttonPressed:(id)sender {
	[checkbox setSelected:![checkbox isSelected]];
}

- (BOOL)isChecked {
	return [checkbox isSelected];
}

- (void)setChecked:(BOOL)newValue {
	[checkbox setSelected:newValue];
}

- (BOOL)isEnabled {
	return [checkbox isEnabled];
}

- (void)setEnabled:(BOOL)newEnabled {
	[checkbox setEnabled:newEnabled];
	[field setEnabled:newEnabled];
}

- (NSString *)text {
	return [field text];
}

- (void)setText:(NSString *)newText {
	[field setText:newText];
}

- (void)setType:(POSelectAccountCellType)type {
	NSString *imageName;
	switch (type) {
		case POSelectAccountCellTypeSingleCell:
			imageName = @"card_cell_one.png";
			break;
		case POSelectAccountCellTypeTopCell:
			imageName = @"card_cell_top.png";
			break;
		case POSelectAccountCellTypeMiddleCell:
			imageName = @"card_cell_middle.png";
			break;
		case POSelectAccountCellTypeBottomCell:
			imageName = @"card_cell_bottom.png";
			break;
		default:
			return;
	}
	[self setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]] autorelease]];
}

@end
