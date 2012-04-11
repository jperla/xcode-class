//
//  POTotalsView.h
//  Portfolio
//
//  Created by Adam Ernst on 2/6/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class POChangeLabel, POAccount;

@interface POTotalsView : UIView {
	POChangeLabel *changeLabel;
	UILabel      *subLabel;
	UILabel      *titleLabel;
	
	BOOL          isShowingAllAccounts;
	POAccount    *account;
}

- (void)setAccounts;
- (void)setAccount:(POAccount *)acc;

@property (nonatomic) NSInteger changeLabelWidth;

@end
