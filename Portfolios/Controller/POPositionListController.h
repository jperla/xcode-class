//
//  POPositionListController.h
//  Portfolio
//
//  Created by Adam Ernst on 2/6/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "POStatusToolbar.h"

@class POTotalsView, POAccount, POPositionDetailController, POPosition, POCyclingButton;

@interface POPositionListController : UIViewController <UITableViewDelegate, UITableViewDataSource, POStatusToolbarDelegate, UIAlertViewDelegate, UITextFieldDelegate> {
	UITableView     *positionList;
	POTotalsView    *totalsView;
	POCyclingButton *errorBar;
	POStatusToolbar *toolbar;
	
	POAccount       *account;
	NSMutableArray  *positions; /* Shadow array for account array of positions */
	
	POPositionDetailController *detailController;
	
	NSInteger        changeLabelWidth;
	
	SEL errorBarSelector;
	NSString *newPassword;
}

@property (nonatomic, retain) POAccount *account;

- (void)showPosition:(POPosition *)position animated:(BOOL)animated;

@end
