//
//  POAppDelegate.h
//  Portfolio
//
//  Created by Adam Ernst on 11/18/08.
//  Copyright cosmicsoft 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class POAccount;

@interface POAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
	UINavigationController *navigationController;
	
	NSInteger networkActivityCount;
	
	BOOL pendingAccountsRefresh;
	BOOL hasUpdatedAllAccounts;
	POAccount *onlyRefreshAccount;
	
	BOOL notifiedOfSecuritiesRefreshError;
}

- (void)schedulePendingAccountsRefresh;
- (void)schedulePendingRefreshForAccount:(POAccount *)account;

- (void)beginNetworkActivity;
- (void)endNetworkActivity;

@end
