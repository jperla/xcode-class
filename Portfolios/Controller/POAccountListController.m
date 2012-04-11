//
//  POAccountListController.m
//  Portfolio
//
//  Created by Adam Ernst on 11/18/08.
//  Copyright cosmicsoft 2008. All rights reserved.
//

#import "POAccountListController.h"
#import "POSelectBrokerController.h"
#import "POAccounts.h"
#import "POAccount.h"
#import "POAutomaticAccount.h"
#import "POAccountCell.h"
#import "POTotalsView.h"
#import "POPositionListController.h"
#import "POSecurities.h"
#import "POChangeLabel.h"
#import "POSettingsPaneController.h"
#import "POSettings.h"
#import "POAccountNameEditController.h"
#import "POAppDelegate.h"

@interface POAccountListController (PrivateMethods)
- (void)computeChangeLabelWidth;
@end

@implementation POAccountListController

- (id)init {
	if (self = [super init]) {
		[[POAccounts sharedAccounts] addObserver:self forKeyPath:@"change" options:0 context:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(securitiesRefreshed:) name:POSecuritiesDidRefreshNotification object:nil];
		[[POSettings sharedSettings] addObserver:self forKeyPath:@"showsChangeAsPercent" options:0 context:nil];
		changeLabelWidth = POAccountCellDefaultChangeWidth;
	}
	return self;
}

- (void)loadView {
	[[self navigationItem] setTitle:NSLocalizedString(@"Portfolios", @"Title of Accounts pane")];
	[[self navigationItem] setLeftBarButtonItem:[self editButtonItem]];
	[[self navigationItem] setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAccount:)] autorelease]];
	
	[super loadView];
	
	CGRect bounds = [[self view] bounds];
	
	totalsView = [[POTotalsView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, 63)];
	[totalsView setAccounts];
	[totalsView setChangeLabelWidth:changeLabelWidth];
	[[self view] addSubview:totalsView];
	
	UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"account_list_background.png"]];
	[bg setFrame:CGRectMake(0, 63, [bg frame].size.width, [bg frame].size.height)];
	[[self view] addSubview:bg];
	[bg release];
	
	accountList = [[UITableView alloc] initWithFrame:CGRectMake(0, 63, bounds.size.width, bounds.size.height - 49 - 63)];
	[accountList setDelegate:self];
	[accountList setDataSource:self];
	[accountList setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
	[accountList setBackgroundColor:[UIColor clearColor]];
	[accountList setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	[accountList setAllowsSelectionDuringEditing:YES];
	[[self view] addSubview:accountList];
	
	POStatusToolbar *toolbar = [[[POStatusToolbar alloc] initWithFrame:CGRectMake(0, bounds.size.height - 49.0, bounds.size.width, 49.0)] autorelease];
	[toolbar setDelegate:self];
	[[self view] addSubview:toolbar];
}

- (void)releaseSubviews {
	[accountList release], accountList = nil;
	[totalsView release], totalsView = nil;
	[positionListController release], positionListController = nil;
}	

- (void)dealloc {
	[self releaseSubviews];
	[[POAccounts sharedAccounts] removeObserver:self forKeyPath:@"change"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[POSettings sharedSettings] removeObserver:self forKeyPath:@"showsChangeAsPercent"];
	[super dealloc];
}

- (void)setView:(UIView *)view {
	if (view == nil) {
		/* In case of memory warnings */
		[self releaseSubviews];
	}
	[super setView:view];
}

- (void)refresh:(id)sender {
	// Refresh accounts after the securities refresh:
	[(POAppDelegate *)[[UIApplication sharedApplication] delegate] schedulePendingAccountsRefresh];
	
	if (![[POSecurities sharedSecurities] refreshing]) 
		[[POSecurities sharedSecurities] startRefreshing];
}

- (void)settings:(id)sender {
	UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:[[[POSettingsPaneController alloc] init] autorelease]] autorelease];
	[[self navigationController] presentModalViewController:navController animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[accountList deselectRowAtIndexPath:[accountList indexPathForSelectedRow] animated:YES];
	[accountList reloadData];
	[self computeChangeLabelWidth];
}

- (void)viewDidAppear:(BOOL)animated {
	[accountList flashScrollIndicators];
	
	/* Prevent position list controller from hanging onto its account for too long. */
	[positionListController setAccount:nil];
}

- (void)showAddControllerAnimated:(BOOL)animated {
	[[self navigationController] presentModalViewController:[[[UINavigationController alloc] initWithRootViewController:[[[POSelectBrokerController alloc] init] autorelease]] autorelease] animated:animated];
}

- (NSInteger)changeLabelWidth {
	return changeLabelWidth;
}

- (void)setChangeLabelWidth:(NSInteger)width {
	changeLabelWidth = width;
	
	[totalsView setChangeLabelWidth:width];
	for (POAccountCell *cell in [accountList visibleCells]) {
		[cell setChangeLabelWidth:width];
	}
}

- (void)computeChangeLabelWidth {
	NSInteger width = POAccountCellDefaultChangeWidth;
	width = MAX(width, [POChangeLabel widthForChange:[[POAccounts sharedAccounts] change] withValue:[[POAccounts sharedAccounts] value]]);
	for (NSInteger i = 0; i < [[POAccounts sharedAccounts] countOfAccounts]; i++) {
		POAccount *acc = [[POAccounts sharedAccounts] objectInAccountsAtIndex:i];
		width = MAX(width, [POChangeLabel widthForChange:[acc change] withValue:[acc value]]);
	}
	if (width != changeLabelWidth) {
		[self setChangeLabelWidth:width];
	}
}

- (void)showAccount:(POAccount *)account animated:(BOOL)animated {
	if (!positionListController) {
		positionListController = [[POPositionListController alloc] init];
	}
	
	[positionListController setAccount:account];
	[[self navigationController] pushViewController:positionListController animated:animated];	
}

- (void)editAccount:(POAccount *)account {
	POAccountNameEditController *c = [[[POAccountNameEditController alloc] init] autorelease];
	[c showToEditAccountName:account];
	[[self navigationController] presentModalViewController:[[[UINavigationController alloc] initWithRootViewController:c] autorelease] animated:YES];
}

- (void)addAccount:(id)sender {
	[self showAddControllerAnimated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[accountList setEditing:editing animated:animated];
	[super setEditing:editing animated:animated];
}

- (void)setEditing:(BOOL)editing {
	[accountList setEditing:editing];
	[super setEditing:editing];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[POAccounts sharedAccounts] countOfAccounts];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"AccountCell";
    
	POAccount *acc = [[POAccounts sharedAccounts] objectInAccountsAtIndex:[indexPath row]];
	
    POAccountCell *cell = (POAccountCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[POAccountCell alloc] initWithReuseIdentifier:CellIdentifier] autorelease];
    }
	
	[cell setAccount:acc];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	[cell setChangeLabelWidth:changeLabelWidth];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 63.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	POAccount *acc = [[POAccounts sharedAccounts] objectInAccountsAtIndex:[indexPath row]];
	if ([self isEditing]) {
		[self editAccount:acc];
	} else {
		[self showAccount:acc animated:YES];
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[POAccounts sharedAccounts] removeObjectFromAccountsAtIndex:[indexPath row]];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		
		if ([[POAccounts sharedAccounts] countOfAccounts] == 0) {
			[self setEditing:NO animated:YES];
		} else {
			if ([indexPath row] == [[POAccounts sharedAccounts] countOfAccounts]) {
				[(POPaperCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[indexPath row] - 1 inSection:0]] setShowsShadow:YES];
			}
			if ([indexPath row] == 0) {
				[(POPaperCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] setShowsTopBorder:YES];
			}
		}
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	POAccount *fromAccount = [[[POAccounts sharedAccounts] objectInAccountsAtIndex:[fromIndexPath row]] retain];
	[[POAccounts sharedAccounts] removeObjectFromAccountsAtIndex:[fromIndexPath row]];
	[[POAccounts sharedAccounts] insertObject:fromAccount inAccountsAtIndex:[toIndexPath row]];
	[fromAccount release];
	
	[tableView updatePaperCellsAfterCellMovedFromIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	int row = [indexPath row];
	int numberOfRows = [tableView numberOfRowsInSection:[indexPath section]];
	
	[(POPaperCell *)cell setShowsShadow:(row == numberOfRows - 1)];
	[(POPaperCell *)cell setShowsTopBorder:(row == 0)];
}

#pragma mark Observing

- (void)securitiesRefreshed:(NSNotification *)notification {
	[self computeChangeLabelWidth];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == [POAccounts sharedAccounts] && [keyPath isEqualToString:@"change"]) {
	 	[self computeChangeLabelWidth];
	} else if (object == [POSettings sharedSettings] && [keyPath isEqualToString:@"showsChangeAsPercent"]) {
		[self computeChangeLabelWidth];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


@end

