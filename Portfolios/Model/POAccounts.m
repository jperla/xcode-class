//
//  POAccounts.m
//  Portfolio
//
//  Created by Adam Ernst on 11/25/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POAccounts.h"
#import "POAccount.h"
#import "POAutomaticAccount.h"

#define kAccountsKey @"accounts"

@interface POAccounts(PrivateMethods)
- (void)addObserversForKeyPathsInAccounts:(NSArray *)newAccounts;
- (void)removeObserversForKeyPathsInAccounts:(NSArray *)oldAccounts;
@end


@implementation POAccounts

static NSString *kAccountsObservationContext = @"kAccountsObservationContext";

static POAccounts *sharedAccounts = nil;

+ (POAccounts *)sharedAccounts {
	@synchronized(self) {
		if (sharedAccounts == nil) {
			sharedAccounts = [[POAccounts alloc] init];
		}
	}
	return sharedAccounts;
}

+ (void)setSharedAccounts:(POAccounts *)accounts {
	/* This will screw up observers, so it's only used at app launch time. */
	@synchronized(self) {
		if (sharedAccounts) [sharedAccounts release];
		sharedAccounts = [accounts retain];
	}
}

- (id)init {
	if (self = [super init]) {
		accounts = [[NSMutableArray alloc] initWithCapacity:8];
		[self addObserver:self forKeyPath:@"accounts" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		accounts = [[decoder decodeObjectForKey:kAccountsKey] mutableCopy];
		[self addObserver:self forKeyPath:@"accounts" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
		[self addObserversForKeyPathsInAccounts:accounts];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:accounts forKey:kAccountsKey];
}

- (void)dealloc {
	[self removeObserversForKeyPathsInAccounts:accounts];
	[self removeObserver:self forKeyPath:@"accounts"];
	
	[accounts release];
	[super dealloc];
}

- (POAccount *)objectInAccountsAtIndex:(NSUInteger)idx {
	return [accounts objectAtIndex:idx];
}

- (NSUInteger)countOfAccounts {
	return [accounts count];
}

- (void)insertObject:(POAccount *)obj inAccountsAtIndex:(NSUInteger)idx {
	[accounts insertObject:obj atIndex:idx];
}

- (void)removeObjectFromAccountsAtIndex:(NSUInteger)idx {
	[accounts removeObjectAtIndex:idx];
}

- (void)replaceObjectInAccountsAtIndex:(NSUInteger)idx withObject:(POAccount *)obj {
	[accounts replaceObjectAtIndex:idx withObject:obj];
}

- (NSDecimalNumber *)accountsTotalForKey:(NSString *)key {
	NSDecimal t = [[NSDecimalNumber zero] decimalValue];
	for (POAccount *a in accounts) {
		NSDecimal o = [(NSDecimalNumber *)[a valueForKey:key] decimalValue];
		NSDecimalAdd(&t, &t, &o, NSRoundBankers);
	}
	return [NSDecimalNumber decimalNumberWithDecimal:t];	
}

- (NSDecimalNumber *)value {
	return [self accountsTotalForKey:@"value"];
}

+ (NSSet *)keyPathsForValuesAffectingValue {
	return [NSSet setWithObjects:@"accounts", nil];
}

- (NSDecimalNumber *)change {
	return [self accountsTotalForKey:@"change"];
}

+ (NSSet *)keyPathsForValuesAffectingChange {
	return [NSSet setWithObjects:@"accounts", nil];
}

- (BOOL)refreshing {
	for (POAccount *acc in accounts) {
		if ([[acc class] isSubclassOfClass:[POAutomaticAccount class]] && [(POAutomaticAccount *)acc refreshing])
			return YES;
	}
	
	return NO;
}

- (NSDate *)lastRefresh {
	/* Return NEWEST refresh date among all automatic accounts */
	NSDate *last = [NSDate distantPast];
	for (POAccount *acc in accounts) {
		if (![[acc class] isSubclassOfClass:[POAutomaticAccount class]]) continue;
		if (![(POAutomaticAccount *)acc lastRefresh]) continue; /* No refresh yet */
		
		last = [last laterDate:[(POAutomaticAccount *)acc lastRefresh]];
	}
	
	if ([last isEqualToDate:[NSDate distantPast]]) return nil;
	
	return last;
}

- (void)startRefreshing {
	/* Convenience method to start refreshing all automatic accounts that aren't currently doing so. */
	for (POAccount *account in accounts) {
		if (![[account class] isSubclassOfClass:[POAutomaticAccount class]]) continue;
		if (![(POAutomaticAccount *)account refreshing])
			[(POAutomaticAccount *)account startRefreshing];
	}
}

- (void)addObserversForKeyPathsInAccounts:(NSArray *)newAccounts {
	if ([newAccounts count] == 0) return;
	
	NSIndexSet *allIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [newAccounts count])];
	[newAccounts addObserver:self toObjectsAtIndexes:allIndexes forKeyPath:@"value" options:NSKeyValueObservingOptionPrior context:kAccountsObservationContext];
	[newAccounts addObserver:self toObjectsAtIndexes:allIndexes forKeyPath:@"change" options:NSKeyValueObservingOptionPrior context:kAccountsObservationContext];
	[newAccounts addObserver:self toObjectsAtIndexes:allIndexes forKeyPath:@"refreshing" options:NSKeyValueObservingOptionPrior context:kAccountsObservationContext];
	[newAccounts addObserver:self toObjectsAtIndexes:allIndexes forKeyPath:@"lastRefresh" options:NSKeyValueObservingOptionPrior context:kAccountsObservationContext];
}

- (void)removeObserversForKeyPathsInAccounts:(NSArray *)oldAccounts {
	if ([oldAccounts count] == 0) return;
	
	NSIndexSet *allIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [oldAccounts count])];
	[oldAccounts removeObserver:self fromObjectsAtIndexes:allIndexes forKeyPath:@"value"];
	[oldAccounts removeObserver:self fromObjectsAtIndexes:allIndexes forKeyPath:@"change"];
	[oldAccounts removeObserver:self fromObjectsAtIndexes:allIndexes forKeyPath:@"refreshing"];
	[oldAccounts removeObserver:self fromObjectsAtIndexes:allIndexes forKeyPath:@"lastRefresh"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == self && [keyPath isEqualToString:@"accounts"]) {
		[self removeObserversForKeyPathsInAccounts:[change objectForKey:NSKeyValueChangeOldKey]];
		[self addObserversForKeyPathsInAccounts:[change objectForKey:NSKeyValueChangeNewKey]];
	} else if (context == kAccountsObservationContext) {
		if ([keyPath isEqualToString:@"refreshing"]) {
			/* Could this account actually change refreshing? */
			if (![[(NSObject *)object class] isSubclassOfClass:[POAutomaticAccount class]])
				return;
			if ([(POAutomaticAccount *)object refreshing] != [self refreshing])
				return;
			
			if ([self refreshing]) {
				/* Is there another account that's refreshing? If so this can't change the value */
				for (POAccount *acc in accounts) {
					if (acc != object && [[acc class] isSubclassOfClass:[POAutomaticAccount class]] && [(POAutomaticAccount *)acc refreshing]) {
						return;
					}
				}
			}
		} else {
			NSAssert(([keyPath isEqualToString:@"change"] || [keyPath isEqualToString:@"value"] || [keyPath isEqualToString:@"lastRefresh"]), @"Unrecognized keyPath when observing accounts");
		}
		
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
