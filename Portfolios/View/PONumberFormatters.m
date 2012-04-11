//
//  PONumberFormatters.m
//  Portfolio
//
//  Created by Adam Ernst on 2/6/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "PONumberFormatters.h"


@implementation PONumberFormatters

/* Returns the change for the two values, in percent or value as requested. */
+ (NSString *)stringForChange:(NSDecimalNumber *)aChange withValue:(NSDecimalNumber *)aValue inPercent:(BOOL)percent {
	if (!aChange) return (percent ? @"—%" : @"—");
	if (!aValue) aValue = [NSDecimalNumber zero];
	
	if (percent) {
		NSDecimalNumber *originalValue = [aValue decimalNumberBySubtracting:aChange];
		if ([originalValue isEqualToNumber:[NSDecimalNumber zero]]) return @"—%";
		return [[PONumberFormatters percentChangeFormatter] stringFromNumber:[aChange decimalNumberByDividingBy:originalValue]];
	} else {
		return [[PONumberFormatters changeFormatter] stringFromNumber:aChange];
	}
}

/* Displays percent day change for a position or portfolio */
/* e.g. "+53%", "-34%", or "+53.35%", "-34.24%" depending on settings */
static NSNumberFormatter *percentChangeFormatter = nil;
+ (NSNumberFormatter *)percentChangeFormatter {
	@synchronized(self) {
		if (percentChangeFormatter == nil) {
			percentChangeFormatter = [[NSNumberFormatter alloc] init];
			[percentChangeFormatter setNumberStyle:NSNumberFormatterPercentStyle];
			[percentChangeFormatter setPositivePrefix:@"+"];
			[percentChangeFormatter setMaximumFractionDigits:1];
			[percentChangeFormatter setMinimumFractionDigits:1];
		}
	}
	return percentChangeFormatter;
}

/* Displays absolute day change for a position or portfolio */
/* e.g. "+53", "-34", or "+53.35", "-34.24" depending on settings */
static NSNumberFormatter *changeFormatter = nil;
+ (NSNumberFormatter *)changeFormatter {
	@synchronized(self) {
		if (changeFormatter == nil) {
			changeFormatter = [[NSNumberFormatter alloc] init];
			[changeFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
			[changeFormatter setPositivePrefix:@"+"];
			[changeFormatter setMaximumFractionDigits:0];
		}
	}
	return changeFormatter;
}

/* Same as changeFormatter, but always displays exactly 2 decimals of precision */
/* Used in the "position detail" pane to display the change with more precision */
static NSNumberFormatter *detailChangeFormatter = nil;
+ (NSNumberFormatter *)detailChangeFormatter {
	@synchronized(self) {
		if (detailChangeFormatter == nil) {
			detailChangeFormatter = [[NSNumberFormatter alloc] init];
			[detailChangeFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
			[detailChangeFormatter setNegativePrefix:@""];
			[detailChangeFormatter setMinimumFractionDigits:2];
			[detailChangeFormatter setMaximumFractionDigits:2];
		}
	}
	return detailChangeFormatter;
}

/* Displays the absolute dollar value for any portfolio or position */
/* e.g. "$3,405", or "$3,405.43" depending on settings */
static NSNumberFormatter *valueFormatter = nil;
+ (NSNumberFormatter *)valueFormatter {
	@synchronized(self) {
		if (valueFormatter == nil) {
			valueFormatter = [[NSNumberFormatter alloc] init];
			[valueFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
			[valueFormatter setCurrencyCode:@"USD"];
			[valueFormatter setCurrencySymbol:@"$"];
			[valueFormatter setMaximumFractionDigits:0];
		}
	}
	return valueFormatter;
}

/* Displays the absolute dollar value for any portfolio or position */
/* e.g. "$3,405", or "$3,405.43" depending on settings */
static NSNumberFormatter *detailValueFormatter = nil;
+ (NSNumberFormatter *)detailValueFormatter {
	@synchronized(self) {
		if (detailValueFormatter == nil) {
			detailValueFormatter = [[NSNumberFormatter alloc] init];
			[detailValueFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
			[detailValueFormatter setCurrencyCode:@"USD"];
			[detailValueFormatter setCurrencySymbol:@"$"];
			[detailValueFormatter setMaximumFractionDigits:2];
			[detailValueFormatter setMinimumFractionDigits:2];
		}
	}
	return detailValueFormatter;
}

/* Used to display the absolute price of a security */
static NSNumberFormatter *priceFormatter = nil;
+ (NSNumberFormatter *)priceFormatter {
	@synchronized(self) {
		if (priceFormatter == nil) {
			priceFormatter = [[NSNumberFormatter alloc] init];
			[priceFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
			[priceFormatter setMinimumFractionDigits:2];
			[priceFormatter setMaximumFractionDigits:4];
		}
	}
	return priceFormatter;
}

/* Used to display the change *per share* (where presumably changes can be very small). */
static NSNumberFormatter *priceChangeFormatter = nil;
+ (NSNumberFormatter *)priceChangeFormatter {
	@synchronized(self) {
		if (priceChangeFormatter == nil) {
			priceChangeFormatter = [[NSNumberFormatter alloc] init];
			[priceChangeFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
			[priceChangeFormatter setPositivePrefix:@"+"];
			[priceChangeFormatter setMinimumFractionDigits:1];
			[priceChangeFormatter setMaximumFractionDigits:3];
		}
	}
	return priceChangeFormatter;
}

/* Used to display the number of shares in a position */
static NSNumberFormatter *sharesFormatter = nil;
+ (NSNumberFormatter *)sharesFormatter {
	@synchronized(self) {
		if (sharesFormatter == nil) {
			sharesFormatter = [[NSNumberFormatter alloc] init];
			[sharesFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
			[sharesFormatter setMinimumFractionDigits:0];
			[sharesFormatter setMaximumFractionDigits:3];
		}
	}
	return sharesFormatter;
}

/* Used to display general statistics */
/* e.g. P/E ratio, EPS, Mkt cap, dividend, volume */
static NSNumberFormatter *generalStatisticsFormatter = nil;
+ (NSNumberFormatter *)generalStatisticsFormatter {
	@synchronized(self) {
		if (generalStatisticsFormatter == nil) {
			generalStatisticsFormatter = [[NSNumberFormatter alloc] init];
			[generalStatisticsFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
			[generalStatisticsFormatter setNilSymbol:@"—"];
			[generalStatisticsFormatter setMinimumFractionDigits:1];
			[generalStatisticsFormatter setMaximumFractionDigits:2];
		}
	}
	return generalStatisticsFormatter;
}

static NSNumberFormatter *yieldFormatter = nil;
+ (NSNumberFormatter *)yieldFormatter {
	@synchronized(self) {
		if (yieldFormatter == nil) {
			yieldFormatter = [[NSNumberFormatter alloc] init];
			[yieldFormatter setNumberStyle:NSNumberFormatterPercentStyle];
			[yieldFormatter setNilSymbol:@"—%"];
			[yieldFormatter setZeroSymbol:@"—%"];
			[yieldFormatter setMaximumFractionDigits:2];
			[yieldFormatter setMinimumFractionDigits:2];
		}
	}
	return yieldFormatter;
}

@end
