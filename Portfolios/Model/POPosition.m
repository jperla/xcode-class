//
//  POPosition.m
//  Portfolio
//
//  Created by Adam Ernst on 11/18/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POPosition.h"
#import "POSecurity.h"
#import "POSecurities.h"


@implementation POPosition

#define kUniqueIdTypeKey @"security.uniqueIdType"
#define kUniqueIdKey @"security.uniqueId"
#define kUnitsKey @"units"
#define kReportedMarketValueKey @"reportedMarketValue"
#define kIsLongKey @"isLong"

@synthesize security, units, reportedMarketValue, isLong;

- (id)initWithSecurity:(POSecurity *)newSecurity {
	if (self = [super init]) {
		security = [newSecurity retain];
		units = [[NSDecimalNumber zero] retain];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		NSString *uniqueIdType = [decoder decodeObjectForKey:kUniqueIdTypeKey];
		NSString *uniqueId = [decoder decodeObjectForKey:kUniqueIdKey];
		security = [[[POSecurities sharedSecurities] securityWithUniqueId:uniqueId ofType:uniqueIdType] retain];
		
		units = [[decoder decodeObjectForKey:kUnitsKey] retain];
		reportedMarketValue = [[decoder decodeObjectForKey:kReportedMarketValueKey] retain];
		isLong = [decoder decodeBoolForKey:kIsLongKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:[security uniqueIdType] forKey:kUniqueIdTypeKey];
	[encoder encodeObject:[security uniqueId] forKey:kUniqueIdKey];
	[encoder encodeObject:units forKey:kUnitsKey];
	[encoder encodeObject:reportedMarketValue forKey:kReportedMarketValueKey];
	[encoder encodeBool:isLong forKey:kIsLongKey];
}

- (void)dealloc {
	[security release];
	[units release];
	[reportedMarketValue release];
	[super dealloc];
}

- (NSDecimalNumber *)value {
	if ([security price]) {
		return [[security price] decimalNumberByMultiplyingBy:units];
	} else {
		return [self reportedMarketValue];
	}
}

+ (NSSet *)keyPathsForValuesAffectingValue {
	return [NSSet setWithObjects:@"units", @"isLong", @"reportedMarketValue", nil];
}

- (NSDecimalNumber *)change {
	if (![security change]) return nil;
	return [[security change] decimalNumberByMultiplyingBy:units];
}

/* Convenience method to get percent change. Can return [NSDecimalNumber notANumber if value is 0. */
- (NSDecimalNumber *)percentChange {
	if ([[self value] isEqualToNumber:[NSDecimalNumber zero]]) return [NSDecimalNumber notANumber];
	return [[self change] decimalNumberByDividingBy:[self value]];
}

+ (NSSet *)keyPathsForValuesAffectingChange {
	return [NSSet setWithObjects:@"units", @"isLong", nil];
}

- (void)synchronizeWithPosition:(POPosition *)templatePosition {
	if (![NSThread isMainThread]) {
		if (![[templatePosition units] isEqualToNumber:[self units]] || ![[templatePosition reportedMarketValue] isEqualToNumber:[self reportedMarketValue]] || [templatePosition isLong] != [self isLong])
			[self performSelectorOnMainThread:@selector(synchronizeWithPosition:) withObject:templatePosition waitUntilDone:YES];
	} else {
		if (![[templatePosition units] isEqualToNumber:[self units]])
			[self setUnits:[templatePosition units]];
		if (![[templatePosition reportedMarketValue] isEqualToNumber:[self reportedMarketValue]])
			[self setReportedMarketValue:[templatePosition reportedMarketValue]];
		if ([templatePosition isLong] != [self isLong])
			[self setIsLong:[templatePosition isLong]];
	}
}

@end
