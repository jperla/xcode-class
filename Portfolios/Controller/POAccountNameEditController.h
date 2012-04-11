//
//  POAccountNameEditController.h
//  Portfolio
//
//  Created by Adam Ernst on 12/1/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class POPromptEditCell, POLabelCell, POAccount;

@interface POAccountNameEditController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	POPromptEditCell *nameCell;
	POLabelCell *topCell;
	POLabelCell *bottomCell;
	UITableViewCell *blankCell;
	
	POAccount *account; // non-nil if editing an existing account's name
}

- (void)showToEditAccountName:(POAccount *)acc;

@end

