//
//  POGraphController.h
//  Portfolios
//
//  Created by Adam Ernst on 5/28/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class POPosition, POGraph;

typedef enum {
	POGraphWeek,
	POGraphMonth,
	POGraphThreeMonths,
	POGraphYear,
	POGraphTwoYears
} POGraphPeriod;

@interface POGraphController : UIViewController {
	IBOutlet POGraph *graph;
	
	IBOutlet UIButton *weekButton;
	IBOutlet UIButton *monthButton;
	IBOutlet UIButton *threeMonthButton;
	IBOutlet UIButton *yearButton;
	IBOutlet UIButton *twoYearButton;
	
	IBOutlet UILabel *activityLabel;
	IBOutlet UIActivityIndicatorView *activityIndicator;
	
	POPosition *position;
	
	POGraphPeriod graphPeriod;
}

@property (nonatomic, retain) POGraph *graph;

@property (nonatomic, retain) UIButton *weekButton;
@property (nonatomic, retain) UIButton *monthButton;
@property (nonatomic, retain) UIButton *threeMonthButton;
@property (nonatomic, retain) UIButton *yearButton;
@property (nonatomic, retain) UIButton *twoYearButton;

@property (nonatomic, retain) UILabel *activityLabel;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, retain) POPosition *position;

@property (nonatomic) POGraphPeriod graphPeriod;

- (IBAction)periodButtonPressed:(id)sender;

@end
