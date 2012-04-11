//
//  POGraph.h
//  Portfolios
//
//  Created by Adam Ernst on 5/28/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface POGraph : UIView {
	NSArray *historicalPrices;
}

@property (nonatomic, retain) NSArray *historicalPrices;

@end
