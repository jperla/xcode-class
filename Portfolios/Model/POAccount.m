//
//  POAccount.m
//  Portfolio
//
//  Created by Adam Ernst on 11/18/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POAccount.h"
#import "POPosition.h"

@interface POAccount(PrivateMethods)
- (void)addObserversForKeyPathsInPositions:(NSArray *)newPositions;
- (void)removeObserversForKeyPathsInPositions:(NSArray *)oldPositions;
@end


@implementation POAccount

static NSString *kPositionsObservationContext = @"kPositionsObservationContext";

#define kNameKey @"name"
#define kPositionsKey @"positions"

@synthesize name;

- (id)initWithName:(NSString *)newName {
	if (self = [super init]) {
		name = [newName copy];
		positions = [[NSMutableArray arrayWithCapacity:16] retain];
		[self addObserver:self forKeyPath:@"positions" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		name = [[decoder decodeObjectForKey:kNameKey] retain];
		
		positions = [[decoder decodeObjectForKey:kPositionsKey] mutableCopy];
		[self addObserver:self forKeyPath:@"positions" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
		[self addObserversForKeyPathsInPositions:positions];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:[self name] forKey:kNameKey];
	@synchronized(positions) {
		[encoder encodeObject:positions forKey:kPositionsKey];
	}
}

- (void)dealloc {
	[self removeObserversForKeyPathsInPositions:positions];
	[self removeObserver:self forKeyPath:@"positions"];
	
	[name release];
	[positions release];
	
	[super dealloc];
}

- (POPosition *)objectInPositionsAtIndex:(NSUInteger)idx {
	@synchronized(positions) {
		return [[[positions objectAtIndex:idx] retain] autorelease];
	}
	return nil;
}

- (NSUInteger)countOfPositions {
	@synchronized(positions) {
		return [positions count];
	}
	return 0;
}

- (void)insertObject:(POPosition *)obj inPositionsAtIndex:(NSUInteger)idx {
	@synchronized(positions) {
		[positions insertObject:obj atIndex:idx];
	}
}

- (void)removeObjectFromPositionsAtIndex:(NSUInteger)idx {
	@synchronized(positions) {
		[positions removeObjectAtIndex:idx];
	}
}

- (void)replaceObjectInPositionsAtIndex:(NSUInteger)idx withObject:(POPosition *)obj {
	@synchronized(positions) {
		[positions replaceObjectAtIndex:idx withObject:obj];
	}
}

- (NSDecimalNumber *)positionsTotalForKey:(NSString *)key {
	NSDecimal t = [[NSDecimalNumber zero] decimalValue];

	@synchronized(positions) {
		for (POPosition *p in positions) {
			NSDecimalNumber *d = (NSDecimalNumber *)[p valueForKey:key];
			if (!d || [d isEqualToNumber:[NSDecimalNumber notANumber]]) continue;
			NSDecimal o = [d decimalValue];
			NSDecimalAdd(&t, &t, &o, NSRoundBankers);
		}
	}
	return [NSDecimalNumber decimalNumberWithDecimal:t];	
}

- (NSDecimalNumber *)value {
	return [self positionsTotalForKey:@"value"];
}

+ (NSSet *)keyPathsForValuesAffectingValue {
	return [NSSet setWithObjects:@"positions", nil];
}

- (NSDecimalNumber *)change {
	return [self positionsTotalForKey:@"change"];
}

+ (NSSet *)keyPathsForValuesAffectingChange {
	return [NSSet setWithObjects:@"positions", nil];
}

- (void)addObserversForKeyPathsInPositions:(NSArray *)newPositions {
	if ([newPositions count] == 0) return;
	
	NSIndexSet *allIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [newPositions count])];
	[newPositions addObserver:self toObjectsAtIndexes:allIndexes forKeyPath:@"value" options:NSKeyValueObservingOptionPrior context:kPositionsObservationContext];
	[newPositions addObserver:self toObjectsAtIndexes:allIndexes forKeyPath:@"change" options:NSKeyValueObservingOptionPrior context:kPositionsObservationContext];
}

- (void)removeObserversForKeyPathsInPositions:(NSArray *)oldPositions {
	if ([oldPositions count] == 0) return;
	
	NSIndexSet *allIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [oldPositions count])];
	[oldPositions removeObserver:self fromObjectsAtIndexes:allIndexes forKeyPath:@"value"];
	[oldPositions removeObserver:self fromObjectsAtIndexes:allIndexes forKeyPath:@"change"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == self && [keyPath isEqualToString:@"positions"]) {
		[self removeObserversForKeyPathsInPositions:[change objectForKey:NSKeyValueChangeOldKey]];
		[self addObserversForKeyPathsInPositions:[change objectForKey:NSKeyValueChangeNewKey]];
	} else if (context == kPositionsObservationContext) {
		NSAssert([keyPath isEqualToString:@"value"] || [keyPath isEqualToString:@"change"], @"Unrecognized keyPath when observing positions");
		if ([[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue]) {
			[self willChangeValueForKey:keyPath];
		} else {
			[self didChangeValueForKey:keyPath];
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
