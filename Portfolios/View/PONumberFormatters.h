//
//  PONumberFormatters.h
//  Portfolio
//
//  Created by Adam Ernst on 2/6/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PONumberFormatters : NSObject {

}

+ (NSString *)stringForChange:(NSDecimalNumber *)aChange withValue:(NSDecimalNumber *)aValue inPercent:(BOOL)percent;

+ (NSNumberFormatter *)percentChangeFormatter;
+ (NSNumberFormatter *)changeFormatter;
+ (NSNumberFormatter *)detailChangeFormatter;

+ (NSNumberFormatter *)valueFormatter;
+ (NSNumberFormatter *)detailValueFormatter;

+ (NSNumberFormatter *)priceFormatter;
+ (NSNumberFormatter *)priceChangeFormatter;

+ (NSNumberFormatter *)sharesFormatter;

+ (NSNumberFormatter *)generalStatisticsFormatter;
+ (NSNumberFormatter *)yieldFormatter;

@end
