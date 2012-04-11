//
//  POSecurity.h
//  Portfolio
//
//  Created by Adam Ernst on 11/18/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	POSecurityTypeStock,
	POSecurityTypeMutualFund,
	POSecurityTypeDebt,
	POSecurityTypeOption,
	POSecurityTypeOther
} POSecurityType;

@interface POSecurity : NSObject <NSCoding, NSCopying> {
	NSString *uniqueId;
	NSString *uniqueIdType;
	POSecurityType type;
	NSString *ticker;
	NSString *name;
	
	NSDecimalNumber *price;
	NSDecimalNumber *change;
	
	NSDate *lastNewsUpdate;
	NSArray *news;
	
	// Stats only for stocks:
	NSDecimalNumber *volume;
	NSDecimalNumber *averageVolume;
	NSDecimalNumber *peRatio;
	NSDecimalNumber *dividend;
	NSDecimalNumber *yield;
	NSDecimalNumber *marketCap;
	NSDecimalNumber *earningsPerShare;
	
	NSDecimalNumber *high52Week;
	NSDecimalNumber *low52Week;
	NSDecimalNumber *highDay;
	NSDecimalNumber *lowDay;
	
	// Stats only for mutual funds:
	// None yet!
	
	// Used while parsing the stats:
	NSURLConnection *statsConnection;
	NSMutableData *statsConnectionData;
	NSMutableData *statsConnectionResponse;
	
	// Cache for historical prices
	NSMutableArray *historicalPricesCache;
	
	// Used while parsing the news:
	NSURLConnection *newsConnection;
	NSMutableData *newsConnectionData;
	NSURLResponse *newsConnectionResponse;	
	
	NSMutableArray *newNews;
	NSMutableString *currentElement;
	NSMutableString *currentTitle;
	NSMutableString *currentLink;
}

@property (nonatomic, readonly, copy) NSString *uniqueId;
@property (nonatomic, readonly, copy) NSString *uniqueIdType;
@property (nonatomic, readonly, copy) NSString *ticker;
@property (nonatomic) POSecurityType type;
@property (nonatomic, copy) NSString *name;

@property (nonatomic, retain) NSDecimalNumber *price;
@property (nonatomic, retain) NSDecimalNumber *change;

/* Statistics are thread-safe since they are updated much more frequently
 so we want to properly do it in the background without bothering the main thread. */
/* Be careful-- if you observe them, you might get a notification on a background thread
 (this is Cocoa standard behavior) */
@property (retain) NSDecimalNumber *volume;
@property (retain) NSDecimalNumber *averageVolume;
@property (retain) NSDecimalNumber *peRatio;
@property (retain) NSDecimalNumber *dividend;
@property (retain) NSDecimalNumber *yield;
@property (retain) NSDecimalNumber *marketCap;
@property (retain) NSDecimalNumber *earningsPerShare;

@property (retain) NSDecimalNumber *high52Week;
@property (retain) NSDecimalNumber *low52Week;
@property (retain) NSDecimalNumber *highDay;
@property (retain) NSDecimalNumber *lowDay;

- (id)initWithUniqueId:(NSString *)newId ofType:(NSString *)newIdType ticker:(NSString *)newTicker type:(POSecurityType)newType name:(NSString *)newName;

- (NSArray *)historicalPricesFromDate:(NSDate *)fromDate;

- (BOOL)isUpdatingNews;
- (void)startUpdatingNews;
- (NSArray *)news;
- (NSDate *)lastNewsUpdate;

@end
