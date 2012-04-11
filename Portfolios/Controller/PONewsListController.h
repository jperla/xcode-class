//
//  PONewsListController.h
//  Portfolios
//
//  Created by Adam Ernst on 3/15/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@class POPosition;

@interface PONewsListController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	IBOutlet UILabel *newsActivityLabel;
	IBOutlet UIActivityIndicatorView *newsActivityIndicator;
	IBOutlet UITableView *newsList;
	
	NSArray *currentNews; /* Of PONewsItem */
	POPosition *position;
	UIViewController *parentController;
}

@property (nonatomic, retain) UILabel *newsActivityLabel;
@property (nonatomic, retain) UIActivityIndicatorView *newsActivityIndicator;
@property (nonatomic, retain) UITableView *newsList;

@property (nonatomic, retain) POPosition *position;
@property (nonatomic, assign) UIViewController *parentController;

@end
