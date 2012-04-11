//
//  POHistoricalPrice.m
//  Portfolios
//
//  Created by Adam Ernst on 5/28/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POHistoricalPrice.h"


@implementation POHistoricalPrice

@synthesize date, adjustedClose;

- (id)initWithDate:(NSDate *)aDate adjustedClose:(NSDecimalNumber *)anAdjustedClose {
	if (self = [super init]) {
		date = [aDate retain];
		adjustedClose = [anAdjustedClose retain];
	}
	return self;
}

- (void)dealloc {
	[date release];
	[adjustedClose release];
	[super dealloc];
}

@end
