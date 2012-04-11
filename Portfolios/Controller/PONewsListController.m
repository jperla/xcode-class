//
//  PONewsListController.m
//  Portfolios
//
//  Created by Adam Ernst on 3/15/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "PONewsListController.h"
#import "POPosition.h"
#import "POSecurity.h"
#import "PONewsItem.h"
#import "PONewsBrowserController.h"


@implementation PONewsListController

@synthesize newsActivityLabel, newsActivityIndicator, newsList, parentController;

- (void)releaseCurrentPosition {
	if (position) [[position security] removeObserver:self forKeyPath:@"news"];
	if (position) [[position security] removeObserver:self forKeyPath:@"isUpdatingNews"];
	[position release];
	
	[currentNews release], currentNews = nil;
}

- (void)viewDidLoad {
	[newsList setSeparatorColor:[UIColor colorWithWhite:0.75 alpha:1.0]];
	[super viewDidLoad];
}

- (void)dealloc {
	[self releaseCurrentPosition];
	[newsActivityIndicator release];
	[newsActivityLabel release];
	[newsList release];
	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
	[newsList deselectRowAtIndexPath:[newsList indexPathForSelectedRow] animated:YES];
}

- (void)updateNewsVisibility {
	BOOL u = [[position security] isUpdatingNews];
	[newsList setHidden:u];
	[newsActivityLabel setHidden:!u];
	if (u)
		[newsActivityIndicator startAnimating];
	else
		[newsActivityIndicator stopAnimating];
}

- (void)setPosition:(POPosition *)aPosition {
	[self view]; /* Ensure view is loaded */
	
	if (aPosition != position) {
		[self releaseCurrentPosition];
		
		position = [aPosition retain];
		
		if (position) {
			[[position security] addObserver:self forKeyPath:@"news" options:0 context:nil];
			[[position security] addObserver:self forKeyPath:@"isUpdatingNews" options:0 context:nil];
			
			currentNews = [[[position security] news] retain];
			
			/* Update news if it's > 1 hr old */
			if (![[position security] lastNewsUpdate] || [(NSDate *)[NSDate dateWithTimeIntervalSinceNow:-60.0*60.0] compare:[[position security] lastNewsUpdate]] == NSOrderedDescending) {
				[[position security] startUpdatingNews];
			}
		}
		
		[newsList reloadData];
		[self updateNewsVisibility];
	}
}

- (POPosition *)position {
	return position;
}

#define kNewsCellId @"newsCellId"
- (UITableViewCell *)newsListCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [newsList dequeueReusableCellWithIdentifier:kNewsCellId];
	if (!cell) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kNewsCellId] autorelease];
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
		[cell setFont:[UIFont boldSystemFontOfSize:15.0]];
		[cell setTextColor:[UIColor colorWithWhite:0.27 alpha:1.0]];
		[cell setSelectedTextColor:[cell textColor]];
		[cell setSelectedBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"news_row_selected.png"]] autorelease]];
	}
	[cell setText:[(PONewsItem *)[currentNews objectAtIndex:[indexPath row]] title]];
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [self newsListCellForRowAtIndexPath:indexPath];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (currentNews ? [currentNews count] : 0);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	PONewsItem *newsItem = [currentNews objectAtIndex:[indexPath row]];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[newsItem url]]];
	[[parentController navigationController] pushViewController:[[[PONewsBrowserController alloc] initWithRequest:request] autorelease] animated:YES];
}

#pragma mark Observing
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == [position security]) {
		if ([keyPath isEqualToString:@"news"]) {
			[currentNews release];
			currentNews = [[[position security] news] retain];
			[newsList reloadData];
		} else if ([keyPath isEqualToString:@"isUpdatingNews"]) {
			[self updateNewsVisibility];
		} else {
			NSLog(@"Unexpected keypath %@ in PONewsListController.observeValueForKeyPath", keyPath);
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


@end
