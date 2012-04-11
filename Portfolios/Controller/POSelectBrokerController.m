//
//  POSelectBrokerController.m
//  Portfolio
//
//  Created by Adam Ernst on 11/20/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POSelectBrokerController.h"
#import "POBroker.h"
#import "POLoginController.h"
#import "POAccountNameEditController.h"
#import "UIBarButtonItem+POStyle.h"


@implementation POSelectBrokerController

- (void)loadView {
	[super loadView];
	
	[[self navigationItem] setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)] autorelease]];
	[[self navigationItem] setTitle:NSLocalizedString(@"Add Portfolio...", @"Title of the add portfolio window")];
	
	[[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"broker_background.png"]]];
	
	UILabel *instructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [[self view] frame].size.width, 40)];
	[instructionLabel setText:NSLocalizedString(@"Choose your broker:", @"Prompt to select broker in add-account pane")];
	[instructionLabel setTextAlignment:UITextAlignmentCenter];
	[instructionLabel setBackgroundColor:[UIColor clearColor]];
	[instructionLabel setTextColor:[UIColor colorWithWhite:0.0 alpha:0.67]];
	[instructionLabel setFont:[UIFont boldSystemFontOfSize:12.0]];
	[instructionLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
	[[self view] addSubview:instructionLabel];
	[instructionLabel release];
	
	NSInteger y_offset = 40;
	for (int i = 0; i < [[POBroker allBrokers] count]; i++) {
		UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage *buttonImage = [UIImage imageNamed:[(POBroker *)[[POBroker allBrokers] objectAtIndex:i] resourceName]];
		[button setBackgroundImage:buttonImage forState:UIControlStateNormal];
		[button setFrame:CGRectMake(0, y_offset, [[self view] frame].size.width, [buttonImage size].height)];
		[button setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		[button setTag:i];
		[button addTarget:self action:@selector(brokerAction:) forControlEvents:UIControlEventTouchUpInside];
		[[self view] addSubview:button];
		y_offset += [buttonImage size].height;
	}
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	UIImage *blankImage = [UIImage imageNamed:@"broker_blank.png"];
	[button setBackgroundImage:blankImage forState:UIControlStateNormal];
	[button setFrame:CGRectMake(0, y_offset, [[self view] frame].size.width, [blankImage size].height)];
	[button setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
	[button setTitle:NSLocalizedString(@"Other (Manual Entry)", @"Create an account where stocks are manually entered") forState:UIControlStateNormal];
	[button setFont:[UIFont boldSystemFontOfSize:17.0]];
	[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[button addTarget:self action:@selector(manualEntryAction:) forControlEvents:UIControlEventTouchUpInside];
	[[self view] addSubview:button];
}

- (void)cancel:(id)sender {
	[[self navigationController] dismissModalViewControllerAnimated:YES];
}

- (void)brokerAction:(id)sender {
	[[self navigationController] pushViewController:[[[POLoginController alloc] initWithBroker:[[POBroker allBrokers] objectAtIndex:[(UIButton *)sender tag]]] autorelease] animated:YES];
}

- (void)manualEntryAction:(id)sender {
	[[self navigationController] pushViewController:[[[POAccountNameEditController alloc] init] autorelease] animated:YES];
}

@end

