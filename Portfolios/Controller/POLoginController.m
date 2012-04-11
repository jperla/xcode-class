//
//  POLoginController.m
//  Portfolio
//
//  Created by Adam Ernst on 11/20/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POLoginController.h"
#import "POBroker.h"
#import "POPromptEditCell.h"
#import "POLabelCell.h"
#import "POOverlay.h"
#import "OfxRequest.h"
#import "SgmlDocument.h"
#import "SgmlContentElement.h"
#import "SgmlAggregateElement.h"
#import "POSelectAccountsController.h"
#import "POAppDelegate.h"


@interface POLoginController(PrivateMethods)
- (void)login;
@end

@implementation POLoginController

- (id)initWithBroker:(POBroker *)aBroker {
	if (self = [super init]) {
		[[self navigationItem] setTitle:NSLocalizedString(@"Account", @"Title of account log in pane")];
		broker = [aBroker retain];
	}
	return self;
}

- (void)dealloc {
	[userCell release];
	[passwordCell release];
	[blankCell release];
	[loginInstructionsCell release];
	[securityCell release];
	[loginButton release];
	[loginOverlay release];
    [super dealloc];
}

- (void)loadView {
	[super loadView];
	
	[[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
	
	UITableView *tableView = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, 
																			[[self view] frame].size.width, 
																			[[self view] frame].size.height) 
														   style:UITableViewStylePlain] autorelease];
	[tableView setDelegate:self];
	[tableView setDataSource:self];
	[tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	[tableView setScrollEnabled:NO];
	[tableView setBackgroundColor:[UIColor clearColor]];
	[tableView setOpaque:NO];
	
	UIFont *promptFont = [UIFont boldSystemFontOfSize:14.0];
	UIFont *fieldFont = [UIFont systemFontOfSize:14.0];
	
	UIColor *promptTextColor = [UIColor colorWithRed:0.376 green:0.3607 blue:0.3333 alpha:1.0];
	UIColor *fieldTextColor = [UIColor colorWithRed:0.2549 green:0.2431 blue:0.2274 alpha:1.0];
	
	NSString *userPrompt = NSLocalizedString(@"User", @"Prompt in the login pane");
	NSString *passwordPrompt = NSLocalizedString(@"Password", @"Prompt in the login pane");
	CGFloat promptWidth = MAX([userPrompt sizeWithFont:promptFont].width, [passwordPrompt sizeWithFont:promptFont].width);
	
	NSString *placeholder = NSLocalizedString(@"Required", @"Prompt in login pane");
	
#define kUserPasswordLeftMargin 29.0
	userCell = [[POPromptEditCell alloc] initWithPrompt:userPrompt promptWidth:promptWidth placeholder:placeholder isSecure:NO leftMargin:kUserPasswordLeftMargin];
	[userCell setAutocorrects:NO];
	[userCell setReturnKeyType:UIReturnKeyGo];
	[userCell setTarget:self];
	[userCell setFieldAction:@selector(userGo:)];
	[userCell setPromptFont:promptFont];
	[userCell setFieldFont:fieldFont];
	[userCell setPromptTextColor:promptTextColor];
	[userCell setFieldTextColor:fieldTextColor];
	[userCell setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_cell_top.png"]] autorelease]];
	
	passwordCell = [[POPromptEditCell alloc] initWithPrompt:passwordPrompt promptWidth:promptWidth placeholder:placeholder isSecure:YES leftMargin:kUserPasswordLeftMargin];
	[passwordCell setReturnKeyType:UIReturnKeyGo];
	[passwordCell setTarget:self];
	[passwordCell setFieldAction:@selector(passwordGo:)];
	[passwordCell setPromptFont:promptFont];
	[passwordCell setFieldFont:fieldFont];
	[passwordCell setPromptTextColor:promptTextColor];
	[passwordCell setFieldTextColor:fieldTextColor];
	[passwordCell setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_cell_bottom.png"]] autorelease]];
	
	blankCell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:nil];
	[blankCell setSelectionStyle:UITableViewCellSelectionStyleNone];
	
	loginInstructionsCell = [[POLabelCell alloc] initWithText:NSLocalizedString(@"Enter your online login details:", @"") style:POLabelCellStyleCardTop];
	securityCell = [[POLabelCell alloc] initWithText:NSLocalizedString(@"Passwords are stored securely in the keychain.", @"Security notice for login pane.") style:POLabelCellStyleCardBottom];
	
	loginButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Log In", @"Button in login window") style:UIBarButtonItemStyleDone target:self action:@selector(login)];
	[[self navigationItem] setRightBarButtonItem:loginButton];
	
	loginOverlay = [[POOverlay alloc] initWithFrame:CGRectMake(60, 140, 200, 200)];
	
	UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	[indicator setFrame:CGRectMake(lroundf([loginOverlay frame].size.width / 2.0 - [indicator frame].size.width / 2.0),
								   lroundf([loginOverlay frame].size.height / 2.0 - [indicator frame].size.height / 2.0) - 16.0,
								   [indicator frame].size.width,
								   [indicator frame].size.height)];
	[loginOverlay addSubview:indicator];
	[indicator startAnimating];
	[indicator release];
	
	UILabel *loggingIn = [[UILabel alloc] initWithFrame:CGRectMake(10.0, [indicator frame].origin.y + [indicator frame].size.height + 10.0, 180.0, 32.0)];
	[loggingIn setBackgroundColor:[UIColor clearColor]];
	[loggingIn setFont:[UIFont boldSystemFontOfSize:19.0]];
	[loggingIn setTextColor:[UIColor whiteColor]];
	[loggingIn setShadowColor:[UIColor blackColor]];
	[loggingIn setTextAlignment:UITextAlignmentCenter];
	[loggingIn setText:NSLocalizedString(@"Logging In...", @"Text in login pane")];
	[loginOverlay addSubview:loggingIn];
	[loggingIn release];
	
	[[self view] addSubview:tableView];
}

- (void)viewWillAppear:(BOOL)animated {
	[userCell becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
	/* Do nothing--don't want to lose user/pass */
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ([indexPath row]) {
		case 0:
			return blankCell;
		case 1:
			return loginInstructionsCell;
		case 2:
			return userCell;
		case 3:
			return passwordCell;
		case 4:
			return securityCell;
	}
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ([indexPath row]) {
		case 0:
			return 20.0f;
		case 1:
			return [loginInstructionsCell height];
		case 4:
			return [securityCell height];
		default:
			return 45.0f;
	}
}

- (void)processGoWithOtherCell:(POPromptEditCell *)otherCell {
	if ([[otherCell fieldText] length]) {
		/* Give it some time to resign the responder */
		[self login];
	} else {
		[otherCell becomeFirstResponder];
	}
}

- (void)userGo:(id)sender {
	[self processGoWithOtherCell:passwordCell];
}

- (void)passwordGo:(id)sender {
	[self processGoWithOtherCell:userCell];
}

#pragma mark Authentication

- (void)login {
	if (loginAttempts == 2) {
		UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You've already entered two incorrect passwords. You may be locked out of your account if you enter another incorrect password.", @"Warning about incorrect password")
														   delegate:self
												  cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel logging in")
											 destructiveButtonTitle:NSLocalizedString(@"Log In Anyway", @"Log in despite warning about passwords")
												  otherButtonTitles:nil];
		[sheet showInView:[self view]];
		[sheet release];
		return;
	}
	
	[userCell setEnabled:NO];
	[passwordCell setEnabled:NO];
	[loginButton setEnabled:NO];
	
	[[[UIApplication sharedApplication] keyWindow] addSubview:loginOverlay];
	CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
	[fadeIn setFromValue:[NSNumber numberWithFloat:0.0]];
	[[loginOverlay layer] addAnimation:fadeIn forKey:nil];
	
	[(POAppDelegate *)[[UIApplication sharedApplication] delegate] beginNetworkActivity];
	
	isLoggingIn = YES;
	[self performSelectorInBackground:@selector(doLogin) withObject:nil];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == [actionSheet cancelButtonIndex]) return;
	
	loginAttempts = 3; /* No longer shows warning after that */
	[self login];
}

- (void)doLogin {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	OfxRequest *request = [OfxRequest requestForAccountsWithUrl:[broker url] userId:[userCell fieldText] password:[passwordCell fieldText]];
	NSError *error;
	SgmlDocument *doc = [request sendRequestReturningError:&error transcript:NULL];
	[(POAppDelegate *)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(endNetworkActivity) withObject:nil waitUntilDone:YES];
	
	if (!doc) {
		[self performSelectorOnMainThread:@selector(loginFailedWithError:) withObject:error waitUntilDone:NO];
	} else {
		if ([OfxRequest ofxSignOnSuccessful:doc error:&error]) {
			[self performSelectorOnMainThread:@selector(loginCompletedSuccessfully:) withObject:doc waitUntilDone:NO];
		} else {
			[self performSelectorOnMainThread:@selector(loginAuthenticationFailedWithError:) withObject:error waitUntilDone:NO];
		}
	}
	
	[pool release];
}

- (void)loginDoneAnimated:(BOOL)animated {
	[userCell setEnabled:YES];
	[passwordCell setEnabled:YES];
	[loginButton setEnabled:YES];
	
	if (animated) {
		CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
		[fadeOut setToValue:[NSNumber numberWithFloat:0.0]];
		[fadeOut setDelegate:self];
		[[loginOverlay layer] addAnimation:fadeOut forKey:nil];
	} else {
		[loginOverlay removeFromSuperview];
	}
	
	isLoggingIn = NO;
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
	/* Only the fade out sets this controller as delegate */
	[loginOverlay removeFromSuperview];
}

- (void)viewWillDisappear:(BOOL)animated {
	if (isLoggingIn) {
		isLoggingIn = NO;
		[loginOverlay removeFromSuperview];
	}
}

- (void)loginCompletedSuccessfully:(SgmlDocument *)document {
	/* Here we can go ahead and query the document for accounts, 
	   then pass those on to the next view controller */
	if (!isLoggingIn) return;
	
	NSError *error = nil;
	
	if (![OfxRequest ofxResponseSuccessful:document statusPath:@"/OFX/SIGNUPMSGSRSV1/ACCTINFOTRNRS/STATUS" error:&error]) {
		NSString *errorMessage = error ? [error localizedDescription] : NSLocalizedString(@"An unexpected error occurred while looking up your accounts.", @"");
		
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Account Status Error", @"Error if the account lookup fails for some reason") 
														 message:errorMessage 
														delegate:nil 
											   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"") 
											   otherButtonTitles:nil] autorelease];
		[alert show];
		
		[self loginDoneAnimated:NO];
		return;
	}
	
	NSArray *accounts = [document elementsForXPath:@"/OFX/SIGNUPMSGSRSV1/ACCTINFOTRNRS/ACCTINFORS/ACCTINFO" error:&error];
	NSMutableArray *potentialAccounts = [NSMutableArray arrayWithCapacity:4];
	
	if (accounts) {
		for (SgmlAggregateElement *e in accounts) {
			NSString *description = [[e firstSubElementWithName:@"DESC"] content];
			
			SgmlAggregateElement *invAcctInfo = (SgmlAggregateElement *)[e firstSubElementWithName:@"INVACCTINFO"];
			if (!invAcctInfo) continue;
			
			SgmlAggregateElement *invAcctFrom = (SgmlAggregateElement *)[invAcctInfo firstSubElementWithName:@"INVACCTFROM"];
			if (!invAcctFrom) continue;
			
			NSString *brokerId = [[invAcctFrom firstSubElementWithName:@"BROKERID"] content];
			NSString *acctId = [[invAcctFrom firstSubElementWithName:@"ACCTID"] content];
			NSString *type = [[invAcctInfo firstSubElementWithName:@"USPRODUCTTYPE"] content];
			
			NSMutableString *suggestedName = [NSMutableString stringWithCapacity:32];
			[suggestedName appendString:[broker name]];
			
			if (type && [type length] && ![type isEqualToString:@"OTHER"] && ![type isEqualToString:@"NORMAL"]) {
				[suggestedName appendString:@" "];
				[suggestedName appendString:type];
			}
			
			if ([accounts count] > 1) {
				if (description && [description length]) {
					[suggestedName appendString:@" "];
					[suggestedName appendString:description];
				}
				
				[suggestedName appendString:@" "];
				[suggestedName appendString:acctId];
			}
			
			[potentialAccounts addObject:[[[POPotentialAccount alloc] initWithBrokerId:brokerId acctId:acctId suggestedName:suggestedName] autorelease]];
		}
	}
	
	if ([potentialAccounts count] == 0) {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Account Status Error", @"Error if the account lookup fails for some reason") 
														 message:NSLocalizedString(@"There are no accounts available. Contact your broker to set up online access.", @"Message if there are no accounts found") 
														delegate:nil 
											   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"") 
											   otherButtonTitles:nil] autorelease];
		[alert show];
		
		[self loginDoneAnimated:NO];
		return;
	}
	
	[[self navigationController] pushViewController:[[[POSelectAccountsController alloc] initWithBroker:broker 
																								 userId:[userCell fieldText] 
																							   password:[passwordCell fieldText] 
																							   accounts:potentialAccounts] autorelease] animated:YES];
	
	[self loginDoneAnimated:YES];
}

- (void)loginAuthenticationFailedWithError:(NSError *)error {
	/* We received a response from the server, but it indicated that the username/password was incorrect. */
	if (!isLoggingIn) return;
	
	[passwordCell setFieldText:@""];
	loginAttempts++;
	
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Log In Error", @"Error if the username/password is incorrect") 
													 message:[error localizedDescription] 
													delegate:self 
										   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"") 
										   otherButtonTitles:nil] autorelease];
	[alert show];
	
	[self loginDoneAnimated:NO];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	[passwordCell becomeFirstResponder];
}

- (void)loginFailedWithError:(NSError *)error {
	/* We were unable to fetch anything from the server, or parsing OFX or SGML failed. */
	if (!isLoggingIn) return;
	
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Network Error", @"Error if the Internet isn't working") 
													 message:[NSString stringWithFormat:NSLocalizedString(@"A connection to the brokerage couldn't be established (%@)", @"Error if the connection fails"), [error localizedDescription]]
													delegate:nil 
										   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"") 
										   otherButtonTitles:nil] autorelease];
	[alert show];
	
	[self loginDoneAnimated:NO];
}

@end
