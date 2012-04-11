//
//  POSelectAccountsController.h
//  Portfolio
//
//  Created by Adam Ernst on 11/25/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class POBroker, POLabelCell;

@interface POSelectAccountsController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	POBroker *broker;
	NSString *userId;
	NSString *password;
	NSArray  *accounts;
	NSArray  *accountCells;
	UITableViewCell *blankCell;
	POLabelCell *topLabelCell;
	POLabelCell *bottomLabelCell;
}

- (id)initWithBroker:(POBroker *)newBroker userId:(NSString *)newUserId password:(NSString *)newPassword accounts:(NSArray *)newAccounts;

@end


@interface POPotentialAccount : NSObject {
	NSString *brokerId;
	NSString *acctId;
	NSString *suggestedName;
}

- (id)initWithBrokerId:(NSString *)newBrokerId acctId:(NSString *)newAcctId suggestedName:(NSString *)newSuggestedName;

@property (readonly, copy) NSString *brokerId;
@property (readonly, copy) NSString *acctId;
@property (readonly, copy) NSString *suggestedName;

@end
