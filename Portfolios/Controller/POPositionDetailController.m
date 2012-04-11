//
//  POPositionDetailController.m
//  Portfolios
//
//  Created by Adam Ernst on 2/27/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POPositionDetailController.h"
#import "POPosition.h"
#import "POSecurity.h"
#import "PONewsItem.h"
#import "PONewsBrowserController.h"
#import "PONumberFormatters.h"
#import "POLabelValueCell.h"
#import "PONewsListController.h"
#import "POStockDetailController.h"
#import "POMutualDetailController.h"
#import "POOptionDetailController.h"
#import "POBondDetailController.h"
#import "POGraphController.h"
#import "POSecurities.h"

#define kViewOptionKey @"POPositionDetailViewOption"

@interface POPositionDetailController (PrivateMethods)
- (void)setViewOption:(POPositionDetailViewOption)opt animated:(BOOL)animated;
- (void)updateFields;
@end


@implementation POPositionDetailController

@synthesize calendar, dayLabel, mathLabel, holdingsBackground, positionLabel, valueLabel, tickerLabel, nameLabel;
@synthesize statsButton, graphButton, newsButton;
@synthesize newsListController, stockDetailController, mutualDetailController, optionDetailController, bondDetailController, graphController;

- (id)initWithNibName:(NSString *)aNibName bundle:(NSBundle *)nibBundle {
	if (self = [super initWithNibName:aNibName bundle:nibBundle]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(securitiesRefreshed:) name:POSecuritiesDidRefreshNotification object:nil];
	}
	return self;
}

/* Useful little utility function. */
- (void)attachSubviewController:(UIViewController *)aViewController {
	if ([[aViewController view] superview]) {
		NSLog(@"ERROR: attempted to attach subview controller %@ when it's already attached to a view. leaving it unattached to new view.", aViewController);
		return;
	}
	
	[[aViewController view] setFrame:CGRectOffset([[aViewController view] frame], 0, [[self view] frame].size.height - [[aViewController view] frame].size.height)];
	[[aViewController view] setHidden:YES];
	[[self view] addSubview:[aViewController view]];
	[aViewController viewWillAppear:YES];
}

- (void)viewDidLoad {
	[[self navigationItem] setTitle:NSLocalizedString(@"Info", @"Title of the Position Detail view")];
	
	[holdingsBackground setImage:[[UIImage imageNamed:@"holdings.png"] stretchableImageWithLeftCapWidth:71 topCapHeight:0]];
	
	[calendar setTitleEdgeInsets:UIEdgeInsetsMake(1, 5, -1, -5)];
	[calendar setImageEdgeInsets:UIEdgeInsetsMake(1, 3, -1, -3)];
	
	UIEdgeInsets imInsets = UIEdgeInsetsMake(1, -3, -1, 3);
	UIEdgeInsets titleInsets = UIEdgeInsetsMake(0, 3, 0, -3);
	[statsButton setImageEdgeInsets:imInsets];
	[statsButton setTitleEdgeInsets:titleInsets];
	[graphButton setImageEdgeInsets:imInsets];
	[graphButton setTitleEdgeInsets:titleInsets];
	[newsButton setImageEdgeInsets:imInsets];
	[newsButton setTitleEdgeInsets:titleInsets];
	
	[newsListController setParentController:self];
	/* Order is important here; we want news list on top of all others */
	[self attachSubviewController:stockDetailController];
	[self attachSubviewController:mutualDetailController];
	[self attachSubviewController:optionDetailController];
	[self attachSubviewController:bondDetailController];
	[self attachSubviewController:graphController];
	[self attachSubviewController:newsListController];
	
	[stockDetailController setPosition:position];
	[mutualDetailController setPosition:position];
	[optionDetailController setPosition:position];
	[bondDetailController setPosition:position];
	[graphController setPosition:position];
	[newsListController setPosition:position];
	
	viewOption = -1;
	[self setViewOption:[[NSUserDefaults standardUserDefaults] integerForKey:kViewOptionKey] animated:NO];
	[self updateFields];
}

- (void)dealloc {
	[calendar release], calendar = nil;
	[dayLabel release], dayLabel = nil;
	[mathLabel release], mathLabel = nil;
	
	[holdingsBackground release], holdingsBackground = nil;
	[positionLabel release], positionLabel = nil;
	[valueLabel release], valueLabel = nil;
	
	[tickerLabel release], tickerLabel = nil;
	[nameLabel release], nameLabel = nil;
	
	[statsButton release], statsButton = nil;
	[graphButton release], graphButton = nil;
	[newsButton release], newsButton = nil;
	
	[newsListController release], newsListController = nil;
	[stockDetailController release], stockDetailController = nil;
	[mutualDetailController release], mutualDetailController = nil;
	[optionDetailController release], optionDetailController = nil;
	[bondDetailController release], bondDetailController = nil;
	[graphController release], graphController = nil;
	
	[position release], position = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
		
    [super dealloc];
}

- (void)setView:(UIView *)aView {
    if (!aView) {
        /* Set outlets to nil (in case this is a memory warning) */
        [self setCalendar:nil];
		[self setDayLabel:nil];
		[self setMathLabel:nil];
		[self setHoldingsBackground:nil];
		[self setPositionLabel:nil];
		[self setValueLabel:nil];
		[self setTickerLabel:nil];
		[self setNameLabel:nil];
		[self setStatsButton:nil];
		[self setGraphButton:nil];
		[self setNewsButton:nil];
		
		/* Unattach these subview controllers but keep them around */
		[[newsListController view] removeFromSuperview];
		[[stockDetailController view] removeFromSuperview];
		[[mutualDetailController view] removeFromSuperview];
		[[optionDetailController view] removeFromSuperview];
		[[bondDetailController view] removeFromSuperview];
		[[graphController view] removeFromSuperview];
    }
    // Invoke super's implementation last
    [super setView:aView];
}

- (void)updateNonNewsPaneVisibility {
	if (![self position]) return;
	
	[[stockDetailController view] setHidden:!(viewOption == POPositionDetailViewOptionStats && [[[self position] security] type] == POSecurityTypeStock)];
	[[mutualDetailController view] setHidden:!(viewOption == POPositionDetailViewOptionStats && [[[self position] security] type] == POSecurityTypeMutualFund)];
	[[optionDetailController view] setHidden:!(viewOption == POPositionDetailViewOptionStats && [[[self position] security] type] == POSecurityTypeOption)];
	[[bondDetailController view] setHidden:!(viewOption == POPositionDetailViewOptionStats && [[[self position] security] type] == POSecurityTypeDebt)];
	
	[[graphController view] setHidden:(viewOption != POPositionDetailViewOptionGraph)];
}

- (void)setViewOption:(POPositionDetailViewOption)opt animated:(BOOL)animated {
	if (opt == viewOption) return;
	
	[statsButton setSelected:(opt == POPositionDetailViewOptionStats)];
	[graphButton setSelected:(opt == POPositionDetailViewOptionGraph)];
	[newsButton setSelected:(opt == POPositionDetailViewOptionNews)];
	
	BOOL delayNonNewsPaneVisibilityUpdate = NO;
	if (animated && (opt == POPositionDetailViewOptionNews || viewOption == POPositionDetailViewOptionNews)) {
		CATransition *anim = [[[CATransition alloc] init] autorelease];
		[anim setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		[anim setDuration:0.6];
		[anim setType:((opt == POPositionDetailViewOptionNews) ? kCATransitionMoveIn : kCATransitionPush)];
		[anim setSubtype:((opt == POPositionDetailViewOptionNews) ? kCATransitionFromTop : kCATransitionFromBottom)];
		if (opt == POPositionDetailViewOptionNews) {
			[anim setDelegate:self];
			delayNonNewsPaneVisibilityUpdate = YES;
		}
		[[[newsListController view] layer] addAnimation:anim forKey:nil];
	}
	
	viewOption = opt;
	[[NSUserDefaults standardUserDefaults] setInteger:opt forKey:kViewOptionKey];
	
	[[newsListController view] setHidden:(opt != POPositionDetailViewOptionNews)];
	if (!delayNonNewsPaneVisibilityUpdate) [self updateNonNewsPaneVisibility];
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
	[self updateNonNewsPaneVisibility];
}

- (void)viewWillAppear:(BOOL)animated {
	[newsListController viewWillAppear:animated];
	[stockDetailController viewWillAppear:animated];
	[mutualDetailController viewWillAppear:animated];
	[optionDetailController viewWillAppear:animated];
	[bondDetailController viewWillAppear:animated];
	[graphController viewWillAppear:animated];
	[super viewWillAppear:animated];
}

- (IBAction)showStats {
	[self setViewOption:POPositionDetailViewOptionStats animated:YES];
}

- (IBAction)showGraph {
	[self setViewOption:POPositionDetailViewOptionGraph animated:YES];
}

- (IBAction)showNews {
	[self setViewOption:POPositionDetailViewOptionNews animated:YES];
}

- (void)updateFields {
	[nameLabel setText:[[position security] name]];
	[tickerLabel setText:[[position security] ticker]];
	
	if ([position change]) {
		[calendar setTitle:[[PONumberFormatters detailChangeFormatter] stringFromNumber:[position change]] forState:UIControlStateNormal];
		
		if ([[NSDecimalNumber zero] compare:[position change]] == NSOrderedDescending) {
			[calendar setImage:[UIImage imageNamed:@"arrow_down.png"] forState:UIControlStateNormal];
		} else {
			[calendar setImage:[UIImage imageNamed:@"arrow_up.png"] forState:UIControlStateNormal];
		}
		
		[mathLabel setText:[NSString stringWithFormat:@"%@ ✕ %@",
							[[PONumberFormatters priceChangeFormatter] stringFromNumber:[[position security] change]],
							[[PONumberFormatters sharesFormatter] stringFromNumber:[position units]]]];
		
		[calendar setEnabled:YES];
	} else {
		[calendar setTitle:@"" forState:UIControlStateNormal];
		[calendar setImage:nil forState:UIControlStateNormal];
		[mathLabel setText:@""];
		[calendar setEnabled:NO];
	}
	
	/* TODO shorts, etc. */
	if ([[position security] price]) {
		[positionLabel setText:[NSString stringWithFormat:NSLocalizedString(@"%@ shares @ %@", @"Number of shares and price in a position"), 
								[[PONumberFormatters sharesFormatter] stringFromNumber:[position units]],
								[[PONumberFormatters priceFormatter] stringFromNumber:[[position security] price]]]];		
	} else {
		[positionLabel setText:[NSString stringWithFormat:NSLocalizedString(@"%@ shares", @"Number of shares and price in a position, if no price available"), 
								[[PONumberFormatters sharesFormatter] stringFromNumber:[position units]]]];
	}
	[positionLabel sizeToFit];
	
	[valueLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Value: %@", @"Value of a position"), 
						 [[PONumberFormatters detailValueFormatter] stringFromNumber:[position value]]]];
	[valueLabel sizeToFit];
	
	CGRect frame = [holdingsBackground frame];
	frame.size.width = MAX([valueLabel frame].size.width, [positionLabel frame].size.width) + 16;
	[holdingsBackground setFrame:frame];
}

- (void)setPosition:(POPosition *)aPosition {
	[self view]; /* Ensure view is loaded */
	
	if (aPosition != position) {
		[position release];
		position = [aPosition retain];
		
		if (position) {
			[position addObserver:self forKeyPath:@"units" options:0 context:nil];
			[self updateFields];
		}
		
		[newsListController setPosition:aPosition];
		[stockDetailController setPosition:aPosition];
		[mutualDetailController setPosition:aPosition];
		[optionDetailController setPosition:aPosition];
		[bondDetailController setPosition:aPosition];
		[graphController setPosition:aPosition];
		[self updateNonNewsPaneVisibility];
	}
}

- (POPosition *)position {
	return position;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == position) {
		if ([keyPath isEqualToString:@"units"]) {
			[self updateFields];
		} else {
			NSLog(@"Unexpected keypath %@ in POPositionDetailController.observeValueForKeyPath", keyPath);
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)securitiesRefreshed:(NSNotification *)notification {
	if (position)
		[self updateFields];
}

@end
