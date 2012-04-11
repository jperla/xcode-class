//
//  POErrorReporterController.h
//  Portfolios
//
//  Created by Adam Ernst on 4/4/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class POOverlay;

@interface POErrorReporterController : UIViewController <UITextViewDelegate> {
	IBOutlet UITextField *emailField;
	IBOutlet UITextView *reportView;
	
	IBOutlet POOverlay *reportingOverlay;
	IBOutlet UIActivityIndicatorView *reportingOverlayActivityIndicator;
	IBOutlet UIImageView *reportingOverlaySuccessImage;
	IBOutlet UILabel *reportingOverlayLabel;
	
	NSError *reportingError;
	NSURLConnection *connection;
}

- (id)initWithError:(NSError *)anError;

@property (nonatomic, retain) UITextField *emailField;
@property (nonatomic, retain) UITextView *reportView;

@property (nonatomic, retain) POOverlay *reportingOverlay;
@property (nonatomic, retain) UIActivityIndicatorView *reportingOverlayActivityIndicator;
@property (nonatomic, retain) UIImageView *reportingOverlaySuccessImage;
@property (nonatomic, retain) UILabel *reportingOverlayLabel;

- (IBAction)report;
- (IBAction)cancel;
- (IBAction)editEmailDone;

@end
