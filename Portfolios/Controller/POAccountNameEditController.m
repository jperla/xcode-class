//
//  POAccountNameEditController.m
//  Portfolio
//
//  Created by Adam Ernst on 12/1/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POAccountNameEditController.h"
#import "POPromptEditCell.h"
#import "POAccount.h"
#import "POAccounts.h"
#import "POLabelCell.h"


@implementation POAccountNameEditController

- (void)dealloc {
	[nameCell release];
	[blankCell release];
	[topCell release];
	[bottomCell release];
	[account release];
    [super dealloc];
}

- (void)loadView {
	[super loadView];
	
	[[self navigationItem] setTitle:NSLocalizedString(@"Portfolio", @"Title of manual account name page")];
	[[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
	[[self navigationItem] setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)] autorelease]];
	
	UITableView *tableView = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, 
																			[[self view] frame].size.width, 
																			[[self view] frame].size.height) 
														   style:UITableViewStylePlain] autorelease];
	[tableView setDelegate:self];
	[tableView setDataSource:self];
	[tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	[tableView setScrollEnabled:NO];
	[tableView setBackgroundColor:[UIColor clearColor]];
	
	UIFont *promptFont = [UIFont boldSystemFontOfSize:14.0];
	UIFont *fieldFont = [UIFont systemFontOfSize:14.0];
	
	UIColor *promptTextColor = [UIColor colorWithRed:0.376 green:0.3607 blue:0.3333 alpha:1.0];
	UIColor *fieldTextColor = [UIColor colorWithRed:0.2549 green:0.2431 blue:0.2274 alpha:1.0];
	
	nameCell = [[POPromptEditCell alloc] initWithPrompt:@"" promptWidth:0.0f placeholder:NSLocalizedString(@"Portfolio", @"Default portfolio name") isSecure:NO leftMargin:29.0];
	[nameCell setAutocorrects:NO];
	[nameCell setReturnKeyType:UIReturnKeyGo];
	[nameCell setTarget:self];
	[nameCell setFieldAction:@selector(done:)];
	[nameCell setPromptFont:promptFont];
	[nameCell setFieldFont:fieldFont];
	[nameCell setPromptTextColor:promptTextColor];
	[nameCell setFieldTextColor:fieldTextColor];
	[nameCell setFieldAutocapitalizationType:UITextAutocapitalizationTypeWords];
	[nameCell setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_cell_one.png"]] autorelease]];
	
	blankCell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:nil];
	[blankCell setSelectionStyle:UITableViewCellSelectionStyleNone];
	
	topCell = [[POLabelCell alloc] initWithText:NSLocalizedString(@"Enter a portfolio name:", @"") style:POLabelCellStyleCardTop];
	bottomCell = [[POLabelCell alloc] initWithText:@"" style:POLabelCellStyleCardBottom];
		
	[[self view] addSubview:tableView];
}

- (void)showToEditAccountName:(POAccount *)acc {
	// If called, this controller is used to *edit* an account. Otherwise, it's used to create a new one. */
	account = [acc retain];
	
	[self view]; // Make sure view is loaded
	[nameCell setFieldText:[acc name]];
	
	[[self navigationItem] setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)] autorelease]];
}

- (void)viewWillAppear:(BOOL)animated {
	[nameCell becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
	/* Do nothing--don't want to lose name cell */
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ([indexPath row]) {
		case 0:
			return blankCell;
		case 1:
			return topCell;
		case 2:
			return nameCell;
		case 3:
			return bottomCell;
	}
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ([indexPath row]) {
		case 0:
			return 20.0f;
		case 1:
			return [topCell height];
		case 3:
			return [bottomCell height];
		default:
			return 45.0f;
	}
}

- (void)done:(id)sender {
	NSString *name = [nameCell fieldText];
	if (!name || ![name length]) name = NSLocalizedString(@"Portfolio", @"Default portfolio name");
	
	if (!account) {
		POAccount *newAccount = [[POAccount alloc] initWithName:name];
		[[POAccounts sharedAccounts] insertObject:newAccount inAccountsAtIndex:[[POAccounts sharedAccounts] countOfAccounts]];
		[newAccount release];
	} else {
		[account setName:name];
	}
	
	[[self navigationController] dismissModalViewControllerAnimated:YES];
}

- (void)cancel:(id)sender {
	// Only callable if editing an existing account
	[[self navigationController] dismissModalViewControllerAnimated:YES];
}

@end
