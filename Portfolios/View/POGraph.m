//
//  POGraph.m
//  Portfolios
//
//  Created by Adam Ernst on 5/28/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POGraph.h"
#import "POHistoricalPrice.h"


@implementation POGraph

enum {
	kSignificantEveryDay,
	kSignificantEveryMonth,
	kSignificantEveryOtherMonth,
	kSignificantEverySixMonths
};

CGFloat yFromPosition(NSDecimalNumber *x, NSDecimalNumber *smallest, NSDecimalNumber *range, NSDecimalNumber *chartHeight) {
	return roundf([[chartHeight decimalNumberBySubtracting:[[[x decimalNumberBySubtracting:smallest] 
															 decimalNumberByDividingBy:range] 
															decimalNumberByMultiplyingBy:chartHeight]] floatValue]);
}

- (void)drawRect:(CGRect)rect {
    [[UIImage imageNamed:@"chart_bg.png"] drawAtPoint:CGPointMake(0.0, 0.0)];
	
	if (!historicalPrices || [historicalPrices count] <= 1) return;
	
	NSLog(@"Starting render");
	
	NSDecimalNumber *largest = [NSDecimalNumber minimumDecimalNumber];
	NSDecimalNumber *smallest = [NSDecimalNumber maximumDecimalNumber];
	
	for (POHistoricalPrice *p in historicalPrices) {
		if ([[p adjustedClose] compare:largest] == NSOrderedDescending) {
			largest = [[[p adjustedClose] retain] autorelease];
		}
		if ([[p adjustedClose] compare:smallest] == NSOrderedAscending) {
			smallest = [[[p adjustedClose] retain] autorelease];
		}
	}
	
	NSDecimalNumber *range = [largest decimalNumberBySubtracting:smallest];
	
	NSDecimalNumber *maximumRangeAllowedForIncrement = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:1 isNegative:NO];
	short roundingIncrement = 0; // 0 means "round to nearest integer"
	
	while ([range compare:maximumRangeAllowedForIncrement] == NSOrderedDescending) {
		roundingIncrement -= 1; // -1 means "round to nearest 10", and so on
		maximumRangeAllowedForIncrement = [maximumRangeAllowedForIncrement decimalNumberByMultiplyingByPowerOf10:1];
	}
	
	largest = [largest decimalNumberByRoundingAccordingToBehavior:[NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundUp scale:roundingIncrement raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO]];
	smallest = [smallest decimalNumberByRoundingAccordingToBehavior:[NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown scale:roundingIncrement raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO]];
	range = [largest decimalNumberBySubtracting:smallest];
	
	// Now the X-axis markers:
	NSInteger significance = kSignificantEveryDay;
	if ([historicalPrices count] > 15) significance = kSignificantEveryMonth;
	if ([historicalPrices count] > 150) significance = kSignificantEveryOtherMonth;
	if ([historicalPrices count] > 260) significance = kSignificantEverySixMonths;
	
	CGContextRef c = UIGraphicsGetCurrentContext();

	CGMutablePathRef p = CGPathCreateMutable();
	
	NSDecimalNumber *chartHeight = [NSDecimalNumber decimalNumberWithMantissa:114 exponent:0 isNegative:NO];
	NSDecimalNumber *chartWidth = [NSDecimalNumber decimalNumberWithMantissa:268 exponent:0 isNegative:NO];
	
	NSDateFormatter *monthNameFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[monthNameFormatter setDateFormat:@"LLL"];
	
	UIFont *xAxisFont = [UIFont boldSystemFontOfSize:12.0];
	
	[[UIColor colorWithWhite:0.0 alpha:0.65] set];
	
	NSLog(@"About to render prices");
	
	int i = 0, cnt = [historicalPrices count];
	NSDateComponents *prevComponents = nil;
	for (POHistoricalPrice *price in historicalPrices) {
		CGFloat y = yFromPosition([price adjustedClose], smallest, range, chartHeight);
		CGFloat x = [[chartWidth decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithDouble:((double)i) / (cnt - 1)] decimalValue]]] floatValue];
		
		if (i == 0) {
			CGPathMoveToPoint(p, NULL, x, y);
		} else {
			CGPathAddLineToPoint(p, NULL, x, y);
		}
		
		BOOL significant = (significance == kSignificantEveryDay);
		NSDateComponents *components = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[price date]];
		if (!significant) {
			if ([components month] != [prevComponents month]) {
				if (significance == kSignificantEveryMonth) {
					significant = YES;
				} else if (significance == kSignificantEveryOtherMonth) {
					significant = ([components month] % 2 == 1);
				} else {
					significant = ([components month] % 6 == 0);
				}
			}
		}
		
		if (significant) {
			[[UIImage imageNamed:@"vertical_chart_line.png"] drawAtPoint:CGPointMake(x, 1)];
			
			NSString *caption = nil;
			if (significance == kSignificantEveryDay) {
				caption = [NSString stringWithFormat:@"%d", [components day]];
			} else {
				caption = [monthNameFormatter stringFromDate:[price date]];
			}
			CGFloat width = [caption sizeWithFont:xAxisFont].width;
			[caption drawAtPoint:CGPointMake(MAX(roundf(x - width / 2.0), 0.0), 118) withFont:xAxisFont];
		}
		
		prevComponents = components;
		
		i++;
	}
		
	CGContextAddPath(c, p);
	[[UIColor colorWithWhite:0.0 alpha:0.25] set];
	CGContextStrokePath(c);	
	
	CGPathAddLineToPoint(p, NULL, 268, 114);
	CGPathAddLineToPoint(p, NULL, 1, 114);
	
	CGContextAddPath(c, p);
	[[UIColor colorWithWhite:0.0 alpha:0.08] set];
	CGContextFillPath(c);
	
	CGContextAddPath(c, p);
	CGContextSaveGState(c);
	CGContextClip(c);
	
	NSDecimalNumber *interval = [NSDecimalNumber decimalNumberWithMantissa:1 exponent:-roundingIncrement isNegative:NO];
	NSDecimalNumber *numberOfIntervals = [[largest decimalNumberBySubtracting:smallest] decimalNumberByDividingBy:interval];
	if ([numberOfIntervals compare:[NSDecimalNumber decimalNumberWithMantissa:4 exponent:0 isNegative:NO]] == NSOrderedDescending) {
		interval = [interval decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithMantissa:2 exponent:0 isNegative:NO]];
	}
	
	NSLog(@"Grid lines y axis");
	
	NSDecimalNumber *marker = [smallest decimalNumberByAdding:interval];
	NSDecimalNumber *m = [[marker copy] autorelease];
	while ([m compare:largest] == NSOrderedAscending) {
		CGFloat y = yFromPosition(m, smallest, range, chartHeight);
		[[UIImage imageNamed:@"horizontal_chart_line.png"] drawInRect:CGRectMake(0, y - 1, [chartWidth floatValue], 3)];
		m = [m decimalNumberByAdding:interval];
	}
	
	CGContextRestoreGState(c); // Remove clipping path
	CGPathRelease(p);
	
	[[UIColor colorWithWhite:0.0 alpha:0.65] set];
	
	NSNumberFormatter *amtFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[amtFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[amtFormatter setMinimumFractionDigits:0];
	[amtFormatter setMaximumFractionDigits:0];	
	
	NSLog(@"Y axis labels now...");
	
	m = [[marker copy] autorelease];
	while ([m compare:largest] == NSOrderedAscending) {
		CGFloat y = yFromPosition(m, smallest, range, chartHeight);
		[[amtFormatter stringFromNumber:m] drawAtPoint:CGPointMake([chartWidth floatValue] + 6.0, y - 6.0) withFont:[UIFont boldSystemFontOfSize:12.0]];
		m = [m decimalNumberByAdding:interval];
	}
	
	NSLog(@"Finished render");
}

- (void)dealloc {
    [super dealloc];
}

- (NSArray *)historicalPrices {
	return historicalPrices;
}

- (void)setHistoricalPrices:(NSArray *)a {
	[historicalPrices autorelease];
	historicalPrices = [a retain];
	[self setNeedsDisplay];
}

@end
