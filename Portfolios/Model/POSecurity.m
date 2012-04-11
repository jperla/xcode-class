//
//  POSecurity.m
//  Portfolio
//
//  Created by Adam Ernst on 11/18/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POSecurity.h"
#import "PONewsItem.h"
#import "POAppDelegate.h"
#import "POHistoricalPrice.h"
#import "NSString+ParsingExtensions.h"

@interface POSecurity(PrivateMethods)
- (void)finishNewsUpdate;
@end

@implementation POSecurity

#define kUniqueIdKey @"uniqueId"
#define kUniqueIdTypeKey @"uniqueIdType"
#define kTickerKey @"ticker"
#define kNameKey @"name"
#define kTypeKey @"type"
#define kPriceKey @"price"
#define kChangeKey @"change"
#define kNewsKey @"news"
#define kLastNewsUpdateKey @"lastUpdateNews"

@synthesize uniqueId, uniqueIdType, ticker, name, type, price, change;
@synthesize volume, averageVolume, peRatio, dividend, yield, marketCap, earningsPerShare;
@synthesize high52Week, low52Week, highDay, lowDay;

- (id)init {
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	}
	return self;
}

- (id)initWithUniqueId:(NSString *)newId ofType:(NSString *)newIdType ticker:(NSString *)newTicker type:(POSecurityType)newType name:(NSString *)newName {
	if (self = [self init]) {
		uniqueId = [newId copy];
		uniqueIdType = [newIdType copy];
		ticker = [newTicker copy];
		type = newType;
		name = [newName copy];
		price = nil;
		change = nil;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [self init]) {
		uniqueId = [[decoder decodeObjectForKey:kUniqueIdKey] retain];
		uniqueIdType = [[decoder decodeObjectForKey:kUniqueIdTypeKey] retain];
		ticker = [[decoder decodeObjectForKey:kTickerKey] retain];
		type = [decoder decodeIntegerForKey:kTypeKey];
		name = [[decoder decodeObjectForKey:kNameKey] retain];
		price = [[decoder decodeObjectForKey:kPriceKey] retain];
		change = [[decoder decodeObjectForKey:kChangeKey] retain];
		news = [[decoder decodeObjectForKey:kNewsKey] retain];
		lastNewsUpdate = [[decoder decodeObjectForKey:kLastNewsUpdateKey] retain];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:uniqueId forKey:kUniqueIdKey];
	[encoder encodeObject:uniqueIdType forKey:kUniqueIdTypeKey];
	[encoder encodeObject:ticker forKey:kTickerKey];
	[encoder encodeInteger:type forKey:kTypeKey];
	[encoder encodeObject:name forKey:kNameKey];
	[encoder encodeObject:price forKey:kPriceKey];
	[encoder encodeObject:change forKey:kChangeKey];
	[encoder encodeObject:news forKey:kNewsKey];
	[encoder encodeObject:lastNewsUpdate forKey:kLastNewsUpdateKey];
}

- (void)memoryWarning:(NSNotification *)not {
	[historicalPricesCache release], historicalPricesCache = nil;
}

- (void)dealloc {
	/* Do this FIRST, before releasing news-- in case
	   change notifications are triggered and cause 
	   listening events to call news accessor */
	if (newsConnection) {
		[newsConnection cancel];
		[self finishNewsUpdate];
	}
	
	[uniqueId release];
	[uniqueIdType release];
	[ticker release];
	[name release];
	
	[price release];
	[change release];
	
	[lastNewsUpdate release];
	[news release];
	
	[volume release];
	[averageVolume release];
	[peRatio release];
	[dividend release];
	[yield release];
	[marketCap release];
	[earningsPerShare release];
	
	[high52Week release];
	[low52Week release];
	[highDay release];
	[lowDay release];
	
	[historicalPricesCache release], historicalPricesCache = nil;
	
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
	return [self retain];
}

- (NSString *)description {
	return name;
}

#pragma mark News

- (BOOL)isUpdatingNews {
	return (newsConnection != nil);
}

- (void)finishNewsUpdate {
	[self willChangeValueForKey:@"isUpdatingNews"];
	[newsConnection release], newsConnection = nil;
	[self didChangeValueForKey:@"isUpdatingNews"];
	
	[(POAppDelegate *)[[UIApplication sharedApplication] delegate] endNetworkActivity];
	
    [newsConnectionData release], newsConnectionData = nil;
	[newsConnectionResponse release], newsConnectionResponse = nil;	
}

- (void)startUpdatingNews {
	if (newsConnection) return; /* Already updating */
	if (!ticker || [ticker length] == 0) return;
	
	newsConnectionData = [[NSMutableData data] retain];
	newsConnectionResponse = nil;
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.google.com/finance?morenews=10&rating=1&q=%@&output=rss", ticker]]];
	[self willChangeValueForKey:@"isUpdatingNews"];
	newsConnection = [[NSURLConnection connectionWithRequest:request delegate:self] retain];
	[self didChangeValueForKey:@"isUpdatingNews"];
	
	if (!newsConnection) {
		[newsConnectionData release], newsConnectionData = nil;
	} else {
		[(POAppDelegate *)[[UIApplication sharedApplication] delegate] beginNetworkActivity];
	}
}

- (void)parseNewsData {
	NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:newsConnectionData] autorelease];
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	
	newNews = [[NSMutableArray arrayWithCapacity:16] retain];
	currentElement = [[NSMutableString alloc] init];
	currentTitle = [[NSMutableString alloc] init];
	currentLink = [[NSMutableString alloc] init];
	
	if ([parser parse]) {
		[self willChangeValueForKey:@"news"];
		if (news) [news release], news = nil;
		news = [newNews retain];
		[lastNewsUpdate release], lastNewsUpdate = [[NSDate date] retain];
		[self didChangeValueForKey:@"news"];
	}
	
	[newNews release];
	[currentElement release];
	[currentTitle release];
	[currentLink release];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
	[currentElement setString:elementName];
	
	if ([elementName isEqualToString:@"item"]) {
		[currentTitle setString:@""];
		[currentLink setString:@""];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
	if ([elementName isEqualToString:@"item"]) {
		[newNews addObject:[PONewsItem newsItemWithTitle:[[currentTitle copy] autorelease] url:[[currentLink copy] autorelease]]];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
	if ([currentElement isEqualToString:@"title"]) {
		[currentTitle appendString:string];
	} else if ([currentElement isEqualToString:@"link"]) {
		[currentLink appendString:string];
	}
}

- (NSArray *)news {
	return news;
}

- (NSDate *)lastNewsUpdate{
	return lastNewsUpdate;
}

#pragma mark Price History

- (NSArray *)historicalPricesFromDate:(NSDate *)fromDate {
	if (![self ticker] || [[self ticker] length] == 0) {
		return nil;
	}
	
	if (!historicalPricesCache || [historicalPricesCache count] == 0 || [[[historicalPricesCache objectAtIndex:0] date] compare:fromDate] == NSOrderedDescending) {
		NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:fromDate];
		
		NSInteger year = [components year];
		NSInteger month = [components month];
		NSInteger day = [components day];
		
		[(POAppDelegate *)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(beginNetworkActivity) withObject:nil waitUntilDone:YES];
		
		NSURLResponse *response = nil;
		NSError *error = nil;
		NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://ichart.finance.yahoo.com/table.csv?s=%@&a=%d&b=%d&c=%d", [self ticker], month - 1, day, year]]] returningResponse:&response error:&error];
		
		[(POAppDelegate *)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(endNetworkActivity) withObject:nil waitUntilDone:YES];
		
		if (!data) return nil;
		
		NSMutableString *responseString = [[[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		[responseString replaceOccurrencesOfString:@"\r" withString:@"" options:0 range:NSMakeRange(0, [responseString length])];
		
		NSArray *rows = [responseString csvRows];
		NSArray *headerRow = [rows objectAtIndex:0];
		NSUInteger dateIdx = [headerRow indexOfObject:@"Date"];
		NSUInteger adjCloseIdx = [headerRow indexOfObject:@"Adj Close"];
		if (dateIdx == NSNotFound || adjCloseIdx == NSNotFound) return nil;
		
		NSMutableArray *newHistoricalPrices = [NSMutableArray arrayWithCapacity:[rows count]];
		
		NSDateFormatter *dtFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dtFormatter setDateFormat:@"yyyy-MM-dd"];
		
		NSLocale *usLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
		
		int j;
		for (j = 1; j < [rows count]; j++) {
			NSArray *row = [rows objectAtIndex:j];
			if (dateIdx >= [row count] || adjCloseIdx >= [row count]) continue;
			
			NSDate *dt = [dtFormatter dateFromString:[row objectAtIndex:dateIdx]];
			NSDecimalNumber *close = [[row objectAtIndex:adjCloseIdx] decimalNumberByParsingWithLocale:usLocale];
			if (!dt || !close) continue;
			
			[newHistoricalPrices insertObject:[[[POHistoricalPrice alloc] initWithDate:dt adjustedClose:close] autorelease] atIndex:0];
		}
		
		[historicalPricesCache release];
		historicalPricesCache = [newHistoricalPrices retain];
	}
	
	int i;
	for (i = 0; i < [historicalPricesCache count]; i++) {
		if ([[[historicalPricesCache objectAtIndex:i] date] compare:fromDate] == NSOrderedDescending) {
			return [historicalPricesCache subarrayWithRange:NSMakeRange(i, [historicalPricesCache count] - i)];
		}
	}
	return [NSArray array];
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if (connection == newsConnection) {
		[self finishNewsUpdate];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	if (connection == newsConnection) {
		newsConnectionResponse = [response retain];
		[newsConnectionData setLength:0];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if (connection == newsConnection) {
		[newsConnectionData appendData:data];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)urlConnection {
	if (urlConnection == newsConnection) {
		[self parseNewsData];
		[self finishNewsUpdate];
	}
}

@end
