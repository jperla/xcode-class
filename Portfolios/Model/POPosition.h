//
//  POPosition.h
//  Portfolio
//
//  Created by Adam Ernst on 11/18/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class POSecurity;

@interface POPosition : NSObject <NSCoding> {
	POSecurity *security;
	NSDecimalNumber *units;
	NSDecimalNumber *reportedMarketValue;
	BOOL isLong;
}

@property (nonatomic, readonly, retain) POSecurity *security;
@property (nonatomic, retain) NSDecimalNumber *units;
@property (nonatomic, retain) NSDecimalNumber *reportedMarketValue;
@property (nonatomic) BOOL isLong;

- (id)initWithSecurity:(POSecurity *)newSecurity;

- (NSDecimalNumber *)value;
- (NSDecimalNumber *)change;
- (NSDecimalNumber *)percentChange;

- (void)synchronizeWithPosition:(POPosition *)templatePosition;

@end
