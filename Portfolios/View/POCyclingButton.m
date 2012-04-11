//
//  POCyclingButton.m
//  Portfolios
//
//  Created by Adam Ernst on 4/4/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POCyclingButton.h"

#define kDefaultTitleCycleInterval 4.0

@implementation POCyclingButton

- (void)removeTimer {
	if (titleCycleTimer) {
		[titleCycleTimer invalidate];
		[titleCycleTimer release], titleCycleTimer = nil;
	}
}

- (void)resetTitleCycleWithInterval:(NSTimeInterval)interval {
	[self removeTimer];
	titleCycleTimer = [[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(cycleTitle) userInfo:nil repeats:YES] retain];
}

- (void)dealloc {
	[self removeTimer];
	[titles release];
	[super dealloc];
}

- (NSArray *)titles {
	return titles;
}

- (void)setTitles:(NSArray *)newTitles {
	if (titles) {
		[titles release], titles = nil;
	}
	if (!newTitles) return;
	
	titles = [[NSArray alloc] initWithArray:newTitles copyItems:YES];
	currentTitleIndex = 0;
	
	if ([titles count]) {
		[self setTitle:[titles objectAtIndex:0] forState:UIControlStateNormal];
	} else {
		[self setTitle:@"" forState:UIControlStateNormal];
	}
	
	/* Start timer if it hasn't already; reset to beginning of cycle */
	[self resetTitleCycleWithInterval:[self titleCycleInterval]];
}

- (NSTimeInterval)titleCycleInterval {
	return (titleCycleTimer ? [titleCycleTimer timeInterval] : kDefaultTitleCycleInterval);
}

- (void)setTitleCycleInterval:(NSTimeInterval)newInterval {
	[self resetTitleCycleWithInterval:newInterval];
}

- (void)cycleTitle {
	if (!titles || ![titles count]) {
		return;
	}
	
	currentTitleIndex++;
	if (currentTitleIndex >= [titles count]) currentTitleIndex = 0;
	
	[self setTitle:[titles objectAtIndex:currentTitleIndex] forState:UIControlStateNormal];
	
	CATransition *transition = [CATransition animation];
	[transition setType:kCATransitionFade];
	[[self layer] addAnimation:transition forKey:nil];
}

@end
