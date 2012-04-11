//
//  POPositionDetailController.h
//  Portfolios
//
//  Created by Adam Ernst on 2/27/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef enum {
	POPositionDetailViewOptionStats,
	POPositionDetailViewOptionGraph,
	POPositionDetailViewOptionNews
} POPositionDetailViewOption;

@class POPosition, PONewsListController, POStockDetailController, POMutualDetailController, POOptionDetailController, POBondDetailController, POGraphController;

@interface POPositionDetailController : UIViewController {
	IBOutlet UIButton *calendar;
	IBOutlet UILabel *dayLabel;
	IBOutlet UILabel *mathLabel;
	
	IBOutlet UIImageView *holdingsBackground;
	IBOutlet UILabel *positionLabel;
	IBOutlet UILabel *valueLabel;
	
	IBOutlet UILabel *tickerLabel;
	IBOutlet UILabel *nameLabel;
	
	IBOutlet UIButton *statsButton;
	IBOutlet UIButton *graphButton;
	IBOutlet UIButton *newsButton;
	
	IBOutlet PONewsListController *newsListController;
	IBOutlet POStockDetailController *stockDetailController;
	IBOutlet POMutualDetailController *mutualDetailController;
	IBOutlet POOptionDetailController *optionDetailController;
	IBOutlet POBondDetailController *bondDetailController;
	IBOutlet POGraphController *graphController;
	
	POPosition *position;
	POPositionDetailViewOption viewOption;
}

@property (nonatomic, retain) UIButton *calendar;
@property (nonatomic, retain) UILabel *dayLabel;
@property (nonatomic, retain) UILabel *mathLabel;

@property (nonatomic, retain) UIImageView *holdingsBackground;
@property (nonatomic, retain) UILabel *positionLabel;
@property (nonatomic, retain) UILabel *valueLabel;

@property (nonatomic, retain) UILabel *tickerLabel;
@property (nonatomic, retain) UILabel *nameLabel;

@property (nonatomic, retain) UIButton *statsButton;
@property (nonatomic, retain) UIButton *graphButton;
@property (nonatomic, retain) UIButton *newsButton;

@property (nonatomic, retain) PONewsListController *newsListController;
@property (nonatomic, retain) POStockDetailController *stockDetailController;
@property (nonatomic, retain) POMutualDetailController *mutualDetailController;
@property (nonatomic, retain) POOptionDetailController *optionDetailController;
@property (nonatomic, retain) POBondDetailController *bondDetailController;
@property (nonatomic, retain) POGraphController *graphController;

@property (nonatomic, retain) POPosition *position;

- (IBAction)showStats;
- (IBAction)showGraph;
- (IBAction)showNews;

@end
