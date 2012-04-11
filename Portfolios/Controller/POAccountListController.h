//
//  POAccountListController.h
//  Portfolio
//
//  Created by Adam Ernst on 11/18/08.
//  Copyright cosmicsoft 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "POStatusToolbar.h"

@class POTotalsView, POPositionListController;

@interface POAccountListController : UIViewController <UITableViewDelegate, UITableViewDataSource, POStatusToolbarDelegate> {
	UITableView  *accountList;
	POTotalsView *totalsView;
	NSInteger changeLabelWidth;
	
	POPositionListController *positionListController;
}

- (void)showAddControllerAnimated:(BOOL)animated;
- (void)showAccount:(POAccount *)account animated:(BOOL)animated;

@end
