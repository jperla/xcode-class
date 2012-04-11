//
//  POErrorReporterController.m
//  Portfolios
//
//  Created by Adam Ernst on 4/4/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POErrorReporterController.h"
#import "POAutomaticAccount.h"
#import "POOverlay.h"
#import "WimAdditions.h"
#import "POAppDelegate.h"


NSString *POErrorReporterControllerEmailAddressKey = @"POErrorReporterControllerEmailAddressKey";

@implementation POErrorReporterController

@synthesize emailField, reportView, reportingOverlay, reportingOverlayActivityIndicator, reportingOverlaySuccessImage, reportingOverlayLabel;

- (id)initWithError:(NSError *)anError {
	if (self = [super initWithNibName:@"POErrorReporter" bundle:[NSBundle mainBundle]]) {
		reportingError = [anError retain];
	}
	return self;
}

- (void)releaseSubviews {
	if (emailField) [[NSUserDefaults standardUserDefaults] setObject:[emailField text] forKey:POErrorReporterControllerEmailAddressKey];
	[emailField release], emailField = nil;
	[reportView release], reportView = nil;
	
	[reportingOverlay release], reportingOverlay = nil;
	[reportingOverlayActivityIndicator release], reportingOverlayActivityIndicator = nil;
	[reportingOverlaySuccessImage release], reportingOverlaySuccessImage = nil;
	[reportingOverlayLabel release], reportingOverlayLabel = nil;
}

- (void)dealloc {
	[self releaseSubviews];
	[reportingError release];
	[connection release], connection = nil;
    [super dealloc];
}

- (void)setView:(UIView *)view {
	if (view == nil) {
		/* In case of memory warnings */
		[self releaseSubviews];
	}
	[super setView:view];
}

- (NSString *)stringForReportingError {
	NSMutableString *string = [NSMutableString stringWithCapacity:1024];
	[string appendFormat:@"Portfolios Version %@ - %@ %@ (%@)", 
	 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
	 [[UIDevice currentDevice] systemName], 
	 [[UIDevice currentDevice] systemVersion], 
	 [[UIDevice currentDevice] model]];
	
	NSError *error = reportingError;
	while (error) {
		[string appendFormat:@"\n%@ (%d)\n%@\n",
		 [error domain], 
		 [error code], 
		 [error localizedDescription]]; 
		
		NSString *transcript = [[error userInfo] objectForKey:POAutomaticAccountRefreshErrorTranscriptKey];
		if (transcript) [string appendFormat:@"\nTranscript:\n%@\n", transcript];
		
		error = [[error userInfo] objectForKey:NSUnderlyingErrorKey];
	}
	
	return string;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[self navigationItem] setTitle:NSLocalizedString(@"Report Error", @"Title of report error pane")];
	[[self navigationItem] setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease]];
	[[self navigationItem] setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Report", @"Button for reporting error") style:UIBarButtonItemStyleDone target:self action:@selector(report)] autorelease]];
	
	[emailField setText:[[NSUserDefaults standardUserDefaults] stringForKey:POErrorReporterControllerEmailAddressKey]];
	[reportView setText:[self stringForReportingError]];
}

- (IBAction)report {
	[[NSUserDefaults standardUserDefaults] setObject:[emailField text] forKey:POErrorReporterControllerEmailAddressKey];
	
	/* Disable "Report" button */
	[[[self navigationItem] rightBarButtonItem] setEnabled:NO];
	
	[reportingOverlay setHidden:NO];
	CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
	[fadeIn setFromValue:[NSNumber numberWithFloat:0.0]];
	[[reportingOverlay layer] addAnimation:fadeIn forKey:nil];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://portfolios.fogbugz.com/scoutSubmit.asp"]] autorelease];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	
	NSMutableString *requestBody = [NSMutableString stringWithCapacity:1024];
	[requestBody appendFormat:@"Email=%@&Description=Portfolios+Error+Report&ScoutUserName=Adam+Ernst&ScoutProject=Inbox&ScoutArea=Not+Spam&FriendlyResponse=0&ForceNewBug=1&Extra=%@",
	 [([emailField text] ? [emailField text] : @"") urlencode],
	 [[self stringForReportingError] urlencode]];
	[request setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
	
	connection = [[NSURLConnection connectionWithRequest:request delegate:self] retain];
	[(POAppDelegate *)[[UIApplication sharedApplication] delegate] beginNetworkActivity];
}

- (IBAction)cancel {
	if (connection) {
		[connection cancel];
		[connection release], connection = nil;
	}
	
	[[self navigationController] dismissModalViewControllerAnimated:YES];
}

- (IBAction)editEmailDone {
	[emailField resignFirstResponder];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
	return NO; /* Don't allow editing */
}

#pragma mark NSURLRequest Delegate

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
	/* Disable cancel button */
	[[[self navigationItem] leftBarButtonItem] setEnabled:NO];
	
	/* Change to the success message */
	[reportingOverlayActivityIndicator setHidden:YES];
	[reportingOverlaySuccessImage setHidden:NO];
	[reportingOverlayLabel setText:NSLocalizedString(@"Reported Error", @"Message when an error report is successfully sent")];
	
	[(POAppDelegate *)[[UIApplication sharedApplication] delegate] endNetworkActivity];
	
	[self performSelector:@selector(hideDone) withObject:nil afterDelay:1.0];
	[connection release], connection = nil;
}

- (void)hideDone {
	[[self navigationController] dismissModalViewControllerAnimated:YES];
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	[connection release], connection = nil;
	
	/* Hide the progress overlay */
	[reportingOverlay setHidden:YES];
	
	/* Re-enable "Report" button */
	[[[self navigationItem] rightBarButtonItem] setEnabled:YES];
	
	[(POAppDelegate *)[[UIApplication sharedApplication] delegate] endNetworkActivity];
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unable to Submit Report", @"Error message if you can't report an error")
														message:NSLocalizedString(@"Make sure you are connected to the Internet", @"") 
													   delegate:nil 
											  cancelButtonTitle:NSLocalizedString(@"Dismiss", @"") 
											  otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

@end
