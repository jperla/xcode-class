//
//  POPositionEditController.h
//  Portfolios
//
//  Created by Adam Ernst on 5/8/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class POPosition;
@class POAccount;

extern NSString *POPositionEditPaneDidUpdatePositionNotification;

@interface POPositionEditController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate> {
	POPosition *position;
	POAccount *account;
	
	IBOutlet UITextField *tickerField;
	BOOL settingTickerToResult;
	IBOutlet UIActivityIndicatorView *indicatorView;
	
	IBOutlet UIImageView *quantityBackground;
	IBOutlet UILabel *quantityLabel;
	IBOutlet UITextField *quantityField;
	IBOutlet UIButton *longButton;
	IBOutlet UIButton *shortButton;
	
	IBOutlet UITableView *searchTable;
	NSArray *currentSearchResults;
	BOOL showingLocalResults;
	BOOL showingRemoteResults;
}

- (id)initWithPosition:(POPosition *)pos account:(POAccount *)account;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

- (IBAction)tickerFieldDone:(id)sender;
- (IBAction)tickerFieldDidChange:(id)sender;

- (IBAction)longButton:(id)sender;
- (IBAction)shortButton:(id)sender;

@end
