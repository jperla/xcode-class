//
//  POTotalsView.m
//  Portfolio
//
//  Created by Adam Ernst on 2/6/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POTotalsView.h"
#import "POChangeLabel.h"
#import "POAccounts.h"
#import "POAccount.h"
#import "POAutomaticAccount.h"
#import "PONumberFormatters.h"
#import "POSecurities.h"
#import "POSettings.h"


@implementation POTotalsView


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		[self setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"account_summary_background.png"]]];
		changeLabel = [[POChangeLabel alloc] initWithFrame:CGRectMake(10 - kGlowLeftMargin, 16 - kGlowTopMargin, 52 + kGlowLeftMargin + kGlowRightMargin, 28 + kGlowTopMargin + kGlowBottomMargin)];
		[changeLabel setGlowing:YES];
		[changeLabel setText:@"0"];
		[self addSubview:changeLabel];
		
		titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(74, 13, frame.size.width - 74 - 8, 20)];
		[titleLabel setFont:[UIFont boldSystemFontOfSize:18.0]];
		[titleLabel setBackgroundColor:[UIColor clearColor]];
		[titleLabel setTextColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
		[titleLabel setShadowColor:[UIColor colorWithWhite:1.0 alpha:0.80]];
		[titleLabel setShadowOffset:CGSizeMake(0.0, 1.0)];
		[titleLabel setText:@"Total value: $2,503.03"];
		[self addSubview:titleLabel];
		
		subLabel = [[UILabel alloc] initWithFrame:CGRectMake(74, 31, frame.size.width - 74 - 8, 18)];
		[subLabel setFont:[UIFont boldSystemFontOfSize:13.0]];
		[subLabel setBackgroundColor:[UIColor clearColor]];
		[subLabel setTextColor:[UIColor colorWithWhite:0.0 alpha:0.58]];
		[subLabel setText:@"Testing testing testing"];
		[self addSubview:subLabel];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(securitiesRefreshed:) name:POSecuritiesDidRefreshNotification object:nil];
		[[POSettings sharedSettings] addObserver:self forKeyPath:@"showsChangeAsPercent" options:0 context:nil];
	}
    return self;
}

- (void)releaseAccount {
	if (account) {
		[account removeObserver:self forKeyPath:@"value"];
		[account removeObserver:self forKeyPath:@"change"];
		[account release];
		account = nil;
	}
}

- (void)dealloc {
	[self releaseAccount];
	if (isShowingAllAccounts) {
		[[POAccounts sharedAccounts] removeObserver:self forKeyPath:@"value"];
		[[POAccounts sharedAccounts] removeObserver:self forKeyPath:@"change"];
	}
	[changeLabel release];
	[titleLabel release];
	[subLabel release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[POSettings sharedSettings] removeObserver:self forKeyPath:@"showsChangeAsPercent"];
    [super dealloc];
}

- (void)setSublabelVisible:(BOOL)v {
	[subLabel setHidden:!v];
	titleLabel.frame = CGRectMake(titleLabel.frame.origin.x, v ? 13 : 21, titleLabel.frame.size.width, titleLabel.frame.size.height);
}

- (void)updateLabelsForAccounts {
	[titleLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Total Value: %@", @"Top of portfolios view"), 
						 [[PONumberFormatters valueFormatter] stringFromNumber:[[POAccounts sharedAccounts] value]]]];
	[changeLabel setChange:[[POAccounts sharedAccounts] change] withValue:[[POAccounts sharedAccounts] value]];
	[subLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Today's Change: %@", @"Top of portfolios view"),
					   [PONumberFormatters stringForChange:[[POAccounts sharedAccounts] change]
												 withValue:[[POAccounts sharedAccounts] value] 
												 inPercent:![[POSettings sharedSettings] showsChangeAsPercent]]]];
	[self setSublabelVisible:YES];
}

- (void)updateLabelsForAccount {
	if (!account) return;
	
	[titleLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Value: %@", @"Top of portfolios view"), 
						 [[PONumberFormatters valueFormatter] stringFromNumber:[account value]]]];
	[changeLabel setChange:[account change] withValue:[account value]];
	[self setChangeLabelWidth:[POChangeLabel widthForChange:[account change] withValue:[account value]]];
	
	BOOL isAutomatic = [[account class] isSubclassOfClass:[POAutomaticAccount class]];
	[self setSublabelVisible:isAutomatic];
	
	if (isAutomatic) {
		POAutomaticAccount *acc = (POAutomaticAccount *)account;
		
		NSMutableString *sub = [NSMutableString stringWithCapacity:128];
		[sub appendFormat:NSLocalizedString(@"Cash: %@", @"Total cash"), [[PONumberFormatters valueFormatter] stringFromNumber:[acc cashBalance]]];
		
		if (![[acc marginBalance] isEqualToNumber:[NSDecimalNumber zero]]) {
			[sub appendFormat:NSLocalizedString(@", Margin: %@", @"Margin total (include leading comma)"), [[PONumberFormatters valueFormatter] stringFromNumber:[acc marginBalance]]];
		}
		
		if (![[acc shortBalance] isEqualToNumber:[NSDecimalNumber zero]]) {
			[sub appendFormat:NSLocalizedString(@", Short: %@", @"Short total (include leading comma)"), [[PONumberFormatters valueFormatter] stringFromNumber:[acc shortBalance]]];
		}
		
		[subLabel setText:sub];
	}
}

- (void)setAccounts {
	isShowingAllAccounts = YES;
	[[POAccounts sharedAccounts] addObserver:self forKeyPath:@"value" options:0 context:nil];
	[[POAccounts sharedAccounts] addObserver:self forKeyPath:@"change" options:0 context:nil];
	[self updateLabelsForAccounts];
}

- (void)setAccount:(POAccount *)acc {
	[self releaseAccount];
	
	account = [acc retain];
	[account addObserver:self forKeyPath:@"value" options:0 context:nil];
	[account addObserver:self forKeyPath:@"change" options:0 context:nil];
	[self updateLabelsForAccount];
}

- (void)updateLabels {
	if (isShowingAllAccounts)
		[self updateLabelsForAccounts];
	else
		[self updateLabelsForAccount];	
}

- (void)securitiesRefreshed:(id)obj {
	[self updateLabels];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == account && !isShowingAllAccounts) {
		[self updateLabels];
	} else if (object == [POAccounts sharedAccounts]) {
		[self updateLabels];
	} else if (object == [POSettings sharedSettings] && [keyPath isEqualToString:@"showsChangeAsPercent"]) {
		[self updateLabels];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (NSInteger)changeLabelWidth {
	return [changeLabel frame].size.width - kGlowLeftMargin - kGlowRightMargin;
}

- (void)setChangeLabelWidth:(NSInteger)width {
	CGRect f = [changeLabel frame];
	NSInteger delta = (width + kGlowLeftMargin + kGlowRightMargin) - (f.size.width);
	[changeLabel setFrame:CGRectMake(f.origin.x, f.origin.y, width + kGlowLeftMargin + kGlowRightMargin, f.size.height)];
	
	f = [titleLabel frame];
	[titleLabel setFrame:CGRectMake(f.origin.x + delta, f.origin.y, f.size.width - delta, f.size.height)];
	f = [subLabel frame];
	[subLabel setFrame:CGRectMake(f.origin.x + delta, f.origin.y, f.size.width - delta, f.size.height)];
}

@end
