//
//  POSelectAccountsController.m
//  Portfolio
//
//  Created by Adam Ernst on 11/25/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POSelectAccountsController.h"
#import "POBroker.h"
#import "POSelectAccountCell.h"
#import "POLabelCell.h"
#import "POAccount.h"
#import "POAccounts.h"
#import "POAutomaticAccount.h"
#import "IVTextTableView.h"


@implementation POSelectAccountsController

- (id)initWithBroker:(POBroker *)newBroker userId:(NSString *)newUserId password:(NSString *)newPassword accounts:(NSArray *)newAccounts {
	if (self = [super init]) {
		broker = [newBroker retain];
		userId = [newUserId copy];
		password = [newPassword copy];
		accounts = [newAccounts retain];
		
		[[self navigationItem] setTitle:NSLocalizedString(@"Select Portfolios", @"Title of the view to select which portfolios to import")];
		[[self navigationItem] setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"") 
																					   style:UIBarButtonItemStyleDone 
																					  target:self 
																					  action:@selector(done:)] autorelease]];
		
		blankCell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:nil];
		[blankCell setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		topLabelCell = [[POLabelCell alloc] initWithText:NSLocalizedString(@"Select the portfolios to track:", @"") style:POLabelCellStyleCardTop];
		bottomLabelCell = [[POLabelCell alloc] initWithText:NSLocalizedString(@"Tap to edit a portfolio's name.", @"Instruction when adding portfolio") style:POLabelCellStyleCardBottom];
		
		NSMutableArray *newAccountCells = [NSMutableArray arrayWithCapacity:[accounts count]];
		for (POPotentialAccount *account in accounts) {
			POSelectAccountCell *newCell = [[[POSelectAccountCell alloc] initWithText:[account suggestedName]] autorelease];
			
			for (POAccount *a in [[POAccounts sharedAccounts] mutableArrayValueForKey:@"accounts"]) {
				if (![[a class] isSubclassOfClass:[POAutomaticAccount class]]) continue;
				
				POAutomaticAccount *s = (POAutomaticAccount *)a;
				if ([[s url] isEqualToString:[broker url]] && [[s userId] isEqualToString:userId] && [[s acctId] isEqualToString:[account acctId]]) {
					[newCell setEnabled:NO];
				}
			}
			
			[newAccountCells addObject:newCell];
		}
		accountCells = [newAccountCells retain];
	}
	return self;
}

- (void)dealloc {
	[blankCell release];
	[topLabelCell release];
	[bottomLabelCell release];
	
	[broker release];
	[userId release];
	[password release];
	[accounts release];
	[accountCells release];
	
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
	/* Do nothing--don't want to lose cells and tableview */
}

- (void)loadView {
	[super loadView];
	
	[[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
	
	IVTextTableView *tableView = [[IVTextTableView alloc] initWithFrame:CGRectMake(0, 0, [[self view] frame].size.width, [[self view] frame].size.height) style:UITableViewStylePlain];
	[tableView setDelegate:self];
	[tableView setDataSource:self];
	[tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	[tableView setBackgroundColor:[UIColor clearColor]];
	[tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
	
	[[self view] addSubview:tableView];
	[tableView release];
}

#pragma mark Done Button

- (void)done:(id)sender {
	for (int i = 0; i < [accountCells count]; i++) {
		POSelectAccountCell *cell = (POSelectAccountCell *)[accountCells objectAtIndex:i];
		if ([cell isEnabled] && [cell isChecked]) {
			POPotentialAccount *potential = [accounts objectAtIndex:i];
			
			POAutomaticAccount *account = [[POAutomaticAccount alloc] initWithUrl:[broker url] userId:userId brokerId:[potential brokerId] acctId:[potential acctId] name:[cell text]];
			[account setPassword:password];
			[[POAccounts sharedAccounts] insertObject:account inAccountsAtIndex:[[POAccounts sharedAccounts] countOfAccounts]];
			[account startRefreshing];
			[account release];
		}
	}
	
	[[self navigationController] dismissModalViewControllerAnimated:YES];
}

#pragma mark Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [accounts count] + 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath row] == 0) {
		return blankCell;
	} else if ([indexPath row] == 1) {
		return topLabelCell;
	} else if ([indexPath row] == [accounts count] + 2) {
		return bottomLabelCell;
	} else {
		return [accountCells objectAtIndex:[indexPath row] - 2];
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath row] == 0) {
		return 20.0;
	} else if ([indexPath row] == 1) {
		return [topLabelCell height];
	} else if ([indexPath row] == [accounts count] + 2) {
		return [bottomLabelCell height];
	} else {
		return 45.0;
	}
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	int row = [indexPath row];
	int numberOfRows = [tableView numberOfRowsInSection:[indexPath section]];
	
	if (row <= 1) return; /* Spacer & top label cell */
	if (row == numberOfRows - 1) return; /* Bottom label cell */
	
	/* Adjust so we only have the account cells */
	row -= 2;
	numberOfRows -= 3;
	
	POSelectAccountCellType type = POSelectAccountCellTypeMiddleCell;
	if (row == 0 && numberOfRows == 1) {
		type = POSelectAccountCellTypeSingleCell;
	} else if (row == 0) {
		type = POSelectAccountCellTypeTopCell;
	} else if (row == numberOfRows - 1) {
		type = POSelectAccountCellTypeBottomCell;
	}
	[(POSelectAccountCell *)cell setType:type];
}

@end


@implementation POPotentialAccount

@synthesize brokerId, acctId, suggestedName;

- (id)initWithBrokerId:(NSString *)newBrokerId acctId:(NSString *)newAcctId suggestedName:(NSString *)newSuggestedName {
	if (self = [super init]) {
		brokerId = [newBrokerId copy];
		acctId = [newAcctId copy];
		suggestedName = [newSuggestedName copy];
	}
	return self;
}

- (void)dealloc {
	[brokerId release];
	[acctId release];
	[suggestedName release];
	[super dealloc];
}

@end

