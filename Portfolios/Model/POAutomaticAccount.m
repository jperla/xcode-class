//
//  POAutomaticAccount.m
//  Portfolio
//
//  Created by Adam Ernst on 12/1/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POAutomaticAccount.h"
#import "OfxRequest.h"
#import "SgmlDocument.h"
#import "POSecurities.h"
#import "SgmlAggregateElement.h"
#import "SgmlContentElement.h"
#import "POPosition.h"
#import "POAppDelegate.h"
#import "POSecurity.h"

NSString *POAutomaticAccountErrorDomain = @"POAutomaticAccountErrorDomain";
NSString *POAutomaticAccountModifyPositionsException = @"POAutomaticAccountModifyPositionsException";
NSString *POAutomaticAccountRefreshErrorTranscriptKey = @"POAutomaticAccountRefreshErrorTranscriptKey";

@implementation POAutomaticAccount

#define kUrlKey @"url"
#define kUserIdKey @"userId"
#define kBrokerIdKey @"brokerId"
#define kAcctIdKey @"acctId"
#define kLastRefreshKey @"lastRefresh"
#define kLastErrorKey @"lastError"
#define kCashBalanceKey @"cashBalance"
#define kMarginBalanceKey @"marginBalance"
#define kShortBalanceKey @"shortBalance"
#define kRefreshDisabledKey @"refreshDisabled"

@synthesize url, userId, brokerId, acctId, lastRefresh, lastError, cashBalance, marginBalance, shortBalance;

- (id)initWithUrl:(NSString *)newUrl userId:(NSString *)newUserId brokerId:(NSString *)newBrokerId acctId:(NSString *)newAcctId name:(NSString *)newName {
	if (self = [super initWithName:newName]) {
		url = [newUrl copy];
		userId = [newUserId copy];
		brokerId = [newBrokerId copy];
		acctId = [newAcctId copy];
		
		cashBalance = [[NSDecimalNumber zero] retain];
		marginBalance = [[NSDecimalNumber zero] retain];
		shortBalance = [[NSDecimalNumber zero] retain];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
		url = [[decoder decodeObjectForKey:kUrlKey] retain];
		userId = [[decoder decodeObjectForKey:kUserIdKey] retain];
		brokerId = [[decoder decodeObjectForKey:kBrokerIdKey] retain];
		acctId = [[decoder decodeObjectForKey:kAcctIdKey] retain];
		lastRefresh = [[decoder decodeObjectForKey:kLastRefreshKey] retain];
		lastError = [[decoder decodeObjectForKey:kLastErrorKey] retain];
		
		cashBalance = [[decoder decodeObjectForKey:kCashBalanceKey] retain];
		marginBalance = [[decoder decodeObjectForKey:kMarginBalanceKey] retain];
		shortBalance = [[decoder decodeObjectForKey:kShortBalanceKey] retain];
		
		refreshDisabled = [decoder decodeBoolForKey:kRefreshDisabledKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	
	[encoder encodeObject:[self url] forKey:kUrlKey];
	[encoder encodeObject:[self userId] forKey:kUserIdKey];
	[encoder encodeObject:[self brokerId] forKey:kBrokerIdKey];
	[encoder encodeObject:[self acctId] forKey:kAcctIdKey];
	[encoder encodeObject:[self lastRefresh] forKey:kLastRefreshKey];
	[encoder encodeObject:[self lastError] forKey:kLastErrorKey];
	
	[encoder encodeObject:[self cashBalance] forKey:kCashBalanceKey];
	[encoder encodeObject:[self marginBalance] forKey:kMarginBalanceKey];
	[encoder encodeObject:[self shortBalance] forKey:kShortBalanceKey];
	
	[encoder encodeBool:[self refreshDisabled] forKey:kRefreshDisabledKey];
}

- (void)dealloc {
	[url release];
	[userId release];
	[brokerId release];
	[acctId release];
	[lastRefresh release];
	[lastError release];
	
	[cashBalance release];
	[marginBalance release];
	[shortBalance release];
	
	[super dealloc];
}

#pragma mark Balances Tracking

- (NSDecimalNumber *)balancesTotal {
	return [[cashBalance decimalNumberByAdding:marginBalance] decimalNumberByAdding:shortBalance];
}

+ (NSSet *)keyPathsForValuesAffectingBalancesTotal {
	return [NSSet setWithObjects:@"cashBalance", @"marginBalance", @"shortBalance", nil];
}

- (NSDecimalNumber *)value {
	return [[self positionsTotalForKey:@"value"] decimalNumberByAdding:[self balancesTotal]];
}

+ (NSSet *)keyPathsForValuesAffectingValue {
	return [NSSet setWithObjects:@"positions", @"balancesTotal", nil];
}

#pragma mark Error Management

- (NSError *)errorWithCode:(NSInteger)code underlyingError:(NSError *)underlying transcript:(NSString *)transcript {
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
	if (underlying)
		[userInfo setObject:underlying forKey:NSUnderlyingErrorKey];
	if (transcript)
		[userInfo setObject:transcript forKey:POAutomaticAccountRefreshErrorTranscriptKey];
	
	return [NSError errorWithDomain:POAutomaticAccountErrorDomain 
							   code:code
						   userInfo:userInfo];
}

#pragma mark Refreshing

- (void)setPassword:(NSString *)newPassword {
#if TARGET_IPHONE_SIMULATOR
	/* Totally insecure, for simulator only: */
	[[NSUserDefaults standardUserDefaults] setObject:newPassword forKey:[url stringByAppendingFormat:@"-%@", acctId]];
#else
	NSData *passwordData = [newPassword dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableDictionary *searchAttribs = [NSMutableDictionary dictionaryWithCapacity:6];
	[searchAttribs setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	[searchAttribs setObject:(id)userId forKey:(id)kSecAttrAccount];
	[searchAttribs setObject:(id)[url stringByAppendingFormat:@"-%@", acctId] forKey:(id)kSecAttrService];
	[searchAttribs setObject:(id)passwordData forKey:(id)kSecValueData];
	OSStatus result = SecItemAdd((CFDictionaryRef)searchAttribs, NULL);
	if (result == errSecDuplicateItem) {
		[searchAttribs removeObjectForKey:(id)kSecValueData];
		result = SecItemUpdate((CFDictionaryRef)searchAttribs, (CFDictionaryRef)[NSDictionary dictionaryWithObject:(id)passwordData forKey:(id)kSecValueData]);
	}
	
	if (result != noErr) {
		NSLog(@"Warning: unable to store password in keychain, error %d", result);
	}
#endif
}

/* Private method--externally, call startRefreshing. (This is here for KVO-compliance.) */
@synthesize refreshing, refreshDisabled;

- (void)startRefreshing {
	[self performSelectorInBackground:@selector(doRefresh) withObject:nil];
}

- (void)addPositions:(NSArray *)add removePositions:(NSArray *)remove {
	/* Merge the new positions array into positions. */
	@synchronized(positions) {
		if ([remove count]) {
			NSMutableIndexSet *removals = [NSMutableIndexSet indexSet];
			for (POPosition *pos in remove) {
				[removals addIndex:[positions indexOfObject:pos]];
			}
			
			[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:removals forKey:@"positions"];
			[positions removeObjectsAtIndexes:removals];
			[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:removals forKey:@"positions"];
		}
		
		if ([add count]) {
			NSIndexSet *insertions = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([positions count], [add count])];
			
			[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:insertions forKey:@"positions"];
			[positions addObjectsFromArray:add];
			[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:insertions forKey:@"positions"];
		}
	}
}

- (BOOL)attemptRefreshWithRequest:(OfxRequest *)request error:(NSError **)error {
	NSError *err = nil;
	NSString *transcript = nil;
	SgmlDocument *response = [request sendRequestReturningError:&err transcript:&transcript];
	if (!response) {
		*error = [self errorWithCode:kPOAutomaticAccountRequestFailedError underlyingError:err transcript:transcript];
		return NO;
	}
	
	if (![OfxRequest ofxSignOnSuccessful:response error:&err]) {
		*error = [self errorWithCode:(([err code] == kOfxRequestBadPasswordError) ? kPOAutomaticAccountBadLogonError : kPOAutomaticAccountServerError) underlyingError:err transcript:transcript];
		return NO;
	}
	
	if (![OfxRequest ofxResponseSuccessful:response statusPath:@"/OFX/INVSTMTMSGSRSV1/INVSTMTTRNRS/STATUS" error:&err]) {
		*error = [self errorWithCode:kPOAutomaticAccountServerError underlyingError:err transcript:transcript];
		return NO;
	}
	
	NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
	
	NSArray *securities = [response elementsForXPath:@"/OFX/SECLISTMSGSRSV1/SECLIST/*/SECINFO" error:&err];
	if (!securities) {
		*error = [self errorWithCode:kPOAutomaticAccountSecuritiesParsingFailed underlyingError:err transcript:transcript];
		return NO;
	}
	
	for (SgmlAggregateElement *sec in securities) {
		NSString *securityType = [[sec parent] name];
		NSString *secId = [[[sec firstSubElementWithName:@"SECID"] firstSubElementWithName:@"UNIQUEID"] content];
		NSString *secIdType = [[[sec firstSubElementWithName:@"SECID"] firstSubElementWithName:@"UNIQUEIDTYPE"] content];
		
		if ([[POSecurities sharedSecurities] securityWithUniqueId:secId ofType:secIdType] != nil) continue;
		
		NSString *ticker = [[sec firstSubElementWithName:@"TICKER"] content];
		NSString *secName = [[sec firstSubElementWithName:@"SECNAME"] content];
		POSecurityType type = POSecurityTypeOther;
		if ([securityType isEqualToString:@"MFINFO"]) {
			type = POSecurityTypeMutualFund;
		} else if ([securityType isEqualToString:@"DEBTINFO"]) {
			type = POSecurityTypeDebt;
		} else if ([securityType isEqualToString:@"OPTINFO"]) {
			type = POSecurityTypeOption;
		} else if ([securityType isEqualToString:@"STOCKINFO"]) {
			type = POSecurityTypeStock;
		}
		
		/* Creating a security after checking for its existence doesn't create a race condition--
		 POSecurities has a lock and won't create a security if it already exists. */
		[[POSecurities sharedSecurities] createSecurityWithUniqueId:secId ofType:secIdType ticker:ticker type:type name:secName];
	}
	
	NSArray *positionEntities = [NSArray arrayWithObjects:@"DEBT", @"MF", @"OPT", @"OTHER", @"STOCK", nil];
	POSecurityType positionTypes[] = {POSecurityTypeDebt, POSecurityTypeMutualFund, POSecurityTypeOption, POSecurityTypeOther, POSecurityTypeStock};
	
	NSMutableArray *downloadedPositions = [NSMutableArray arrayWithCapacity:[self countOfPositions]];
	
	for (int i = 0; i < [positionEntities count]; i++) {
		NSArray *pos = [response elementsForXPath:[NSString stringWithFormat:@"/OFX/INVSTMTMSGSRSV1/INVSTMTTRNRS/INVSTMTRS/INVPOSLIST/POS%@", [positionEntities objectAtIndex:i]] error:&err];
		if (!pos) {
			*error = [self errorWithCode:kPOAutomaticAccountPositionsParsingFailed underlyingError:err transcript:transcript];
			return NO;
		}
		
		for (SgmlAggregateElement *p in pos) {
			SgmlAggregateElement *invPos = (SgmlAggregateElement *)[p firstSubElementWithName:@"INVPOS"];
			
			SgmlAggregateElement *e = (SgmlAggregateElement *)[invPos firstSubElementWithName:@"SECID"];
			NSString *uid = [[e firstSubElementWithName:@"UNIQUEID"] content];
			NSString *uidtype = [[e firstSubElementWithName:@"UNIQUEIDTYPE"] content];
			
			POSecurity *security = [[POSecurities sharedSecurities] securityWithUniqueId:uid ofType:uidtype];
			if (!security) continue; // TODO handle better?
			
			if ([security type] != positionTypes[i]) {
				/* Not sure what to do with this! */
				NSLog(@"Unexpected position<->security type mismatch! Position is of type %d but security is of type %d, security uniqueID %@ with ticker %@", [security type], positionTypes[i], [security uniqueId], [security ticker]);
				/* Proceed anyway I guess. */
			}
			
			BOOL isLong = [[[invPos firstSubElementWithName:@"POSTYPE"] content] isEqualToString:@"LONG"];
			
			NSDecimalNumber *units = [NSDecimalNumber decimalNumberWithString:[[invPos firstSubElementWithName:@"UNITS"] content] locale:usLocale];
			NSDecimalNumber *marketValue = [NSDecimalNumber decimalNumberWithString:[[invPos firstSubElementWithName:@"MKTVAL"] content] locale:usLocale];
			
			/* Sometimes positions with qty 0 come with the response; also catch various other error conditions here. */
			if (!units || [units isEqualToNumber:[NSDecimalNumber zero]] || [units isEqualToNumber:[NSDecimalNumber notANumber]])
				continue;
			
			POPosition *newPosition = [[POPosition alloc] initWithSecurity:security];
			[newPosition setUnits:units];
			[newPosition setReportedMarketValue:marketValue];
			[newPosition setIsLong:isLong];
			[downloadedPositions addObject:newPosition];
			[newPosition release];
		}
	}
	
	NSMutableDictionary *existingPositions = [NSMutableDictionary dictionaryWithCapacity:[self countOfPositions]];
	for (POPosition *pos in [self mutableArrayValueForKey:@"positions"]) {
		[existingPositions setObject:pos forKey:[pos security]];
	}
	
	NSMutableArray *newPositions = [NSMutableArray arrayWithCapacity:4];
	for (POPosition *pos in downloadedPositions) {
		POPosition *old = [existingPositions objectForKey:[pos security]];
		if (old) {
			[old synchronizeWithPosition:pos];
			[existingPositions removeObjectForKey:[pos security]];
		} else {
			[newPositions addObject:pos];
		}
	}
	
	[self addPositions:newPositions removePositions:[existingPositions allValues]];
	
	NSArray *bals = [response elementsForXPath:@"/OFX/INVSTMTMSGSRSV1/INVSTMTTRNRS/INVSTMTRS/INVBAL" error:&err];
	if (!bals || [bals count] != 1) {
		*error = [self errorWithCode:kPOAutomaticAccountBalancesParsingFailed underlyingError:err transcript:transcript];
		return NO;
	}
	
	SgmlAggregateElement *bal = [bals objectAtIndex:0];
	
	[self performSelectorOnMainThread:@selector(setCashBalance:) withObject:[NSDecimalNumber decimalNumberWithString:[[bal firstSubElementWithName:@"AVAILCASH"] content] locale:usLocale] waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(setMarginBalance:) withObject:[NSDecimalNumber decimalNumberWithString:[[bal firstSubElementWithName:@"MARGINBALANCE"] content] locale:usLocale] waitUntilDone:NO];
	[self performSelectorOnMainThread:@selector(setShortBalance:) withObject:[NSDecimalNumber decimalNumberWithString:[[bal firstSubElementWithName:@"SHORTBALANCE"] content] locale:usLocale] waitUntilDone:NO];	
	
	return YES;
}

- (void)doRefresh {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[refreshLock lock];
	
	/* Check if refresh is disabled. Check here instead of startRefresh
	   in case many refresh requests are queued up--this way we're protected
	   by refreshLock in case the first one fails. */
	if ([self refreshDisabled]) {
		[refreshLock unlock];
		[pool release];
		return;
	}
	
	NSString *password;
#if TARGET_IPHONE_SIMULATOR
	password = [[NSUserDefaults standardUserDefaults] objectForKey:[url stringByAppendingFormat:@"-%@", acctId]];
	if (!password || [password length] == 0) {
		[self setLastError:[self errorWithCode:kPOAutomaticAccountMissingPasswordError underlyingError:nil transcript:nil]];
		[refreshLock unlock];
		[pool release];
		return;
	}
#else
	NSMutableDictionary *searchAttribs = [NSMutableDictionary dictionaryWithCapacity:6];
	[searchAttribs setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	[searchAttribs setObject:(id)userId forKey:(id)kSecAttrAccount];
	[searchAttribs setObject:(id)[url stringByAppendingFormat:@"-%@", acctId] forKey:(id)kSecAttrService];
	[searchAttribs setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
	CFDataRef passwordData;
	OSStatus result = SecItemCopyMatching((CFDictionaryRef)searchAttribs, (CFTypeRef *) &passwordData);
	
	if (result != noErr) {
		[self setLastError:[self errorWithCode:kPOAutomaticAccountMissingPasswordError underlyingError:nil transcript:nil]];
		[refreshLock unlock];
		[pool release];
		return;
	}
	
	password = [[[NSString alloc] initWithData:(NSData *)passwordData encoding:NSUTF8StringEncoding] autorelease];
#endif
	
	[self setRefreshing:YES];
	[(POAppDelegate *)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(beginNetworkActivity) withObject:nil waitUntilDone:YES];
	
	[NSThread setThreadPriority:0.1]; // Lower priority
	NSLog(@"Starting refresh in %@", name);
	
	OfxRequest *request = [OfxRequest requestForPositionsWithUrl:url userId:userId password:password brokerId:brokerId acctId:acctId];
	NSError *error = nil;
	
	// Try the request twice.
	BOOL success = [self attemptRefreshWithRequest:request error:&error];
	if (!success) success = [self attemptRefreshWithRequest:request error:&error];
	
	if (!success) {
		if ([error code] == kPOAutomaticAccountBadLogonError) {
			// Prevent hammering the server with the same bad password.
			[self setRefreshDisabled:YES];
		}
		
		[self setLastError:error];
	} else {
		[self setLastError:nil];
		[self setLastRefresh:[NSDate date]];
	}
	
	/* If you're changing this end routine, change it in the error conditions above too. */
	[self setRefreshing:NO];
	[(POAppDelegate *)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(endNetworkActivity) withObject:nil waitUntilDone:YES];
	[refreshLock unlock];
	[pool release];
	NSLog(@"Done refreshing in %@", name);
}

@end
