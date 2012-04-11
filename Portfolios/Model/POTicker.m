//
//  POTicker.m
//  Portfolios
//
//  Created by Adam Ernst on 5/8/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POTicker.h"
#import "WimAdditions.h"

static sqlite3 *handle = nil;
// We can pass handle across threads as long as only
// one is using it at a time and all statements are 
// finalized after use.
static NSLock *handleLock = nil;

#define MAX_PATH 512

@implementation POTicker

+ (void)initialize {
	if ( self == [POTicker class] ) {
		if (handleLock == nil) {
			handleLock = [[NSLock alloc] init];
		}
    }	
}

@synthesize symbol, name, exchange;

- (id)initWithRow:(sqlite3_stmt *)stmt {
	if (self = [super init]) {
		int i, count;
		count = sqlite3_column_count(stmt);
		NSParameterAssert(count > 0);
		for (i = 0; i < count; i++) {
			char *columnName = (char *) sqlite3_column_name(stmt, i);
			
			if (strcmp(columnName, "symbol") == 0)
				symbol = [[NSString stringWithCString:(char *)sqlite3_column_text(stmt, i) encoding:NSUTF8StringEncoding] retain];
			else if (strcmp(columnName, "name") == 0)
				name = [[NSString stringWithCString:(char *)sqlite3_column_text(stmt, i) encoding:NSUTF8StringEncoding] retain];
			else if (strcmp(columnName, "exchange") == 0)
				exchange = [[NSString stringWithCString:(char *)sqlite3_column_text(stmt, i) encoding:NSUTF8StringEncoding] retain];
		}
	}
	
	return self;	
}

- (id)initWithSymbol:(NSString *)aSymbol name:(NSString *)aName exchange:(NSString *)anExchange {
	if (self = [super init]) {
		symbol = [aSymbol retain];
		name = [aName retain];
		exchange = [anExchange retain];
	}
	return self;
}

- (void)dealloc {
	[symbol release];
	[name release];
	[exchange release];
	
	[super dealloc];
}

+ (void)initHandle {
	if (handle == nil) {
		CFURLRef url = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("tickers"), CFSTR("db"), NULL);
		if (!url) return;
		
		unsigned char *path = malloc(MAX_PATH);
		Boolean result = CFURLGetFileSystemRepresentation(url, true, path, MAX_PATH);
		CFRelease(url);
		
		if (!result) {
			free(path);
			return;
		}
		
		sqlite3_open((char *) path, &handle);
		free(path);		
	}
}

+ (NSArray *)localTickersContaining:(NSString *)searchString {
	if ([searchString length] == 0) return [NSArray array];
	
	[handleLock lock];
	[POTicker initHandle];
	
	sqlite3_stmt *search_ticker_statement = NULL;
	NSParameterAssert(sqlite3_prepare_v2(handle, 
										 "SELECT * FROM ticker WHERE symbol MATCH ? LIMIT 50",
										 -1, 
										 &search_ticker_statement, 
										 NULL) == SQLITE_OK);

	NSMutableSet *symbols = [NSMutableSet setWithCapacity:50];
	NSMutableArray *tickers = [NSMutableArray arrayWithCapacity:50];
	
	sqlite3_bind_text(search_ticker_statement, 1, [[NSString stringWithFormat:@"%@*", searchString] UTF8String], -1, SQLITE_TRANSIENT);
	while (sqlite3_step(search_ticker_statement) == SQLITE_ROW) {
		POTicker *ticker = [[[POTicker alloc] initWithRow:search_ticker_statement] autorelease];
		[tickers addObject:ticker];
		[symbols addObject:[ticker symbol]];
	}
	sqlite3_finalize(search_ticker_statement);
	
	if ([tickers count] < 50) {
		// Perform a looser search
		sqlite3_stmt *loose_search_ticker_statement = NULL;
		NSParameterAssert(sqlite3_prepare_v2(handle, 
											 "SELECT * FROM ticker WHERE ticker MATCH ? LIMIT 50", // "ticker" is a keyword to search all fields
											 -1, 
											 &loose_search_ticker_statement, 
											 NULL) == SQLITE_OK);
		
		sqlite3_bind_text(loose_search_ticker_statement, 1, [[NSString stringWithFormat:@"%@*", searchString] UTF8String], -1, SQLITE_TRANSIENT);
		while (sqlite3_step(loose_search_ticker_statement) == SQLITE_ROW) {
			POTicker *ticker = [[[POTicker alloc] initWithRow:loose_search_ticker_statement] autorelease];
			if (![symbols containsObject:[ticker symbol]]) {
				[tickers addObject:ticker];
			}
		}
		sqlite3_finalize(loose_search_ticker_statement);
	}
	
	[handleLock unlock];
	
	return tickers;
}

+ (NSArray *)remoteTickersContaining:(NSString *)searchString {
	if ([searchString length] == 0) return [NSArray array];
	
	@try {
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://autoc.finance.yahoo.com/autoc?query=%@&callback=YAHOO.Finance.SymbolSuggest.ssCallback", [searchString urlencode]]];
		NSURLResponse *response = nil;
		NSError *error = nil;
		NSData *responseData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:&response error:&error];
		
		/* TODO raise errors to the caller, have it passed back to list & let user submit it with auto-error-submit. */
		
		if (!responseData) {
			NSLog(@"Error retrieving quote suggestions. %@", error);
			return [NSArray array];
		}
		
		NSString *suggestions = [[[NSString alloc] initWithData:responseData 
													   encoding:NSUTF8StringEncoding] autorelease];
		NSString *wrapper = @"YAHOO.Finance.SymbolSuggest.ssCallback(";
		
		if ([suggestions length] < [wrapper length]) {
			NSLog(@"Too-short response in %@", suggestions);
			return [NSArray array];
		}
		if (![[suggestions substringWithRange:NSMakeRange(0, [wrapper length])] isEqualToString:wrapper]) {
			NSLog(@"Unexpected start in %@", suggestions);
			return [NSArray array];
		}
		if (![[suggestions substringFromIndex:[suggestions length] - 1] isEqualToString:@")"]) {
			NSLog(@"Unexpected finish in %@", suggestions);
			return [NSArray array];
		}
		
		suggestions = [suggestions substringWithRange:NSMakeRange([wrapper length], [suggestions length] - [wrapper length] - 1)];
		
		NSDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:[suggestions dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
		
		if (!parsedResponse) {
			NSLog(@"Error parsing JSON. %@", suggestions);
			return [NSArray array];
		}
				
		NSDictionary *resultSet = [parsedResponse objectForKey:@"ResultSet"];
		NSDictionary *result = [resultSet objectForKey:@"Result"];
		
		if (!result) {
			NSLog(@"No response in response: %@", parsedResponse);
			return [NSArray array];
		}
		
		NSMutableArray *tickers = [NSMutableArray arrayWithCapacity:[result count]];
		for (NSDictionary *d in result) {
			NSString *exchange = [d objectForKey:@"exchDisp"];
			if ([[d objectForKey:@"type"] isEqualToString:@"M"]) {
				exchange = @"MUTF";
			}
			
			POTicker *t = [[POTicker alloc] initWithSymbol:[d objectForKey:@"symbol"] 
													  name:[d objectForKey:@"name"] 
												  exchange:exchange];
			[tickers addObject:t];
			[t release];
		}
		
		return tickers;
	} @catch (NSException *e) {
		NSLog(@"Unhandled exception %@", e);
	}
	return [NSArray array];
}

+ (POTicker *)tickerWithSymbol:(NSString *)symb {
	[handleLock lock];
	[POTicker initHandle];
	
	POTicker *ticker = nil;
	
	sqlite3_stmt *ticker_statement = NULL;
	NSParameterAssert(sqlite3_prepare_v2(handle, 
										 "SELECT * FROM ticker WHERE symbol = ?",
										 -1, 
										 &ticker_statement, 
										 NULL) == SQLITE_OK);
	
	sqlite3_bind_text(ticker_statement, 1, [symb UTF8String], -1, SQLITE_TRANSIENT);
	if (sqlite3_step(ticker_statement) == SQLITE_ROW) {
		ticker = [[[POTicker alloc] initWithRow:ticker_statement] autorelease];
	}
	sqlite3_finalize(ticker_statement);
	
	[handleLock unlock];
	
	return ticker;
}

@end
