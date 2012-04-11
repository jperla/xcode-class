//
//  POAppDelegate.m
//  Portfolio
//
//  Created by Adam Ernst on 11/18/08.
//  Copyright cosmicsoft 2008. All rights reserved.
//

#import "POAppDelegate.h"
#import "POAccountListController.h"
#import "POAccounts.h"
#import "POSecurities.h"
#import "MethodSwizzle.h"
#import "POPositionListController.h"
#import "POAccount.h"
#import "POPositionDetailController.h"
#import "PONewsBrowserController.h"

#define kAccountsKey @"accounts"
#define kSecuritiesKey @"securities"
#define kLaunchedPreviouslyKey @"launchedPreviously"
#define kViewStateSavedKey @"viewStateSaved"
#define kViewAccountKey @"viewAccount"
#define kViewPositionKey @"viewPosition"
#define kViewNewsUrlKey @"viewNewsUrl"

@implementation POAppDelegate

- (void)initializeStyleSystem {
	MethodSwizzle([UINavigationBar class], @selector(didAddSubview:), @selector(didAddSubview_Stylize:));
	MethodSwizzle([UIToolbar class], @selector(drawRect:), @selector(drawRect_Stylize:));
	MethodSwizzle([UINavigationController class], @selector(initWithRootViewController:), @selector(initWithRootViewController_Stylize:));
	
	MethodSwizzle([UIBarButtonItem class], @selector(initWithImage:style:target:action:), @selector(initWithImage_Stylize:style:target:action:));
	MethodSwizzle([UIBarButtonItem class], @selector(initWithTitle:style:target:action:), @selector(initWithTitle_Stylize:style:target:action:));
	MethodSwizzle([UIBarButtonItem class], @selector(initWithBarButtonSystemItem:target:action:), @selector(initWithBarButtonSystemItem_Stylize:target:action:));
	MethodSwizzle([UIBarButtonItem class], @selector(setTarget:), @selector(setTarget_Stylize:));
	MethodSwizzle([UIBarButtonItem class], @selector(setAction:), @selector(setAction_Stylize:));
	MethodSwizzle([UIBarButtonItem class], @selector(setStyle:), @selector(setStyle_Stylize:));
	MethodSwizzle([UIBarButtonItem class], @selector(setTitle:), @selector(setTitle_Stylize:));
	MethodSwizzle([UIBarButtonItem class], @selector(setPossibleTitles:), @selector(setPossibleTitles_Stylize:));
	MethodSwizzle([UIBarButtonItem class], @selector(setWidth:), @selector(setWidth_Stylize:));
	MethodSwizzle([UIBarButtonItem class], @selector(setEnabled:), @selector(setEnabled_Stylize:));
}

- (void)installSchwabCertificate {
	// Install the Schwab intermediate certificate. Schwab's SSL gives a URL to fetch the intermediate cert from
	// and iPhone OS doesn't support intermediate-cert-fetching.
	
	NSData *           certData;
	SecCertificateRef  certificate;
	OSStatus           err;
	
	certData = [[[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"VeriSignOFXCA" ofType:@"cer"]] autorelease];
	if (certData == nil) return;
	
	certificate = SecCertificateCreateWithData(NULL, (CFDataRef)certData);
	if (certificate == NULL) return;
	
	err = SecItemAdd(
					 (CFDictionaryRef) [NSDictionary dictionaryWithObjectsAndKeys:
										(id) kSecClassCertificate,  kSecClass, 
										certificate,                kSecValueRef, 
										nil
										], 
					 NULL
					 );
    // Don't actually assert, just fail silently.
	//assert(err == noErr || err == errSecDuplicateItem);
    
    CFRelease(certificate);
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	@try {
		NSData *securitiesData = [[NSUserDefaults standardUserDefaults] objectForKey:kSecuritiesKey];
		if (securitiesData)
			[POSecurities setSharedSecurities:[NSKeyedUnarchiver unarchiveObjectWithData:securitiesData]];
		
		NSData *accountsData = [[NSUserDefaults standardUserDefaults] objectForKey:kAccountsKey];
		if (accountsData)
			[POAccounts setSharedAccounts:[NSKeyedUnarchiver unarchiveObjectWithData:accountsData]];
	} @catch (NSException *e) {}
	
	[self initializeStyleSystem];
	
	[self installSchwabCertificate];
	
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	POAccountListController *acctListController = [[[POAccountListController alloc] init] autorelease];
	navigationController = [[UINavigationController alloc] initWithRootViewController:acctListController];
	[window addSubview:[navigationController view]];
	[window makeKeyAndVisible];
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:kLaunchedPreviouslyKey] && [[POAccounts sharedAccounts] countOfAccounts] == 0) {
		[acctListController showAddControllerAnimated:NO];
	} else {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:kViewStateSavedKey]) {
			NSInteger accountIdx = [[NSUserDefaults standardUserDefaults] integerForKey:kViewAccountKey];
			if (accountIdx >= 0 && accountIdx < [[POAccounts sharedAccounts] countOfAccounts]) {
				POAccount *account = [[POAccounts sharedAccounts] objectInAccountsAtIndex:accountIdx];
				[acctListController showAccount:account animated:NO];
				
				POPositionListController *positionListController = (POPositionListController *)[navigationController topViewController];
				NSInteger positionIdx = [[NSUserDefaults standardUserDefaults] integerForKey:kViewPositionKey];
				if (positionIdx >= 0 && positionIdx < [account countOfPositions] && [[positionListController class] isSubclassOfClass:[POPositionListController class]]) {
					[positionListController showPosition:[account objectInPositionsAtIndex:positionIdx] animated:NO];
					
					NSString *newsUrl = [[NSUserDefaults standardUserDefaults] objectForKey:kViewNewsUrlKey];
					if (newsUrl && [newsUrl length]) {
						[navigationController pushViewController:[[[PONewsBrowserController alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:newsUrl]]] autorelease] animated:NO];
					}
				}
			}
		}
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(securitiesFailedRefresh:) name:POSecuritiesFailedToRefreshNotification object:nil];
	
	pendingAccountsRefresh = YES;
	[[POSecurities sharedSecurities] addObserver:self forKeyPath:@"refreshing" options:0 context:nil];
	[[POSecurities sharedSecurities] performSelector:@selector(startRefreshing) withObject:nil afterDelay:1.0];
	
	[NSTimer scheduledTimerWithTimeInterval:60.0*10.0 target:[POSecurities sharedSecurities] selector:@selector(startRefreshing) userInfo:nil repeats:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	NSData *accountsData = [NSKeyedArchiver archivedDataWithRootObject:[POAccounts sharedAccounts]];
	NSData *securitiesData = [NSKeyedArchiver archivedDataWithRootObject:[POSecurities sharedSecurities]];
	[[NSUserDefaults standardUserDefaults] setObject:accountsData forKey:kAccountsKey];
	[[NSUserDefaults standardUserDefaults] setObject:securitiesData forKey:kSecuritiesKey];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kLaunchedPreviouslyKey];
	
	POAccount *account = nil;
	POPosition *position = nil;
	NSString *newsUrl = nil;
	for (UIViewController *viewController in [navigationController viewControllers]) {
		if ([[viewController class] isSubclassOfClass:[POPositionListController class]])
			account = [(POPositionListController *)viewController account];
		else if ([[viewController class] isSubclassOfClass:[POPositionDetailController class]])
			position = [(POPositionDetailController *)viewController position];
		else if ([[viewController class] isSubclassOfClass:[PONewsBrowserController class]])
			newsUrl = [(PONewsBrowserController *)viewController url];
	}
	
	NSInteger accountIdx = -1, positionIdx = -1;
	if (account) {
		accountIdx = [[[POAccounts sharedAccounts] mutableArrayValueForKey:@"accounts"] indexOfObject:account];
		if (accountIdx == NSNotFound) accountIdx = -1;
		
		if (accountIdx >= 0 && position) {
			positionIdx = [[account mutableArrayValueForKey:@"positions"] indexOfObject:position];
			if (positionIdx == NSNotFound) positionIdx = -1;
		}
	}
	
	if (positionIdx == -1)
		newsUrl = nil;
	
	[[NSUserDefaults standardUserDefaults] setInteger:accountIdx forKey:kViewAccountKey];
	[[NSUserDefaults standardUserDefaults] setInteger:positionIdx forKey:kViewPositionKey];
	[[NSUserDefaults standardUserDefaults] setObject:newsUrl forKey:kViewNewsUrlKey];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kViewStateSavedKey];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
	[[POSecurities sharedSecurities] removeObserver:self forKeyPath:@"refreshing"];
	[onlyRefreshAccount release];
	[navigationController release];
	[window release];
	[super dealloc];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == [POSecurities sharedSecurities] && [keyPath isEqualToString:@"refreshing"]) {
		if (![[POSecurities sharedSecurities] refreshing] && pendingAccountsRefresh) {
			if (onlyRefreshAccount == nil) {
				if (!hasUpdatedAllAccounts) {
					hasUpdatedAllAccounts = YES;
				}
				[[POAccounts sharedAccounts] performSelectorOnMainThread:@selector(startRefreshing) withObject:nil waitUntilDone:NO];
			} else {
				[onlyRefreshAccount performSelectorOnMainThread:@selector(startRefreshing) withObject:nil waitUntilDone:NO];
				onlyRefreshAccount = nil, [onlyRefreshAccount release];
			}
			pendingAccountsRefresh = NO;
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)securitiesFailedRefresh:(NSNotification *)notification {
	if (!notifiedOfSecuritiesRefreshError) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Downloading Quotes", @"") 
															message:[NSString stringWithFormat:NSLocalizedString(@"Make sure you are connected to the Internet (%@)", @""), [(NSError *)[notification object] localizedDescription]]
														   delegate:nil 
												  cancelButtonTitle:NSLocalizedString(@"Dismiss", @"") 
												  otherButtonTitles:nil];
		[alertView show];
		[alertView release];
		notifiedOfSecuritiesRefreshError = YES;
	}
}

- (void)schedulePendingAccountsRefresh {
	pendingAccountsRefresh = YES;
}

- (void)schedulePendingRefreshForAccount:(POAccount *)account {
	pendingAccountsRefresh = YES;
	
	// If the first refresh of *all* accounts hasn't happened yet, don't do this;
	// let that go through first since inevitably then "account" will be refreshed.
	if (hasUpdatedAllAccounts) {
		onlyRefreshAccount = [account retain];
	}
}

// A way to balance the network activity indicator visibility
- (void)beginNetworkActivity {
	networkActivityCount++;
	if (networkActivityCount)
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)endNetworkActivity {
	networkActivityCount--;
	if (networkActivityCount == 0)
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
