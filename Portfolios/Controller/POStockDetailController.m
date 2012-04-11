//
//  POStockDetailController.m
//  Portfolios
//
//  Created by Adam Ernst on 3/15/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POStockDetailController.h"
#import "POPosition.h"
#import "POSecurity.h"
#import "POSecurities.h"
#import "PONumberFormatters.h"


@implementation POStockDetailController

@synthesize volumeLabel, peLabel, dividendLabel, marketCapLabel, epsLabel, dayLabel, yearLabel;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
	if (self = [super initWithNibName:nibName bundle:nibBundle]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(securityStatsUpdated:) name:POSecuritiesDidRefreshNotification object:nil];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[position release];
	[volumeLabel release];
	[peLabel release];
	[dividendLabel release];
	[marketCapLabel release];
	[epsLabel release];
	[dayLabel release];
	[yearLabel release];
	[super dealloc];
}

- (NSString *)abbreviatedStringForDecimalNumber:(NSDecimalNumber *)aNumber {
	/* Abbreviates billions to B, millions to M, trillions to T */
	if (!aNumber) return @"—";
	
	NSDecimalNumber *trillion = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:12 isNegative:NO];
	NSDecimalNumber *billion = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:9 isNegative:NO];
	NSDecimalNumber *million = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:6 isNegative:NO];
	
	if ([aNumber compare:trillion] != NSOrderedAscending) {
		return [[[PONumberFormatters generalStatisticsFormatter] stringFromNumber:[aNumber decimalNumberByDividingBy:trillion]] stringByAppendingString:@"T"];
	} else if ([aNumber compare:billion] != NSOrderedAscending) {
		return [[[PONumberFormatters generalStatisticsFormatter] stringFromNumber:[aNumber decimalNumberByDividingBy:billion]] stringByAppendingString:@"B"];
	} else {
		return [[[PONumberFormatters generalStatisticsFormatter] stringFromNumber:[aNumber decimalNumberByDividingBy:million]] stringByAppendingString:@"M"];
	}
}

- (void)updateFields {
	POSecurity *sec = [position security];
	
	NSMutableString *volume = [NSMutableString stringWithFormat:@"%@ ", [self abbreviatedStringForDecimalNumber:[sec volume]]];
	[volume appendFormat:NSLocalizedString(@"(avg %@)", @"Average volume in parentheses in stats window"), [self abbreviatedStringForDecimalNumber:[sec averageVolume]]];
	[volumeLabel setText:volume];
	
	if (![sec dividend] || [[sec dividend] isEqualToNumber:[NSDecimalNumber zero]]) {
		[dividendLabel setText:@"—"];
	} else {
		[dividendLabel setText:[NSString stringWithFormat:@"%@ (%@)", 
								[[PONumberFormatters generalStatisticsFormatter] stringFromNumber:[sec dividend]],
								[[PONumberFormatters yieldFormatter] stringFromNumber:[sec yield]]]];
	}
	
	[peLabel setText:[[PONumberFormatters generalStatisticsFormatter] stringFromNumber:[sec peRatio]]];
	[marketCapLabel setText:[self abbreviatedStringForDecimalNumber:[sec marketCap]]];
	[epsLabel setText:[[PONumberFormatters generalStatisticsFormatter] stringFromNumber:[sec earningsPerShare]]];
	
	if ([sec lowDay] && [sec highDay]) {
		[dayLabel setText:[NSString stringWithFormat:@"%@ – %@", [[PONumberFormatters priceFormatter] stringFromNumber:[sec lowDay]], [[PONumberFormatters priceFormatter] stringFromNumber:[sec highDay]]]];
	} else {
		[dayLabel setText:@"—"];
	}
	
	if ([sec low52Week] && [sec high52Week]) {
		[yearLabel setText:[NSString stringWithFormat:@"%@ – %@", [[PONumberFormatters priceFormatter] stringFromNumber:[sec low52Week]], [[PONumberFormatters priceFormatter] stringFromNumber:[sec high52Week]]]];
	} else {
		[yearLabel setText:@"—"];
	}	
}

- (void)setPosition:(POPosition *)aPosition {
	if (position == aPosition) return;
	
	[position release];
	position = [aPosition retain];
	[self updateFields];
}

- (POPosition *)position {
	return position;
}

- (void)didReceiveMemoryWarning {
	// Ignore.
}

- (void)securityStatsUpdated:(NSNotification *)aNotification {
	[self updateFields];
}

@end
