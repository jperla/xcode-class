//
//  POCyclingButton.h
//  Portfolios
//
//  Created by Adam Ernst on 4/4/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@interface POCyclingButton : UIButton {
	NSArray *titles;
	NSInteger currentTitleIndex;
	NSTimer *titleCycleTimer;
}

@property (nonatomic, copy) NSArray *titles;
@property (nonatomic) NSTimeInterval titleCycleInterval;

@end
