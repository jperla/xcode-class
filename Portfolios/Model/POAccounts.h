//
//  POAccounts.h
//  Portfolio
//
//  Created by Adam Ernst on 11/25/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class POAccount;

@interface POAccounts : NSObject <NSCoding> {
	NSMutableArray *accounts;
}

+ (POAccounts *)sharedAccounts;
+ (void)setSharedAccounts:(POAccounts *)accounts;

/* The 'accounts' array is main-thread only. */
- (POAccount *)objectInAccountsAtIndex:(NSUInteger)idx;
- (NSUInteger)countOfAccounts;	
- (void)insertObject:(POAccount *)obj inAccountsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAccountsAtIndex:(NSUInteger)idx;
- (void)replaceObjectInAccountsAtIndex:(NSUInteger)idx withObject:(POAccount *)obj;

- (BOOL)refreshing;
- (NSDate *)lastRefresh;
- (void)startRefreshing;

- (NSDecimalNumber *)value;
- (NSDecimalNumber *)change;

@end
