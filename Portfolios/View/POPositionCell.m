//
//  POPositionCell.m
//  Portfolio
//
//  Created by Adam Ernst on 2/6/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POPositionCell.h"
#import "POPosition.h"
#import "POChangeLabel.h"
#import "PONumberFormatters.h"
#import "POSecurity.h"
#import "POSecurities.h"
#import "POSettings.h"


@implementation POPositionCell

+ (UIColor *)lightShadowColor {
	return [UIColor colorWithWhite:1.0 alpha:0.80];
}

+ (UIColor *)darkShadowColor {
	return [UIColor colorWithWhite:0.0 alpha:0.80];
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:CGRectMake(0, 0, 320, 44) reuseIdentifier:reuseIdentifier]) {
		[self setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"position_row.png"]] autorelease]];
		[self setSelectedBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"position_row_selected.png"]] autorelease]];
		
		changeLabel = [[POChangeLabel alloc] initWithFrame:CGRectMake(320 - 8 - POPositionCellDefaultChangeWidth, 9, POPositionCellDefaultChangeWidth, 28)];
		[changeLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
		[[self contentView] addSubview:changeLabel];
		
		UIColor *mainTextColor = [UIColor colorWithWhite:0.0 alpha:0.75];
		
		nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 13, 132, 20)];
		[nameLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
		[nameLabel setBackgroundColor:[UIColor clearColor]];
		[nameLabel setTextColor:mainTextColor];
		[nameLabel setHighlightedTextColor:[UIColor whiteColor]];
		[nameLabel setShadowColor:[POPositionCell lightShadowColor]];
		[nameLabel setShadowOffset:CGSizeMake(0.0, 1.0)];
		[nameLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		[[self contentView] addSubview:nameLabel];
		
		valueLabel = [[UILabel alloc] initWithFrame:CGRectMake([changeLabel frame].origin.x - POPositionCellValueWidth - 6, 13, POPositionCellValueWidth, 20)];
		[valueLabel setFont:[UIFont boldSystemFontOfSize:20.0]];
		[valueLabel setBackgroundColor:[UIColor clearColor]];
		[valueLabel setTextColor:mainTextColor];
		[valueLabel setHighlightedTextColor:[UIColor whiteColor]];
		[valueLabel setShadowColor:[POPositionCell lightShadowColor]];
		[valueLabel setShadowOffset:CGSizeMake(0.0, 1.0)];
		[valueLabel setTextAlignment:UITextAlignmentRight];
		[valueLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
		[[self contentView] addSubview:valueLabel];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(securitiesRefreshed:) name:POSecuritiesDidRefreshNotification object:nil];
		[[POSettings sharedSettings] addObserver:self forKeyPath:@"showsChangeAsPercent" options:0 context:nil];
    }
    return self;
}

- (void)releasePosition {
	if (position) {
		[position removeObserver:self forKeyPath:@"value"];
		[position removeObserver:self forKeyPath:@"change"];
		[position release];
		position = nil;
	}
}

- (void)updateLabels {
	if (!position) return;
	
	NSString *acctValue = [[PONumberFormatters valueFormatter] stringFromNumber:[position value]];
	[valueLabel setText:acctValue];
	[changeLabel setChange:[position change] withValue:[position value]];
	[nameLabel setText:[[position security] ticker]];
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
	for (UILabel *l in [NSArray arrayWithObjects:nameLabel, valueLabel, nil]) {
		[l setShadowColor:(sel ? [POPositionCell darkShadowColor] : [POPositionCell lightShadowColor])];
		[l setShadowOffset:(sel ? CGSizeMake(0.0, -1.0) : CGSizeMake(0.0, 1.0))];
	}
	if (animated)
		[UIView commitAnimations];
	
	[super setSelected:sel animated:animated];
}

- (void)setPosition:(POPosition *)pos {
	if (pos != position) {
		[self releasePosition];
		position = [pos retain];
		[pos addObserver:self forKeyPath:@"value" options:0 context:nil];
		[pos addObserver:self forKeyPath:@"change" options:0 context:nil];
	}
	[self updateLabels];
}

- (POPosition *)position {
	return position;
}

- (void)dealloc {
    [self releasePosition];
	[changeLabel release];
	[valueLabel release];
	[nameLabel release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[POSettings sharedSettings] removeObserver:self forKeyPath:@"showsChangeAsPercent"];
	[super dealloc];
}

- (void)prepareForReuse {
	[self releasePosition];
	[super prepareForReuse];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == position) {
		[self updateLabels];
	} else if (object == [POSettings sharedSettings] && [keyPath isEqualToString:@"showsChangeAsPercent"]) {
		[self updateLabels];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)setInsertMode {
	[valueLabel removeFromSuperview];
	[changeLabel removeFromSuperview];
	[nameLabel setText:NSLocalizedString(@"Add new position...", @"")];
	[nameLabel setFrame:CGRectMake([nameLabel frame].origin.x, [nameLabel frame].origin.y, 
								   [changeLabel frame].origin.x + [changeLabel frame].size.width - [nameLabel frame].origin.x, 
								   [nameLabel frame].size.height)];
}

- (NSInteger)changeLabelWidth {
	return [changeLabel frame].size.width;
}

- (void)setChangeLabelWidth:(NSInteger)width {
	[changeLabel setFrame:CGRectMake([[self contentView] frame].size.width - 8 - width, 9, width, 28)];
	[valueLabel setFrame:CGRectMake([changeLabel frame].origin.x - POPositionCellValueWidth - 4, 13, POPositionCellValueWidth, 20)];
	[nameLabel setFrame:CGRectMake(8, 13, [valueLabel frame].origin.x - 8 - 12, 20)];
}

@end
