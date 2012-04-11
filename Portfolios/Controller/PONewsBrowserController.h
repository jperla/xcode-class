//
//  PONewsBrowserController.h
//  Portfolios
//
//  Created by Adam Ernst on 3/7/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PONewsBrowserController : UIViewController <UIWebViewDelegate> {
	UIActivityIndicatorView *activityIndicator;
	UIWebView *webview;
	UILabel *errorLabel;
	NSURLRequest *request;
}

- (id)initWithRequest:(NSURLRequest *)aRequest;
- (NSString *)url;

@end
