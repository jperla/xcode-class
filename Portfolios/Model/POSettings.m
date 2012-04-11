//
//  POSettings.m
//  Portfolios
//
//  Created by Adam Ernst on 4/3/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POSettings.h"

#define kShowsChangeAsPercentKey @"kShowsChangeAsPercentKey"
#define kPositionsListSortKey @"kPositionsListSortKey"

@implementation POSettings

static POSettings *sharedSettings = nil;

+ (POSettings *)sharedSettings {
	@synchronized(self) {
		if (sharedSettings == nil) {
			sharedSettings = [[POSettings alloc] init];
		}
	}
	return sharedSettings;
}

- (BOOL)showsChangeAsPercent {
	return [[NSUserDefaults standardUserDefaults] boolForKey:kShowsChangeAsPercentKey];
}

- (void)setShowsChangeAsPercent:(BOOL)newValue {
	[[NSUserDefaults standardUserDefaults] setBool:newValue forKey:kShowsChangeAsPercentKey];
}

- (POSettingsPositionListSortOption)positionListSortOption {
	return [[NSUserDefaults standardUserDefaults] integerForKey:kPositionsListSortKey];
}

- (void)setPositionListSortOption:(POSettingsPositionListSortOption)newValue {
	[[NSUserDefaults standardUserDefaults] setInteger:newValue forKey:kPositionsListSortKey];
}

@end
