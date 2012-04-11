//
//  POGraphController.m
//  Portfolios
//
//  Created by Adam Ernst on 5/28/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POGraphController.h"
#import "POPosition.h"
#import "POGraph.h"
#import "POSecurity.h"

#define kPOGraphPeriodKey @"graphPeriod"

@implementation POGraphController

@synthesize graph, weekButton, monthButton, threeMonthButton, yearButton, twoYearButton;
@synthesize activityLabel, activityIndicator;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
	if (self = [super initWithNibName:nibName bundle:nibBundle]) {
		[self setGraphPeriod:(POGraphPeriod) [[NSUserDefaults standardUserDefaults] integerForKey:kPOGraphPeriodKey]];
	}
	return self;
}

- (void)updateSelectedButton {
	[weekButton setSelected:(graphPeriod == POGraphWeek)];
	[monthButton setSelected:(graphPeriod == POGraphMonth)];
	[threeMonthButton setSelected:(graphPeriod == POGraphThreeMonths)];
	[yearButton setSelected:(graphPeriod == POGraphYear)];
	[twoYearButton setSelected:(graphPeriod == POGraphTwoYears)];
}

- (void)viewDidLoad {
	[self updateSelectedButton];
}

- (void)updateGraph {
	if (!graph) return; // If called before nib loads
	
	[graph setHistoricalPrices:nil];
	[graph setHidden:YES];
	[activityIndicator startAnimating];
	[activityLabel setHidden:NO];
	
	SEL selector = @selector(backgroundFetchHistoricalPricesForPosition:inPeriod:);
	NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[[POGraphController class] instanceMethodSignatureForSelector:selector]];
	[inv setSelector:selector];
	[inv setArgument:&position atIndex:2];
	[inv setArgument:&graphPeriod atIndex:3];
	[inv performSelectorInBackground:@selector(invokeWithTarget:) withObject:self];
}

- (void)backgroundFetchHistoricalPricesForPosition:(POPosition *)pos inPeriod:(POGraphPeriod)period {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSInteger daysPast = 7;
	if (period == POGraphMonth) daysPast = 30;
	else if (period == POGraphThreeMonths) daysPast = 90;
	else if (period == POGraphYear) daysPast = 365;
	else if (period == POGraphTwoYears) daysPast = 730;
	
	NSLog(@"Fetching historical prices...");
	NSArray *prices = [[pos security] historicalPricesFromDate:[NSDate dateWithTimeIntervalSinceNow:-60*60*24*daysPast]];
	NSLog(@"Done fetching historical prices. %d of them.", [prices count]);
	
	SEL selector = @selector(historicalPricesAvailable:forPosition:inPeriod:);
	NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[[POGraphController class] instanceMethodSignatureForSelector:selector]];
	[inv setSelector:selector];
	[inv setArgument:&prices atIndex:2];
	[inv setArgument:&pos atIndex:3];
	[inv setArgument:&period atIndex:4];
	[inv performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:self waitUntilDone:YES];	
	
	[pool release];
}

- (void)historicalPricesAvailable:(NSArray *)historicalPrices forPosition:(POPosition *)pos inPeriod:(POGraphPeriod)period {
	// Ignore out-of-date responses
	if (pos != position) return;
	if (period != graphPeriod) return;
	
	[activityIndicator stopAnimating];
	[activityLabel setHidden:YES];
	
	NSLog(@"Setting historical prices...");
	[graph setHistoricalPrices:historicalPrices];
	NSLog(@"Finished setting historical prices.");
	[graph setHidden:NO];
}

- (void)setPosition:(POPosition *)aPosition {
	[position autorelease];
	position = [aPosition retain];
	[self updateGraph];
}

- (POPosition *)position {
	return position;
}

- (void)dealloc {
	[graph release];
	
	[weekButton release];
	[monthButton release];
	[threeMonthButton release];
	[yearButton release];
	[twoYearButton release];
	
	[activityLabel release];
	[activityIndicator release];
	
	[position release];
	
	[super dealloc];
}

- (POGraphPeriod)graphPeriod {
	return graphPeriod;
}

- (void)setGraphPeriod:(POGraphPeriod)aPeriod {
	if (graphPeriod == aPeriod) return;
	
	graphPeriod = aPeriod;
	[self updateSelectedButton];
	[self updateGraph];
	
	[[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)aPeriod forKey:kPOGraphPeriodKey];
}

- (IBAction)periodButtonPressed:(id)sender {
	POGraphPeriod newPeriod = POGraphWeek;
	if (sender == monthButton) newPeriod = POGraphMonth;
	else if (sender == threeMonthButton) newPeriod = POGraphThreeMonths;
	else if (sender == yearButton) newPeriod = POGraphYear;
	else if (sender == twoYearButton) newPeriod = POGraphTwoYears;
	
	[self setGraphPeriod:newPeriod];
}

@end
