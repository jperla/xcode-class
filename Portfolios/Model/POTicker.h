//
//  POTicker.h
//  Portfolios
//
//  Created by Adam Ernst on 5/8/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "sqlite3.h"
#import <Foundation/Foundation.h>


@interface POTicker : NSObject {
	NSString *symbol;
	NSString *name;
	NSString *exchange;
}

// Search built-in ticker list. Thread-safe.
+ (NSArray *)localTickersContaining:(NSString *)searchString;
// Search remote ticker list. Also thread-safe.
+ (NSArray *)remoteTickersContaining:(NSString *)searchString;

+ (POTicker *)tickerWithSymbol:(NSString *)symb;

- (id)initWithRow:(sqlite3_stmt  *)stmt;
- (id)initWithSymbol:(NSString *)aSymbol name:(NSString *)aName exchange:(NSString *)anExchange;

// For simplicity we retain, not copy, these strings. Don't 
// pass mutable strings in and then mutate them!
@property (nonatomic, retain, readonly) NSString *symbol;
@property (nonatomic, retain, readonly) NSString *name;
@property (nonatomic, retain, readonly) NSString *exchange;

@end
