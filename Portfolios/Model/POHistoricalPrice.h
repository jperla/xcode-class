//
//  POHistoricalPrice.h
//  Portfolios
//
//  Created by Adam Ernst on 5/28/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface POHistoricalPrice : NSObject {
	NSDate *date;
	NSDecimalNumber *adjustedClose;
}

@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly) NSDecimalNumber *adjustedClose;

- (id)initWithDate:(NSDate *)aDate adjustedClose:(NSDecimalNumber *)anAdjustedClose;

@end
