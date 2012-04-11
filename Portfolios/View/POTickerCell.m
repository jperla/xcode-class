//
//  POTickerCell.m
//  Portfolios
//
//  Created by Adam Ernst on 5/9/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POTickerCell.h"


@implementation POTickerCell

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        symbolLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 12, 20, 30)];
		[symbolLabel setFont:[UIFont boldSystemFontOfSize:17.0]];
		[symbolLabel setTextColor:[UIColor colorWithWhite:0.176 alpha:1.0]];
		[symbolLabel setHighlightedTextColor:[symbolLabel textColor]];
		[symbolLabel setOpaque:NO];
		[symbolLabel setBackgroundColor:[UIColor clearColor]];
		[[self contentView] addSubview:symbolLabel];
		
		nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(36, 12, 20, 30)];
		[nameLabel setFont:[UIFont systemFontOfSize:17.0]];
		[nameLabel setTextColor:[UIColor colorWithWhite:0.30 alpha:1.0]];
		[nameLabel setHighlightedTextColor:[nameLabel textColor]];
		[nameLabel setOpaque:NO];
		[nameLabel setBackgroundColor:[UIColor clearColor]];
		[[self contentView] addSubview:nameLabel];
		
		[self setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ticker_row_background.png"]] autorelease]];
		[self setSelectedBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ticker_row_background_selected.png"]] autorelease]];
	}
	return self;
}
		
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[symbolLabel setHighlighted:selected];
	[nameLabel setHighlighted:selected];
	[super setSelected:selected animated:animated];
}

- (void)dealloc {
	[symbolLabel release];
	[nameLabel release];
    [super dealloc];
}

- (void)setSymbol:(NSString *)symbol name:(NSString *)name {
	[symbolLabel setText:symbol];
	[nameLabel setText:name];
	
	[symbolLabel sizeToFit];
	[nameLabel sizeToFit];
	
	int x = [symbolLabel frame].origin.x + [symbolLabel frame].size.width + 8;
	[nameLabel setFrame:CGRectMake(x, 12, MIN([nameLabel frame].size.width, [[self contentView] frame].size.width - x - 8), [nameLabel frame].size.height)];
}

@end
