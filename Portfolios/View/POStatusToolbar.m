//
//  POStatusToolbar.m
//  Portfolio
//
//  Created by Adam Ernst on 2/7/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POStatusToolbar.h"
#import "POAccount.h"
#import "POAutomaticAccount.h"
#import "POAccounts.h"
#import "POSecurities.h"


@interface POStatusToolbar(PrivateMethods)
- (void)observeAccounts;
- (void)unobserveAccounts;
- (void)observeAccount:(POAccount *)acc;
- (void)unobserveAccount:(POAccount *)acc;
- (void)update;
@end

#define kInfoSectionWidth 230.0f

@implementation POStatusToolbar

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin];
		/* Refresh button */
		UIBarButtonItem *refreshButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
																						target:self 
																						action:@selector(refresh:)] autorelease];
		
		/* Info section */
		UIView *infoSection = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, kInfoSectionWidth, 40)] autorelease];
		[infoSection setBackgroundColor:[UIColor clearColor]];
		
		statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 1, kInfoSectionWidth, 38)];
		[statusLabel setFont:[UIFont systemFontOfSize:13.0]];
		[statusLabel setNumberOfLines:2];
		[statusLabel setTextAlignment:UITextAlignmentCenter];
		[statusLabel setTextColor:[UIColor colorWithWhite:0.90 alpha:1.0]];
		[statusLabel setBackgroundColor:[UIColor clearColor]];
		[statusLabel setShadowColor:[UIColor colorWithWhite:0.15 alpha:1.0]];
		[statusLabel setShadowOffset:CGSizeMake(0, -1.0)];
		[infoSection addSubview:statusLabel];
		
		activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		[infoSection addSubview:activityIndicator];
		
		activityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 24)];
		[activityLabel setBackgroundColor:[UIColor clearColor]];
		[activityLabel setFont:[UIFont boldSystemFontOfSize:13.0]];
		[activityLabel setTextColor:[UIColor colorWithWhite:0.90 alpha:1.0]];
		[activityLabel setShadowColor:[UIColor colorWithWhite:0.15 alpha:1.0]];
		[activityLabel setShadowOffset:CGSizeMake(0, -1.0)];
		[infoSection addSubview:activityLabel];
		
		UIBarButtonItem *labelBarItem = [[[UIBarButtonItem alloc] initWithCustomView:infoSection] autorelease];
		
		UIBarButtonItem *spaceItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
		[spaceItem setWidth:32.0];
		
		[self setItems:[NSArray arrayWithObjects:
						refreshButton, 
						[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
						labelBarItem,
						[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
						[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear.png"] style:UIBarButtonItemStylePlain target:self action:@selector(settings:)] autorelease],
						nil]];
		
		[[POSecurities sharedSecurities] addObserver:self forKeyPath:@"refreshing" options:0 context:nil];
		[self observeAccounts];
		[self update];
		
		/* Timer to automatically update every minute. Needed otherwise "x minutes ago" gets out of date. */
		updateTimer = [[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(update) userInfo:nil repeats:YES] retain];
	}
	return self;
}

- (void)dealloc {
	[updateTimer invalidate];
	[updateTimer release];
	
	if (inSingleAccountMode) {
		[self unobserveAccount:account];
	} else {
		[self unobserveAccounts];
	}
	[[POSecurities sharedSecurities] removeObserver:self forKeyPath:@"refreshing"];
	
	[statusLabel release];
	[activityLabel release];
	[activityIndicator release];
	[account release];
	[super dealloc];
}

- (void)refresh:(id)sender {
	if (delegate) [delegate refresh:sender];
}

- (void)settings:(id)sender {
	if (delegate) [delegate settings:sender];
}

- (void)setAccount:(POAccount *)anAccount {
	if (anAccount == account) return;
	
	if (anAccount && !inSingleAccountMode) {
		[self unobserveAccounts];
		inSingleAccountMode = YES;
	}
	
	[self unobserveAccount:account];
	[account release];
	account = [anAccount retain];
	[self observeAccount:account];
	[self update];
}

- (POAccount *)account {
	return account;
}

- (void)observeAccounts {
	[[POAccounts sharedAccounts] addObserver:self forKeyPath:@"refreshing" options:0 context:nil];
}

- (void)unobserveAccounts {
	[[POAccounts sharedAccounts] removeObserver:self forKeyPath:@"refreshing"];
}

- (void)observeAccount:(POAccount *)acc {
	if (!acc) return;
	if (![[acc class] isSubclassOfClass:[POAutomaticAccount class]]) return;
	
	[acc addObserver:self forKeyPath:@"refreshing" options:0 context:nil];
}

- (void)unobserveAccount:(POAccount *)acc {
	if (!acc) return;
	if (![[acc class] isSubclassOfClass:[POAutomaticAccount class]]) return;
	
	[acc removeObserver:self forKeyPath:@"refreshing"];
}

- (void)update {
	BOOL showActivity = NO;
	NSDate *lastRefresh = nil;
	
	if (inSingleAccountMode) {
		if (account && [[account class] isSubclassOfClass:[POAutomaticAccount class]]) {
			if ([(POAutomaticAccount *)account refreshing]) {
				[activityLabel setText:NSLocalizedString(@"Downloading positions...", @"Status text while refreshing an account.")];
				showActivity = YES;
			}
			lastRefresh = [(POAutomaticAccount *)account lastRefresh];
		}
	} else {
		if ([[POAccounts sharedAccounts] refreshing]) {
			[activityLabel setText:NSLocalizedString(@"Downloading positions...", @"Status text while refreshing all accounts.")];
			showActivity = YES;
		}
		lastRefresh = [[POAccounts sharedAccounts] lastRefresh];
	}
	
	if (!showActivity && [[POSecurities sharedSecurities] refreshing]) {
		[activityLabel setText:NSLocalizedString(@"Downloading quotes...", @"Status text while downloading stock quotes.")];
		showActivity = YES;
	}
	lastRefresh = lastRefresh ? [lastRefresh laterDate:[[POSecurities sharedSecurities] lastRefresh]] : [[POSecurities sharedSecurities] lastRefresh];
	
	[activityLabel setHidden:!showActivity];
	if (showActivity && ![activityIndicator isAnimating]) [activityIndicator startAnimating];
	if (!showActivity && [activityIndicator isAnimating]) [activityIndicator stopAnimating];
	[statusLabel setHidden:showActivity];
	
	if (showActivity) {
		[activityLabel sizeToFit];
		
		CGRect indFrame = [activityIndicator frame];
		CGFloat activityWidth = [activityLabel frame].size.width + indFrame.size.width + 8;
		
		[activityIndicator setFrame:CGRectMake(lroundf(kInfoSectionWidth / 2.0 - activityWidth / 2.0), 10.0, 
											   indFrame.size.width, 
											   indFrame.size.height)];
		
		[activityLabel setFrame:CGRectMake([activityIndicator frame].origin.x + indFrame.size.width + 8, 10,
										   [activityLabel frame].size.width, [activityLabel frame].size.height)];
		
	} else {
		NSString *timeAgo = @"never";
		if (lastRefresh) {
			int amt;
			NSString *type;
			
			amt = MAX(lround([[NSDate date] timeIntervalSinceDate:lastRefresh] / 60.0), 1);
			if (amt < 60) {
				type = (amt == 1) ? NSLocalizedString(@"minute", @"") : NSLocalizedString(@"minutes", @"");
			} else {
				amt = MAX(lround(amt / 60.0), 1);
				if (amt < 24) {
					type = (amt == 1) ? NSLocalizedString(@"hour", @"") : NSLocalizedString(@"hours", @"");
				} else {
					amt = MAX(lround(amt / 24.0), 1);
					type = (amt == 1) ? NSLocalizedString(@"day", @"") : NSLocalizedString(@"days", @"");
				}
			}
			
			timeAgo = [NSString stringWithFormat:NSLocalizedString(@"%d %@ ago", @""), amt, type];
		}
		
		[statusLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Last refresh: %@\nQuotes are delayed", @"Status text"), timeAgo]];
	}
	
	[[statusLabel superview] setNeedsDisplay];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"refreshing"]) {
		[self performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


@end
