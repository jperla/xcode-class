//
//  POSettings.h
//  Portfolios
//
//  Created by Adam Ernst on 4/3/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
	POSettingsPositionListSortTotalValue,
	POSettingsPositionListSortDayChange,
	POSettingsPositionListSortTickerSymbol
} POSettingsPositionListSortOption;


@interface POSettings : NSObject {

}

+ (POSettings *)sharedSettings;

@property (nonatomic) BOOL showsChangeAsPercent;
@property (nonatomic) POSettingsPositionListSortOption positionListSortOption;

@end
