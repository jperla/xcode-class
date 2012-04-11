//
//  PONewsBrowserController.m
//  Portfolios
//
//  Created by Adam Ernst on 3/7/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "PONewsBrowserController.h"


@implementation PONewsBrowserController

- (void)showErrorPage:(NSString *)error inWebView:(UIWebView *)aWebview {
	[aWebview setHidden:YES];
	[activityIndicator stopAnimating];
	[errorLabel setText:[NSString stringWithFormat:NSLocalizedString(@"An error occurred.\n(%@)", @"News load error"), error]];
}

- (id)initWithRequest:(NSURLRequest *)aRequest
{
	if (self = [super init]) {
		request = [aRequest retain];
	}
	return self;
}

- (void)loadView {
	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[activityIndicator startAnimating];
	
	UIView *wrapper = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 26, 20)];
	[wrapper addSubview:activityIndicator];
	
	UIBarButtonItem *refreshingItem = [[[UIBarButtonItem alloc] initWithCustomView:wrapper] autorelease];
	[wrapper release];
	
	[self setView:[[[UIView alloc] initWithFrame:CGRectZero] autorelease]];
	[[self view] setBackgroundColor:[UIColor whiteColor]];
	
	[self setTitle:NSLocalizedString(@"News", "")];
	[[self navigationItem] setRightBarButtonItem:refreshingItem];
	
	errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 150, [[self view] frame].size.width, 60)];
	[errorLabel setFont:[UIFont boldSystemFontOfSize:17.0]];
	[errorLabel setNumberOfLines:0];
	[errorLabel setTextAlignment:UITextAlignmentCenter];
	[errorLabel setTextColor:[UIColor colorWithWhite:0.35 alpha:1.0]];
	[errorLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
	[[self view] addSubview:errorLabel];
	
	webview = [[UIWebView alloc] initWithFrame:CGRectZero];
	[webview setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[webview setScalesPageToFit:YES];
	[webview setDelegate:self];
	[[self view] addSubview:webview];
	[webview loadRequest:request];
}

- (void)dealloc {
	[request release];
	[activityIndicator release], activityIndicator = nil;
	[webview release], webview = nil;
	[super dealloc];
}

- (void)viewWillDisappear:(BOOL)animated {
	[webview stopLoading];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	if (!webview) return;
	if ([error code] != NSURLErrorCancelled) [self showErrorPage:[error localizedDescription] inWebView:webView];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[activityIndicator stopAnimating];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[activityIndicator startAnimating];
}

- (NSString *)url {
	return [[request URL] absoluteString];
}

@end
