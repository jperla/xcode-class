//
//  POSecurities.m
//  Portfolio
//
//  Created by Adam Ernst on 11/19/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POSecurities.h"
#import "POSecurity.h"
#import "WimAdditions.h"
#import "NSString+ParsingExtensions.h"
#import "POAppDelegate.h"


NSString *POSecuritiesDidRefreshNotification = @"POSecuritiesDidRefreshNotification";
NSString *POSecuritiesFailedToRefreshNotification = @"POSecuritiesFailedToRefreshNotification";

@implementation POSecurities

#define kSecuritiesKey @"securities"
#define kSecuritiesLastRefreshKey @"lastRefresh"

static POSecurities *sharedSecurities;

+ (POSecurities *)sharedSecurities {
	@synchronized(self) {
		if (sharedSecurities == nil) {
			sharedSecurities = [[POSecurities alloc] init];
		}
	}
	return sharedSecurities;
}

+ (void)setSharedSecurities:(POSecurities *)sec {
	/* Only used at app launch time. */
	@synchronized(self) {
		if (sharedSecurities) [sharedSecurities release];
		sharedSecurities = [sec retain];
	}
}

- (id)init {
	if (self = [super init]) {
		securities = [[NSMutableDictionary dictionaryWithCapacity:16] retain];
		securitiesByTicker = [[NSMutableDictionary dictionaryWithCapacity:16] retain];
		securityLock = [[NSRecursiveLock alloc] init];
		refreshLock = [[NSLock alloc] init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	// Call the default initializer, then fill in data
	if (self = [self init]) {
		NSArray *secs = [decoder decodeObjectForKey:kSecuritiesKey];
		for (POSecurity *sec in secs) {
			[securities setObject:sec forKey:[NSString stringWithFormat:@"%@/%@", [sec uniqueIdType], [sec uniqueId]]];
			if ([[sec ticker] length]) [securitiesByTicker setObject:sec forKey:[sec ticker]];
		}
		
		lastRefresh = [[decoder decodeObjectForKey:kSecuritiesLastRefreshKey] retain];
	}
	return self;	
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[securityLock lock];
	NSArray *secs = [securities allValues];
	[securityLock unlock];
	[encoder encodeObject:secs forKey:kSecuritiesKey];
	[encoder encodeObject:lastRefresh forKey:kSecuritiesLastRefreshKey];
}

- (void)dealloc {
	[securities release];
	[securitiesByTicker release];
	[securityLock release];
	[lastRefresh release];
	[refreshLock release];
	[super dealloc];
}

/* Finds a given security; returns nil if it can't be found. */
- (POSecurity *)securityWithUniqueId:(NSString *)searchId ofType:(NSString *)searchType {
	[securityLock lock];
	POSecurity *sec = [[[securities objectForKey:[NSString stringWithFormat:@"%@/%@", searchType, searchId]] retain] autorelease];
	[securityLock unlock];
	return sec;
}

- (POSecurity *)securityWithTicker:(NSString *)searchTicker {
	[securityLock lock];
	POSecurity *sec = [[[securitiesByTicker objectForKey:searchTicker] retain] autorelease];
	[securityLock unlock];
	return sec;
}

- (void)startDelayedRefresh {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(startDelayedRefresh) withObject:nil waitUntilDone:NO];
		return;
	}
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startRefreshing) object:nil];
	[self performSelector:@selector(startRefreshing) withObject:nil afterDelay:0.5];
}

/* Create a security, unless one with the same unique id & type already exists, in which case we do nothing. */
- (POSecurity *)createSecurityWithUniqueId:(NSString *)newId ofType:(NSString *)newIdType ticker:(NSString *)newTicker type:(POSecurityType)newType name:(NSString *)newName {
	[securityLock lock];
	if ([self securityWithUniqueId:newId ofType:newIdType] != nil) return nil;
	
	POSecurity *security = [[POSecurity alloc] initWithUniqueId:newId ofType:newIdType ticker:newTicker type:newType name:newName];
	[securities setObject:security forKey:[NSString stringWithFormat:@"%@/%@", newIdType, newId]];
	if ([newTicker length]) [securitiesByTicker setObject:security forKey:newTicker];
	[security autorelease];
	[securityLock unlock];
	
	/* It would be perfectly valid to call startRefreshing directly here. 
	   But in case a number of securities are being created simultaneously, we schedule a delay. */
	[self startDelayedRefresh];
	
	return security;
}

#pragma mark Refreshing

/* Private method--externally, call startRefreshing. (This is here for KVO-compliance.) */
@synthesize refreshing, lastRefresh;

- (void)startRefreshing {
	[self performSelectorInBackground:@selector(doRefresh) withObject:nil];
}

/* Called in a background thread by startRefreshing--do not call this directly */
- (void)doRefresh {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[NSThread setThreadPriority:0.1]; // Lower priority
	
	[refreshLock lock];
	[self setRefreshing:YES];
	[(POAppDelegate *)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(beginNetworkActivity) withObject:nil waitUntilDone:YES];
	
	NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setLocale:usLocale];
	[dateFormatter setAMSymbol:@"am"];
	[dateFormatter setPMSymbol:@"pm"];
	[dateFormatter setDateFormat:@"M/d/yyyy h:mma"];
	
	NSDate *midnightToday = [NSDate date];
	NSDateComponents *components = [[NSCalendar currentCalendar] components:NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:midnightToday];
	midnightToday = [midnightToday addTimeInterval:-([components hour]*60*60 + [components minute]*60 + [components second])];
	
	[securityLock lock];
	NSArray *tickers = [securitiesByTicker allKeys];
	[securityLock unlock];
	int i;
	/* Break up into batches of 150, since Yahoo! imposes a 200-stock limit per request. */
	NSError *refreshError = nil; /* No error */
	
	for (i = 0; i < [tickers count]; i += 150) {
		NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
		
		NSString *symbols = [[tickers subarrayWithRange:NSMakeRange(i, MIN(150, [tickers count] - i))] componentsJoinedByString:@"+"];
		NSLog(@"Fetching ticker symbols %@", symbols);
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://download.finance.yahoo.com/d/quotes.csv?s=%@&f=spl1nd1t1va2rdyj1ejkgh", symbols]];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:120.0];
		[request addValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
		
		NSURLResponse *response;
		NSError *error;
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		if (!data) {
			refreshError = error;
			break;
		}
		
		NSMutableString *responseString = [[[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		[responseString replaceOccurrencesOfString:@"\r" withString:@"" options:0 range:NSMakeRange(0, [responseString length])];
		
		NSArray *lines = [responseString csvRows];
		
		for (NSArray *fields in lines) {
			if ([fields count] != 17) continue;
			
			NSString *ticker, *name, *date, *time;
			NSDecimalNumber *price, *prevClose, *change;
			NSDate *lastTrade;
			@try {
				ticker = [(NSString *)[fields objectAtIndex:0] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
				prevClose = [(NSString *)[fields objectAtIndex:1] decimalNumberByParsingWithLocale:usLocale];
				price = [(NSString *)[fields objectAtIndex:2] decimalNumberByParsingWithLocale:usLocale];
				if ([price isEqualToNumber:[NSDecimalNumber zero]]) price = nil;
				name = [NSString decodeHTMLEntities:[(NSString *)[fields objectAtIndex:3] stringByReplacingOccurrencesOfString:@"\"" withString:@""]];
				date = [(NSString *)[fields objectAtIndex:4] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
				time = [(NSString *)[fields objectAtIndex:5] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
				lastTrade = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@ %@", date, time]];
			} @catch (NSException *e) {
				NSLog(@"Failed to parse line");
				continue;
			}
			
			if (price) {
				if ([lastTrade compare:midnightToday] == NSOrderedDescending) {
					change = [price decimalNumberBySubtracting:(prevClose ? prevClose : [NSDecimalNumber zero])];
				} else {
					change = [NSDecimalNumber zero];
				}
			} else {
				change = nil;
			}
			
			POSecurity *sec = [self securityWithTicker:ticker];
			if (sec) {
				if (![[sec price] isEqualToNumber:price]) 
					[sec performSelectorOnMainThread:@selector(setPrice:) withObject:price waitUntilDone:NO];
				if (![[sec change] isEqualToNumber:change])
					[sec performSelectorOnMainThread:@selector(setChange:) withObject:change waitUntilDone:NO];
				if (![[sec name] isEqualToString:name])
					[sec performSelectorOnMainThread:@selector(setName:) withObject:name waitUntilDone:NO];
				
				[sec setVolume:[(NSString *)[fields objectAtIndex:6] decimalNumberByParsingWithLocale:usLocale]];
				[sec setAverageVolume:[(NSString *)[fields objectAtIndex:7] decimalNumberByParsingWithLocale:usLocale]];
				[sec setPeRatio:[(NSString *)[fields objectAtIndex:8] decimalNumberByParsingWithLocale:usLocale]];
				[sec setDividend:[(NSString *)[fields objectAtIndex:9] decimalNumberByParsingWithLocale:usLocale]];
				
				NSDecimalNumber *newYield = [(NSString *)[fields objectAtIndex:10] decimalNumberByParsingWithLocale:usLocale];
				if (newYield) newYield = [newYield decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100"]];
				[sec setYield:newYield];
				
				NSString *marketCapField = (NSString *)[fields objectAtIndex:11];
				NSInteger exponent = 0; /* 10 ^ 0 = 1 */
				if ([marketCapField rangeOfString:@"M"].location != NSNotFound) {
					exponent = 6;
					marketCapField = [marketCapField stringByReplacingOccurrencesOfString:@"M" withString:@""];
				} else if ([marketCapField rangeOfString:@"B"].location != NSNotFound) {
					exponent = 9;
					marketCapField = [marketCapField stringByReplacingOccurrencesOfString:@"B" withString:@""];
				}
				NSDecimalNumber *newMarketCap = [marketCapField decimalNumberByParsingWithLocale:usLocale];
				if (newMarketCap)
					newMarketCap = [newMarketCap decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithMantissa:1 exponent:exponent isNegative:NO]];
				
				[sec setMarketCap:newMarketCap];
				[sec setEarningsPerShare:[(NSString *)[fields objectAtIndex:12] decimalNumberByParsingWithLocale:usLocale]];
				[sec setLow52Week:[(NSString *)[fields objectAtIndex:13] decimalNumberByParsingWithLocale:usLocale]];
				[sec setHigh52Week:[(NSString *)[fields objectAtIndex:14] decimalNumberByParsingWithLocale:usLocale]];
				[sec setLowDay:[(NSString *)[fields objectAtIndex:15] decimalNumberByParsingWithLocale:usLocale]];
				[sec setHighDay:[(NSString *)[fields objectAtIndex:16] decimalNumberByParsingWithLocale:usLocale]];								
			} /* else {
				NSLog(@"Warning: can't find security with ticker %@, may have been deleted since started updating", ticker);
			}*/
		}
		
		[loopPool release];
	}
	
	[self setRefreshing:NO];
	if (!refreshError) {
		[self setLastRefresh:[NSDate date]];
	} else {
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) 
															   withObject:[NSNotification notificationWithName:POSecuritiesFailedToRefreshNotification object:refreshError] 
															waitUntilDone:YES];
	}
	[(POAppDelegate *)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(endNetworkActivity) withObject:nil waitUntilDone:YES];
	[refreshLock unlock];
	
	/* Notify that refresh finished regardless of error, since a *partial* refresh may have occurred. */
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) 
														   withObject:[NSNotification notificationWithName:POSecuritiesDidRefreshNotification object:nil] 
														waitUntilDone:YES];	
	
	[pool release];
}

@end
