//
//  POAccountCell.m
//  Portfolio
//
//  Created by Adam Ernst on 12/2/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POAccountCell.h"
#import "POAccount.h"
#import "POChangeLabel.h"
#import "PONumberFormatters.h"
#import "POSecurities.h"
#import "POSettings.h"


@implementation POAccountCell

+ (UIColor *)lightShadowColor {
	return [UIColor colorWithWhite:1.0 alpha:0.80];
}

+ (UIColor *)darkShadowColor {
	return [UIColor colorWithWhite:0.0 alpha:0.80];
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:CGRectMake(0, 0, 320, 44) reuseIdentifier:reuseIdentifier]) {
		[self setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"account_row.png"]] autorelease]];
		[self setSelectedBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"position_row_selected.png"]] autorelease]];
		[self setHidesAccessoryWhenEditing:NO];
		
		CGRect contentBounds = [[self contentView] bounds];
		
		changeLabel = [[POChangeLabel alloc] initWithFrame:CGRectMake(10, 16, POAccountCellDefaultChangeWidth, 28)];
		[[self contentView] addSubview:changeLabel];
		
		nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(76, 13, contentBounds.size.width - 76 - 8, 20)];
		[nameLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
		[nameLabel setBackgroundColor:[UIColor clearColor]];
		[nameLabel setTextColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		[nameLabel setShadowColor:[POAccountCell lightShadowColor]];
		[nameLabel setShadowOffset:CGSizeMake(0.0, 1.0)];
		[nameLabel setHighlightedTextColor:[UIColor whiteColor]];
		[nameLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		[[self contentView] addSubview:nameLabel];
		
		valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(76, 31, contentBounds.size.width - 76 - 8, 18)];
		[valueLabel setFont:[UIFont boldSystemFontOfSize:13.0]];
		[valueLabel setBackgroundColor:[UIColor clearColor]];
		[valueLabel setTextColor:[UIColor colorWithWhite:0.0 alpha:0.58]];
		[valueLabel setHighlightedTextColor:[UIColor whiteColor]];
		[valueLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		[[self contentView] addSubview:valueLabel];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(securitiesRefreshed:) name:POSecuritiesDidRefreshNotification object:nil];
		[[POSettings sharedSettings] addObserver:self forKeyPath:@"showsChangeAsPercent" options:0 context:nil];
    }
    return self;
}

- (void)releaseAccount {
	if (account) {
		[account removeObserver:self forKeyPath:@"name"];
		[account removeObserver:self forKeyPath:@"value"];
		[account removeObserver:self forKeyPath:@"change"];
		[account release];
		account = nil;
	}
}

- (void)updateLabels {
	NSString *acctValue = [[PONumberFormatters valueFormatter] stringFromNumber:[account value]];
	
	[valueLabel setText:[NSString stringWithFormat:NSLocalizedString(@"%@", @"Value text in account list"), acctValue]];
	[changeLabel setChange:[account change] withValue:[account value]];
	[nameLabel setText:[account name]];
}

- (void)securitiesRefreshed:(id)obj {
	[self updateLabels];
}

- (void)setSelected:(BOOL)sel {
	[self setSelected:sel animated:NO];
}

- (void)setSelected:(BOOL)sel animated:(BOOL)animated {
	if (animated)
		[UIView beginAnimations:nil context:nil];
	[nameLabel setShadowColor:(sel ? [POAccountCell darkShadowColor] : [POAccountCell lightShadowColor])];
	[nameLabel setShadowOffset:(sel ? CGSizeMake(0.0, -1.0) : CGSizeMake(0.0, 1.0))];
	if (animated)
		[UIView commitAnimations];
	
	[super setSelected:sel animated:animated];
}

- (void)setAccount:(POAccount *)acc {
	if (acc == account) return;
	
	[self releaseAccount];
	account = [acc retain];
	[acc addObserver:self forKeyPath:@"name" options:0 context:nil];
	[acc addObserver:self forKeyPath:@"value" options:0 context:nil];
	[acc addObserver:self forKeyPath:@"change" options:0 context:nil];
	[self updateLabels];
}

- (void)dealloc {
    [self releaseAccount];
	[changeLabel release];
	[valueLabel release];
	[nameLabel release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[POSettings sharedSettings] removeObserver:self forKeyPath:@"showsChangeAsPercent"];
	[super dealloc];
}

- (void)prepareForReuse {
	[self releaseAccount];
	[super prepareForReuse];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == account) {
		[self updateLabels];
	} else if (object == [POSettings sharedSettings] && [keyPath isEqualToString:@"showsChangeAsPercent"]) {
		[self updateLabels];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (NSInteger)changeLabelWidth {
	return [changeLabel frame].size.width;
}

- (void)setChangeLabelWidth:(NSInteger)width {
	[changeLabel setFrame:CGRectMake(10, 16, width, 28)];
	NSInteger labelLeft = 10 + width + 14;
	[nameLabel setFrame:CGRectMake(labelLeft, 13, [[self contentView] frame].size.width - labelLeft - 8, 20)];
	[valueLabel setFrame:CGRectMake(labelLeft, 31, [[self contentView] frame].size.width - labelLeft - 8, 18)];
}

@end
