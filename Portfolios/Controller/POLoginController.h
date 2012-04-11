//
//  POLoginController.h
//  Portfolio
//
//  Created by Adam Ernst on 11/20/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class POBroker, POPromptEditCell, POLabelCell, POOverlay;

@interface POLoginController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, UIAlertViewDelegate> {
	POBroker *broker;
	
	int               loginAttempts;
	
	POPromptEditCell *userCell;
	POPromptEditCell *passwordCell;
	UITableViewCell  *blankCell;
	POLabelCell      *loginInstructionsCell;
	POLabelCell      *securityCell;
	
	UIBarButtonItem  *loginButton;
	
	POOverlay        *loginOverlay;
	BOOL              isLoggingIn;
}

- (id)initWithBroker:(POBroker *)aBroker;

@end
