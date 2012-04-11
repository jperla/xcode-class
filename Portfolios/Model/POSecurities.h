//
//  POSecurities.h
//  Portfolio
//
//  Created by Adam Ernst on 11/19/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "POSecurity.h"

extern NSString *POSecuritiesDidRefreshNotification;
extern NSString *POSecuritiesFailedToRefreshNotification;

@interface POSecurities : NSObject <NSCoding> {
	// Internally maintain a common list of securities (in case the same security is in multiple accounts).
	// Key to this dictionary is of the form "TYPE/ID", where TYPE is the unique id type and ID is the id.
	// In most cases this will look like "CUSIP/395491039".
	NSMutableDictionary *securities;
	
	// In this dictionary, ticker is the key.
	NSMutableDictionary *securitiesByTicker;
	
	NSRecursiveLock *securityLock;
	
	NSDate *lastRefresh;
	
	NSLock *refreshLock;
	BOOL    refreshing;
}

+ (POSecurities *)sharedSecurities;
+ (void)setSharedSecurities:(POSecurities *)sec;

- (POSecurity *)securityWithUniqueId:(NSString *)searchId ofType:(NSString *)searchType;
- (POSecurity *)createSecurityWithUniqueId:(NSString *)newId ofType:(NSString *)newIdType ticker:(NSString *)newTicker type:(POSecurityType)newType name:(NSString *)newName;
- (POSecurity *)securityWithTicker:(NSString *)searchTicker;

@property (retain) NSDate *lastRefresh;

@property BOOL refreshing;
- (void)startRefreshing;

@end
