//
//  POAutomaticAccount.h
//  Portfolio
//
//  Created by Adam Ernst on 12/1/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Security/Security.h>
#import "POAccount.h"

extern NSString *POAutomaticAccountErrorDomain;
extern NSString *POAutomaticAccountModifyPositionsException;
extern NSString *POAutomaticAccountRefreshErrorTranscriptKey;

enum {
	kPOAutomaticAccountMissingPasswordError,
	kPOAutomaticAccountRequestFailedError,
	kPOAutomaticAccountBadLogonError,
	kPOAutomaticAccountServerError,
	kPOAutomaticAccountSecuritiesParsingFailed,
	kPOAutomaticAccountPositionsParsingFailed,
	kPOAutomaticAccountBalancesParsingFailed
};

@interface POAutomaticAccount : POAccount <NSCoding> {
	NSString *userId;
	NSString *brokerId;
	NSString *acctId;
	NSString *url;
	
	NSDate   *lastRefresh;
	NSError  *lastError;
	BOOL      refreshDisabled;
	BOOL      refreshing;
	NSLock   *refreshLock;
	
	NSDecimalNumber *cashBalance;
	NSDecimalNumber *marginBalance;
	NSDecimalNumber *shortBalance;	
}

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *brokerId;
@property (nonatomic, copy) NSString *acctId;

@property (nonatomic, retain) NSDate *lastRefresh;
@property (nonatomic, retain) NSError *lastError;

@property (nonatomic, retain) NSDecimalNumber *cashBalance;
@property (nonatomic, retain) NSDecimalNumber *marginBalance;
@property (nonatomic, retain) NSDecimalNumber *shortBalance;

- (id)initWithUrl:(NSString *)newUrl userId:(NSString *)newUserId brokerId:(NSString *)newBrokerId acctId:(NSString *)newAcctId name:(NSString *)newName;

- (void)setPassword:(NSString *)password;

@property (nonatomic) BOOL refreshing;
- (void)startRefreshing;

@property (nonatomic) BOOL refreshDisabled;

@end
