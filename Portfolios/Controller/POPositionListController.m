//
//  POPositionListController.m
//  Portfolio
//
//  Created by Adam Ernst on 2/6/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POPositionListController.h"
#import "POTotalsView.h"
#import "POAccount.h"
#import "POPositionCell.h"
#import "POAutomaticAccount.h"
#import "POSecurities.h"
#import "POChangeLabel.h"
#import "POPositionDetailController.h"
#import "POPosition.h"
#import "POSettings.h"
#import "POSettingsPaneController.h"
#import "POCyclingButton.h"
#import "OfxRequest.h"
#import "POErrorReporterController.h"
#import "POPositionEditController.h"
#import "POPositionEditController.h"
#import "POAppDelegate.h"

@interface POPositionListController (PrivateMethods)
- (void)updateErrorBar;
- (void)updateShadows;
@end

enum {
	POPositionListPasswordAlertTag,
	POPositionListPasswordFieldTag,
	POPositionListReportErrorAlertTag
};

@implementation POPositionListController

- (id)init {
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(securitiesRefreshed:) name:POSecuritiesDidRefreshNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(positionUpdated:) name:POPositionEditPaneDidUpdatePositionNotification object:nil];
		[[POSettings sharedSettings] addObserver:self forKeyPath:@"positionListSortOption" options:0 context:nil];
		[[POSettings sharedSettings] addObserver:self forKeyPath:@"showsChangeAsPercent" options:0 context:nil];
	}
	return self;
}

- (void)reloadFields {
	if (account) {
		[[self navigationItem] setTitle:[account name]];
		
		if ([[account class] isSubclassOfClass:[POAutomaticAccount class]]) {
			[[self navigationItem] setRightBarButtonItem:nil];
		} else {
			[[self navigationItem] setRightBarButtonItem:[self editButtonItem]];
		}
	}
	
	[toolbar setAccount:account];
	[totalsView setAccount:account];
	
	[self updateErrorBar];
}

- (NSInteger)changeLabelWidth {
	return changeLabelWidth;
}

- (void)setChangeLabelWidth:(NSInteger)width {
	changeLabelWidth = width;
	
	for (POPositionCell *cell in [positionList visibleCells]) {
		[cell setChangeLabelWidth:width];
	}
}

- (void)updateListReloadingData:(BOOL)reload {
	NSSortDescriptor *descriptor = nil;
	
	switch ([[POSettings sharedSettings] positionListSortOption]) {
		case POSettingsPositionListSortDayChange:
			if ([[POSettings sharedSettings] showsChangeAsPercent])
				descriptor = [[NSSortDescriptor alloc] initWithKey:@"percentChange" ascending:YES];
			else				
				descriptor = [[NSSortDescriptor alloc] initWithKey:@"change" ascending:NO];
			break;
		case POSettingsPositionListSortTickerSymbol:
			descriptor = [[NSSortDescriptor alloc] initWithKey:@"security.ticker" ascending:YES];
			break;
		default: /* Including POSettingsPositionListSortTotalValue */
			descriptor = [[NSSortDescriptor alloc] initWithKey:@"value" ascending:NO];
			break;
	}
	
	[positions sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
	[descriptor release];
		
	NSInteger width = POPositionCellDefaultChangeWidth;
	for (POPosition *pos in positions) {
		width = MAX(width, [POChangeLabel widthForChange:[pos change] withValue:[pos value]]);
	}
	if (width != changeLabelWidth) {
		[self setChangeLabelWidth:width];
	}
	
	if (reload) [positionList reloadData];
}

- (void)securitiesRefreshed:(NSNotification *)notification {
	[self updateListReloadingData:YES];
}

- (void)positionUpdated:(NSNotification *)notification {
	[self updateListReloadingData:YES];
}

- (void)loadView {
	[[self navigationItem] setTitle:NSLocalizedString(@"Portfolio", @"Title of Portfolios pane")];
	
	[super loadView];
	
	CGRect bounds = [[self view] frame];
	
	totalsView = [[POTotalsView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, 63)];
	[[self view] addSubview:totalsView];
	
	UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"account_list_background.png"]];
	[bg setFrame:CGRectMake(0, 63, [bg frame].size.width, [bg frame].size.height)];
	[bg setOpaque:YES];
	[[self view] addSubview:bg];
	[bg release];
	
	positionList = [[UITableView alloc] initWithFrame:CGRectMake(0, 63, bounds.size.width, bounds.size.height - 49 - 63)];
	[positionList setDelegate:self];
	[positionList setDataSource:self];
	[positionList setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
	[positionList setBackgroundColor:[UIColor clearColor]];
	[positionList setOpaque:NO];
	[positionList setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	// We want "Add position" and other rows to be selectable if in editing mode (for manual accounts)
	[positionList setAllowsSelectionDuringEditing:YES];
	[[self view] addSubview:positionList];
	
	errorBar = [[POCyclingButton buttonWithType:UIButtonTypeCustom] retain];
	[errorBar setBackgroundImage:[UIImage imageNamed:@"error_bar_background.png"] forState:UIControlStateNormal];
	[errorBar setImage:[UIImage imageNamed:@"warning.png"] forState:UIControlStateNormal];
	[errorBar setFont:[UIFont boldSystemFontOfSize:15.0]];
	[errorBar setTitleColor:[UIColor colorWithWhite:0.0 alpha:0.75] forState:UIControlStateNormal];
	[errorBar setTitleShadowColor:[UIColor colorWithWhite:1.0 alpha:0.80] forState:UIControlStateNormal];
	[errorBar setTitleShadowColor:[UIColor colorWithWhite:0.0 alpha:0.0] forState:UIControlStateHighlighted];
	[errorBar setTitleShadowOffset:CGSizeMake(0.0, 1.0)];
	[errorBar setTitleEdgeInsets:UIEdgeInsetsMake(1, 2, -1, -2)];
	[errorBar setImageEdgeInsets:UIEdgeInsetsMake(0, -2, 0, 2)];
	[errorBar setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
	[errorBar setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
	[errorBar setContentEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
	[errorBar setFrame:CGRectMake(0, bounds.size.height - 49.0 - 44.0, bounds.size.width, 44.0)];
	[errorBar addTarget:self action:@selector(errorBarTapped:) forControlEvents:UIControlEventTouchUpInside];
	
	toolbar = [[POStatusToolbar alloc] initWithFrame:CGRectMake(0, bounds.size.height - 49.0, bounds.size.width, 49.0)];
	[toolbar setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth];
	[toolbar setDelegate:self];
	[[self view] addSubview:toolbar];
	
	/* In case we're reloading the view, reload data */
	[self reloadFields];
}

- (void)releaseSubviews {
	[positionList release], positionList = nil;
	[toolbar release], toolbar = nil;
	[totalsView release], totalsView = nil;
	[errorBar release], errorBar = nil;
	
	[detailController release], detailController = nil;
}

- (void)dealloc {
	[self releaseSubviews];
	
	if (account) {
		[account removeObserver:self forKeyPath:@"positions"];
		if ([[account class] isSubclassOfClass:[POAutomaticAccount class]]) {
			[account removeObserver:self forKeyPath:@"lastError"];
			[account removeObserver:self forKeyPath:@"refreshing"];
		}
		[account release], account = nil;
	}
	[positions release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[POSettings sharedSettings] removeObserver:self forKeyPath:@"positionListSortOption"];
    [[POSettings sharedSettings] removeObserver:self forKeyPath:@"showsChangeAsPercent"];
	
	[newPassword release], newPassword = nil;
	
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
	if (account && [[account class] isSubclassOfClass:[POAutomaticAccount class]]) {
		// Refresh accounts after the securities refresh:
		[(POAppDelegate *)[[UIApplication sharedApplication] delegate] schedulePendingRefreshForAccount:account];
	}
	
	if (![[POSecurities sharedSecurities] refreshing])
		[[POSecurities sharedSecurities] startRefreshing];
}

- (void)settings:(id)sender {
	UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:[[[POSettingsPaneController alloc] init] autorelease]] autorelease];
	[[self navigationController] presentModalViewController:navController animated:YES];
}

- (void)setAccount:(POAccount *)anAccount {
	if (anAccount != account) {
		if (account) {
			[account removeObserver:self forKeyPath:@"positions"];
			if ([[account class] isSubclassOfClass:[POAutomaticAccount class]]) {
				[account removeObserver:self forKeyPath:@"lastError"];
				[account removeObserver:self forKeyPath:@"refreshing"];
			}
			[account release];
		}
		[positions release];
		
		account = [anAccount retain];
		if ([[account class] isSubclassOfClass:[POAutomaticAccount class]]) {
			[account addObserver:self forKeyPath:@"lastError" options:0 context:nil];
			[account addObserver:self forKeyPath:@"refreshing" options:0 context:nil];
		}
		[account addObserver:self forKeyPath:@"positions" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
		positions = [[NSMutableArray arrayWithArray:[account mutableArrayValueForKey:@"positions"]] retain];
		[self updateListReloadingData:YES];
	}
	
	[self setEditing:NO];
	[self reloadFields];
}

- (POAccount *)account {
	return account;
}

- (void)showPosition:(POPosition *)position animated:(BOOL)animated {
	if (!detailController) {
		detailController = [[POPositionDetailController alloc] initWithNibName:@"POPositionDetail" bundle:[NSBundle mainBundle]];
	}
	
	[detailController setPosition:position];
	[[self navigationController] pushViewController:detailController animated:animated];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[positionList deselectRowAtIndexPath:[positionList indexPathForSelectedRow] animated:YES];
	[positionList reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[positionList flashScrollIndicators];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	BOOL changed = (editing != [super isEditing]);
	
	[positionList setEditing:editing animated:animated];
	[super setEditing:editing animated:animated];
	
	if (changed) {
		if (editing) {
			[positionList insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[positions count] inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
		} else {
			[positionList deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[positions count] inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
		}
		[self updateShadows];
	}
}

- (void)setEditing:(BOOL)editing {
	[self setEditing:editing animated:NO];
}

- (void)addPositions:(NSArray *)new deletePositions:(NSArray *)old {
	[positionList beginUpdates];
	
	NSMutableArray *deletedRows = [NSMutableArray arrayWithCapacity:[old count]];
	for (id obj in old) {
		[deletedRows addObject:[NSIndexPath indexPathForRow:[positions indexOfObjectIdenticalTo:obj] inSection:0]];
	}
	for (id obj in old) {
		[positions removeObjectIdenticalTo:obj];
	}
	[positionList deleteRowsAtIndexPaths:deletedRows withRowAnimation:UITableViewRowAnimationRight];
	
	NSMutableArray *addedRows = [NSMutableArray arrayWithCapacity:[new count]];
	[positions addObjectsFromArray:new];
	[self updateListReloadingData:NO];
	for (id obj in new) {
		[addedRows addObject:[NSIndexPath indexPathForRow:[positions indexOfObjectIdenticalTo:obj] inSection:0]];
	}
	[positionList insertRowsAtIndexPaths:addedRows withRowAnimation:UITableViewRowAnimationLeft];
	
	[positionList endUpdates];
}

- (void)showEditPositionPane:(POPosition *)position {
	UIViewController *addRoot = [[[POPositionEditController alloc] initWithPosition:position account:account] autorelease];
	[[self navigationController] presentModalViewController:[[[UINavigationController alloc] initWithRootViewController:addRoot] autorelease] animated:YES];
}

- (void)showAddPositionPane {
	[self showEditPositionPane:nil];
}

#pragma mark Tableview management

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (positions ? [positions count] : 0) + ([super isEditing] ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"PositionCell";
    static NSString *InsertCellIdentifier = @"InsertPositionCell";
	
	POPositionCell *cell;
		
	if ([indexPath row] == [positions count]) {
		cell = (POPositionCell *)[tableView dequeueReusableCellWithIdentifier:InsertCellIdentifier];
		if (cell == nil) {
			cell = [[[POPositionCell alloc] initWithReuseIdentifier:InsertCellIdentifier] autorelease];
		}
		[cell setInsertMode];		
	} else {
		POPosition *pos = [positions objectAtIndex:[indexPath row]];
		
		cell = (POPositionCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[POPositionCell alloc] initWithReuseIdentifier:CellIdentifier] autorelease];
		}
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
		[cell setPosition:pos];
		[cell setChangeLabelWidth:changeLabelWidth];
	}
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 46.0;
}

- (void)updateShadows {
	NSUInteger lastRow = [positionList numberOfRowsInSection:0] - 1;
	
	for (NSIndexPath *index in [positionList indexPathsForVisibleRows]) {
		POPaperCell *cell = (POPaperCell *) [positionList cellForRowAtIndexPath:index];
		
		[cell setShowsTopBorder:[index row] == 0];
		[cell setShowsShadow:[index row] == lastRow];
	}
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	int row = [indexPath row];
	int lastRow = [tableView numberOfRowsInSection:[indexPath section]] - 1;
	
	[(POPaperCell *)cell setShowsShadow:row == lastRow];
	[(POPaperCell *)cell setShowsTopBorder:row == 0];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self isEditing]) {
		if ([indexPath row] == [positions count]) {
			[self showAddPositionPane];
		} else {
			[self showEditPositionPane:(POPosition * )[positions objectAtIndex:[indexPath row]]];
		}
	} else {
		[self showPosition:(POPosition * )[positions objectAtIndex:[indexPath row]] animated:YES];
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row] == [positions count]) {
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([self isEditing] && [indexPath row] == [positions count]) return YES;
	
	if ([[account class] isSubclassOfClass:[POAutomaticAccount class]]) return NO;
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleInsert) {
		NSAssert([indexPath row] == [positions count], @"Unexpected insertion index");
		[self showAddPositionPane];
	} else if (editingStyle == UITableViewCellEditingStyleDelete) {
		POPosition *pos = [positions objectAtIndex:[indexPath row]];
		[[[self account] mutableArrayValueForKey:@"positions"] removeObject:pos];
		[self updateShadows];
	}
}

- (void)updatePositionsForChange:(NSDictionary *)change {
	[self addPositions:[change objectForKey:NSKeyValueChangeNewKey] deletePositions:[change objectForKey:NSKeyValueChangeOldKey]];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == account && [keyPath isEqualToString:@"positions"]) {
		[self performSelectorOnMainThread:@selector(updatePositionsForChange:) withObject:change waitUntilDone:YES];
	} else if (object == [POSettings sharedSettings] && ([keyPath isEqualToString:@"positionListSortOption"] || [keyPath isEqualToString:@"showsChangeAsPercent"])) {
		[self updateListReloadingData:YES];
	} else if (object == account && ([keyPath isEqualToString:@"lastError"] || [keyPath isEqualToString:@"refreshing"])) {
		[self performSelectorOnMainThread:@selector(updateErrorBar) withObject:nil waitUntilDone:NO];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Error Bar

- (void)updateErrorBar {
	BOOL showBar = (account && [[account class] isSubclassOfClass:[POAutomaticAccount class]] 
					&& ![(POAutomaticAccount *)account refreshing] 
					&& ([(POAutomaticAccount *)account lastError] != nil || [(POAutomaticAccount *)account refreshDisabled]));
	
	if (showBar) {
		NSArray *messages = nil;
		SEL selector = @selector(askReportError);
		NSError *error = [(POAutomaticAccount *)account lastError];
		
		if ([(POAutomaticAccount *)account refreshDisabled] || ([[error domain] isEqualToString:POAutomaticAccountErrorDomain] && 
																([error code] == kPOAutomaticAccountMissingPasswordError 
																 || [error code] == kPOAutomaticAccountBadLogonError))) {
			messages = [NSArray arrayWithObjects:NSLocalizedString(@"Incorrect brokerage password", @"Error when updating brokerage positions"), 
						NSLocalizedString(@"Tap here to enter password…", @"Message allowing user to fix incorrect password error"), nil];
			selector = @selector(updatePassword);
		} else if (error) {
			NSError *underlyingError = [[error userInfo] objectForKey:NSUnderlyingErrorKey];
			switch ([error code]) {
				case kPOAutomaticAccountRequestFailedError:
					if (underlyingError && [[underlyingError domain] isEqualToString:NSURLErrorDomain]) {
						messages = [NSArray arrayWithObjects:NSLocalizedString(@"Unable to connect to brokerage", @""), nil];
						selector = @selector(unableToConnect);
					}
					/* else: OfxRequestErrorDomain, SgmlDocumentErrorDomain. Use default error. */
					break;
				case kPOAutomaticAccountBalancesParsingFailed:
				case kPOAutomaticAccountSecuritiesParsingFailed:
				case kPOAutomaticAccountPositionsParsingFailed:
					/* All the parsing errors are esssentially the same. */
					messages = [NSArray arrayWithObjects:NSLocalizedString(@"Unexpected error parsing positions", @"Error message if parsing fails"),
								NSLocalizedString(@"Tap here to report error…", @"Message allowing user to report an error"), nil];
					break;
				case kPOAutomaticAccountServerError:
					if (underlyingError && [[underlyingError domain] isEqualToString:OfxRequestErrorDomain] && [underlyingError code] == kOfxRequestServerError) {
						messages = [NSArray arrayWithObjects:NSLocalizedString(@"Brokerage server returned an error", @""),
									[underlyingError localizedDescription],
									NSLocalizedString(@"Tap here to report error…", @"Message allowing user to report an error"), nil];
					}
					/* else: Bad document error when parsing STATUS; or other garbled responses from server. Use default error. */
					break;
			}
		}
		
		if (!messages) {
			messages = [NSArray arrayWithObjects:NSLocalizedString(@"Unexpected error updating positions", @""),
						NSLocalizedString(@"Tap here to report error…", @"Message allowing user to report an error"), nil];
		}
		
		[errorBar setTitles:messages];
		errorBarSelector = selector;
	}
	
	if (showBar && ![errorBar superview]) {
		/* Show bar */
		[[self view] addSubview:errorBar];
		[errorBar setFrame:CGRectMake(0, [[self view] bounds].size.height - 49.0 - 44.0, [[self view] bounds].size.width, 44.0)];
		[positionList setFrame:CGRectMake(0, 63, [[self view] bounds].size.width, [[self view] bounds].size.height - 49 - 44 - 63)];
	} else if (!showBar && [errorBar superview]) {
		/* Hide bar */
		[errorBar removeFromSuperview];
		[positionList setFrame:CGRectMake(0, 63, [[self view] bounds].size.width, [[self view] bounds].size.height - 49 - 63)];
	}
}

- (void)errorBarTapped:(id)sender {
	if (errorBarSelector) {
		[self performSelector:errorBarSelector];
	}
}

- (void)updatePassword {
	UIAlertView *passwordAlert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ Password", @"Password prompt--e.g. 'Schwab 294950 Password'"), [account name]]
															message:@"\n\n\n"
														   delegate:self
												  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
												  otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
	passwordAlert.tag = POPositionListPasswordAlertTag;
	
	UILabel *passwordLabel = [[UILabel alloc] initWithFrame:CGRectMake(12,40,260,25)];
	passwordLabel.font = [UIFont systemFontOfSize:16];
	passwordLabel.textColor = [UIColor whiteColor];
	passwordLabel.backgroundColor = [UIColor clearColor];
	passwordLabel.shadowColor = [UIColor blackColor];
	passwordLabel.shadowOffset = CGSizeMake(0,-1);
	passwordLabel.textAlignment = UITextAlignmentCenter;
	passwordLabel.text = [(POAutomaticAccount *)account userId];
	[passwordAlert addSubview:passwordLabel];
	
	UIImageView *passwordImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"passwordfield.png"]];
	passwordImage.frame = CGRectMake(11,79,262,31);
	[passwordAlert addSubview:passwordImage];
	
	UITextField *passwordField = [[UITextField alloc] initWithFrame:CGRectMake(16,83,252,25)];
	passwordField.font = [UIFont systemFontOfSize:18];
	passwordField.backgroundColor = [UIColor whiteColor];
	passwordField.secureTextEntry = YES;
	passwordField.keyboardAppearance = UIKeyboardAppearanceAlert;
	passwordField.delegate = self;
	passwordField.tag = POPositionListPasswordFieldTag;
	[passwordField becomeFirstResponder];
	[passwordAlert addSubview:passwordField];
	
	[passwordAlert show];
	[passwordAlert release];
	[passwordField release];
	[passwordImage release];
	[passwordLabel release];	
}

- (void)passwordAlert:(UIAlertView *)alertView dismissedWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == [alertView cancelButtonIndex]) return;
	if (!account || ![[account class] isSubclassOfClass:[POAutomaticAccount class]]) return;
	
	[(POAutomaticAccount *)account setPassword:newPassword];
	[(POAutomaticAccount *)account setRefreshDisabled:NO];
	[(POAutomaticAccount *)account startRefreshing];
	
	[newPassword release], newPassword = nil;
}

- (void)passwordFieldDidEndEditing:(UITextField *)theField {
	newPassword = [[theField text] copy];
}

- (void)askReportError {
	UIAlertView *reportAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error updating positions", @"") 
															  message:NSLocalizedString(@"Try again later. If the error persists, report it so we can fix it.", @"")
															 delegate:self
													cancelButtonTitle:NSLocalizedString(@"Dismiss", @"") 
													otherButtonTitles:NSLocalizedString(@"Report…", @""), nil];
	[reportAlertView setTag:POPositionListReportErrorAlertTag];
	[reportAlertView show];
	[reportAlertView release];
}

- (void)reportError {
	NSError *error = [(POAutomaticAccount *)account lastError];
	if (!error) return;
	
	POErrorReporterController *errorReporter = [[POErrorReporterController alloc] initWithError:error];
	[[self navigationController] presentModalViewController:[[[UINavigationController alloc] initWithRootViewController:errorReporter] autorelease] animated:YES];
	[errorReporter release];
}

- (void)unableToConnect {
	NSError *error = [(POAutomaticAccount *)account lastError];
	NSError *underlyingError = [[error userInfo] objectForKey:NSUnderlyingErrorKey];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unable to connect to brokerage", @"") 
														message:[NSString stringWithFormat:NSLocalizedString(@"Make sure you are connected to the Internet (%@)", @""), [underlyingError localizedDescription]]
													   delegate:nil 
											  cancelButtonTitle:NSLocalizedString(@"Dismiss", @"") 
											  otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	switch ([alertView tag]) {
		case POPositionListPasswordAlertTag:
			[self passwordAlert:alertView dismissedWithButtonIndex:buttonIndex];
			break;
		case POPositionListReportErrorAlertTag:
			if (buttonIndex == [alertView firstOtherButtonIndex]) {
				[self reportError];
			}
			break;
	}
}

#pragma mark UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
	switch ([textField tag]) {
		case POPositionListPasswordFieldTag:
			[self passwordFieldDidEndEditing:textField];
			break;
	}
}

@end
