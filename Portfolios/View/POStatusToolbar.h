//
//  POStatusToolbar.h
//  Portfolio
//
//  Created by Adam Ernst on 2/7/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "POStatusToolbar.h"

@protocol POStatusToolbarDelegate
- (void)refresh:(id)sender;
- (void)settings:(id)sender;
@end

@class POAccount;

@interface POStatusToolbar : UIToolbar {
	id<POStatusToolbarDelegate> delegate;
	
	UILabel *statusLabel;
	UILabel *activityLabel;
	UIActivityIndicatorView *activityIndicator;
	
	BOOL inSingleAccountMode; /* Default NO until setAccount: is called */
	POAccount *account;
	
	NSTimer *updateTimer;
}

@property (nonatomic, assign) id<POStatusToolbarDelegate> delegate;
@property (nonatomic, retain) POAccount *account;

@end
