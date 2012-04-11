//
//  POPositionEditController.m
//  Portfolios
//
//  Created by Adam Ernst on 5/8/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POPositionEditController.h"
#import "POAccount.h"
#import "POPosition.h"
#import "PONumberFormatters.h"
#import "POSecurity.h"
#import "POTicker.h"
#import "POTickerCell.h"
#import "POPositionListController.h"
#import "POSecurities.h"

#define kTickerCellId @"kTickerCellId"

NSString *POPositionEditPaneDidUpdatePositionNotification = @"POPositionEditPaneDidUpdatePositionNotification";

@implementation POPositionEditController

- (id)initWithPosition:(POPosition *)pos account:(POAccount *)acc {
	if (self = [super initWithNibName:@"POPositionEdit" bundle:[NSBundle mainBundle]]) {
		position = [pos retain];
		account = [acc retain];
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[longButton setBackgroundImage:[[UIImage imageNamed:@"toggle_left_up.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateNormal];
	[longButton setBackgroundImage:[[UIImage imageNamed:@"toggle_left_down.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateSelected];
	[shortButton setBackgroundImage:[[UIImage imageNamed:@"toggle_right_up.png"] stretchableImageWithLeftCapWidth:1 topCapHeight:0] forState:UIControlStateNormal];
	[shortButton setBackgroundImage:[[UIImage imageNamed:@"toggle_right_down.png"] stretchableImageWithLeftCapWidth:1 topCapHeight:0] forState:UIControlStateSelected];
	
	[longButton setTitleColor:[UIColor colorWithRed:0.36 green:0.345 blue:0.302 alpha:1.0] forState:UIControlStateNormal];
	[longButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
	[shortButton setTitleColor:[UIColor colorWithRed:0.36 green:0.345 blue:0.302 alpha:1.0] forState:UIControlStateNormal];
	[shortButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
	
	[[self navigationItem] setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)] autorelease]];
	[[self navigationItem] setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)] autorelease]];
	
	if (position) {
		[[self navigationItem] setTitle:NSLocalizedString(@"Edit Position", @"")];
		
		[tickerField setText:[[position security] ticker]];
		[tickerField setEnabled:NO];
		
		[quantityField setText:[[PONumberFormatters sharesFormatter] stringFromNumber:[position units]]];
	} else {
		[[self navigationItem] setTitle:NSLocalizedString(@"Add Position", @"")];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	if (position) {
		// Edit qty field
		[quantityField becomeFirstResponder];
	} else {
		// Edit ticker field, if this is a *new* position.
		[tickerField becomeFirstResponder];
	}
}

- (void)didReceiveMemoryWarning {
	// Ignore.
}

- (void)dealloc {
	[position release];
	[account release];
    [super dealloc];
}

- (IBAction)cancel:(id)sender {
	[[self navigationController] dismissModalViewControllerAnimated:YES];
}

- (NSString*)UUIDString {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return [(NSString *)string autorelease];
}

- (IBAction)done:(id)sender {
	NSDecimalNumber *qty = nil;
	@try {
		qty = [NSDecimalNumber decimalNumberWithString:[quantityField text] locale:[NSLocale currentLocale]];
		if (qty == [NSDecimalNumber notANumber]) qty = nil;
	} @catch (NSException *e) {
	}
	
	if (qty == nil) {
		return;
	}
	
	if ([[tickerField text] length] == 0) {
		return;
	}
	
	NSString *symbol = [[tickerField text] uppercaseString];
	
	if (position == nil) {
		POSecurity *security = [[POSecurities sharedSecurities] securityWithTicker:symbol];
		if (security == nil) {
			// Try to guess what type of security this is
			POSecurityType type = POSecurityTypeStock;
			NSString *name = @"";
			
			POTicker *ticker = [POTicker tickerWithSymbol:symbol];
			if (ticker) {
				name = [ticker name];
				if ([[ticker exchange] isEqualToString:@"MUTF"]) {
					type = POSecurityTypeMutualFund;
				}
			}
			
			security = [[POSecurities sharedSecurities] createSecurityWithUniqueId:[self UUIDString] ofType:@"PortfoliosUUID" ticker:symbol type:type name:@""];
		} else {
			POPosition *existingPosition = nil;
			for (POPosition *e in [account mutableArrayValueForKey:@"positions"]) {
				if ([e security] == security) {
					existingPosition = e;
					break;
				}
			}
			
			if (existingPosition) {
				if ([sender respondsToSelector:@selector(class)] && [[(NSObject *)sender class] isSubclassOfClass:[UIActionSheet class]]) {
					// Merge positions was selected in the action sheet.
					[existingPosition setUnits:[[existingPosition units] decimalNumberByAdding:qty]];
					[[NSNotificationCenter defaultCenter] postNotificationName:POPositionEditPaneDidUpdatePositionNotification object:existingPosition];
					[[self navigationController] dismissModalViewControllerAnimated:YES];
					return;
				} else {
					UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"A position with ticker symbol %@ already exists in \"%@\".", @"Position with ticker symbol AAPL already exists in \"Portfolio Name\""), [security ticker], [account name]]
																	   delegate:self 
															  cancelButtonTitle:NSLocalizedString(@"Cancel", @"") 
														 destructiveButtonTitle:nil 
															  otherButtonTitles:NSLocalizedString(@"Merge Positions", @""), nil];
					[sheet showInView:[self view]];
					[sheet release];
					
					return;
				}
			}
		}
		
		POPosition *pos = [[POPosition alloc] initWithSecurity:security];
		[pos setUnits:qty];
		[pos setIsLong:YES];
		
		[account insertObject:pos inPositionsAtIndex:0];
	} else {
		[position setUnits:qty];
		
		// Need to tell parent to re-sort list.
		[[NSNotificationCenter defaultCenter] postNotificationName:POPositionEditPaneDidUpdatePositionNotification object:position];
	}
	
	[[self navigationController] dismissModalViewControllerAnimated:YES];
}

- (void)setSearchTableVisible:(BOOL)visible {
	[searchTable setHidden:!visible];
	[quantityBackground setHidden:visible];
	[quantityLabel setHidden:visible];
	[quantityField setHidden:visible];
	//[shortButton setHidden:visible];
	//[longButton setHidden:visible];
}

- (IBAction)tickerFieldDone:(id)sender {
	[searchTable deselectRowAtIndexPath:[searchTable indexPathForSelectedRow] animated:NO];
	[self setSearchTableVisible:NO];
	[quantityField becomeFirstResponder];
}

- (IBAction)longButton:(id)sender {
	if ([shortButton isSelected]) {
		[shortButton setSelected:NO];
		[longButton setSelected:YES];
	}
}

- (IBAction)shortButton:(id)sender {
	if ([longButton isSelected]) {
		[longButton setSelected:NO];
		[shortButton setSelected:YES];
	}
}

- (IBAction)tickerFieldDidChange:(id)sender {
	if (settingTickerToResult) return;
	
	[currentSearchResults release], currentSearchResults = [[NSArray array] retain];
	
	[self setSearchTableVisible:([[tickerField text] length] > 0)];
	
	if (![indicatorView isAnimating]) {
		[indicatorView startAnimating];
	}
	showingLocalResults = NO;
	showingRemoteResults = NO;
	
	// Delay the local search invocation if it's 2 chars or less, since those are most expensive
	if ([[tickerField text] length] > 0 && [[tickerField text] length] <= 2) {
		[self performSelector:@selector(fetchLocalResultsDelayed:) withObject:[[[tickerField text] copy] autorelease] afterDelay:0.75];
	} else {
		[self performSelectorInBackground:@selector(fetchLocalResults:) withObject:[tickerField text]];
	}
	
	// Always delay the remote invocation
	[self performSelector:@selector(fetchRemoteResultsDelayed:) withObject:[[[tickerField text] copy] autorelease] afterDelay:0.75];
}

- (void)fetchRemoteResultsDelayed:(NSString *)search {
	if ([[tickerField text] isEqualToString:search]) {
		[self performSelectorInBackground:@selector(fetchRemoteResults:) withObject:search];
	}
}

- (void)fetchLocalResultsDelayed:(NSString *)search {
	if ([[tickerField text] isEqualToString:search]) {
		[self performSelectorInBackground:@selector(fetchLocalResults:) withObject:search];
	}
}

#pragma mark Background Searching

enum {
	POLocalResults,
	PORemoteResults
};

- (void)fetchRemoteResults:(NSString *)search {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *results = [POTicker remoteTickersContaining:search];
	NSInteger type = PORemoteResults;
	
	SEL selector = @selector(updateSearchResults:forSearch:ofType:);
	NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[[POPositionEditController class] instanceMethodSignatureForSelector:selector]];
	[inv setSelector:selector];
	[inv setArgument:&results atIndex:2];
	[inv setArgument:&search atIndex:3];
	[inv setArgument:&type atIndex:4];
	[inv performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:self waitUntilDone:YES];
	
	[pool release];
}

- (void)fetchLocalResults:(NSString *)search {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *results = [POTicker localTickersContaining:search];
	NSInteger type = POLocalResults;
	
	SEL selector = @selector(updateSearchResults:forSearch:ofType:);
	NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[[POPositionEditController class] instanceMethodSignatureForSelector:selector]];
	[inv setSelector:selector];
	[inv setArgument:&results atIndex:2];
	[inv setArgument:&search atIndex:3];
	[inv setArgument:&type atIndex:4];
	[inv performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:self waitUntilDone:YES];
	
	[pool release];
}

NSInteger searchSort(id ticker1, id ticker2, void *context)
{
	NSString *symbol1 = [(POTicker *)ticker1 symbol];
	NSString *symbol2 = [(POTicker *)ticker2 symbol];
	
	BOOL symbol1HasPeriod = ([symbol1 rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]].location != NSNotFound);
	BOOL symbol2HasPeriod = ([symbol2 rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]].location != NSNotFound);
	
	// Penalize periods since they tend to be obscure stocks.
	if (!symbol1HasPeriod && symbol2HasPeriod) {
		return NSOrderedAscending;
	} else if (symbol1HasPeriod && !symbol2HasPeriod) {
		return NSOrderedDescending;
	}
	
	NSUInteger s1 = [symbol1 rangeOfString:(NSString *)context options:NSCaseInsensitiveSearch].location;
	NSUInteger s2 = [symbol2 rangeOfString:(NSString *)context options:NSCaseInsensitiveSearch].location;
	
	if (s1 < s2) {
		return NSOrderedAscending;
	} else if (s1 > s2) {
		return NSOrderedDescending;
	} else {
		if (s1 == NSNotFound) {
			// Neither symbol even *has* the search string. Compare by name.
			NSUInteger n1 = [[(POTicker *)ticker1 name] rangeOfString:(NSString *)context options:NSCaseInsensitiveSearch].location;
			NSUInteger n2 = [[(POTicker *)ticker2 name] rangeOfString:(NSString *)context options:NSCaseInsensitiveSearch].location;
			
			if (n1 < n2) {
				return NSOrderedAscending;
			} else if (n1 > n2) {
				return NSOrderedDescending;
			} else {
				// Both names have the same location of the search string. Prefer shorter ticker.
				if ([symbol1 length] < [symbol2 length]) {
					return NSOrderedAscending;
				} else if ([symbol2 length] < [symbol1 length]) {
					return NSOrderedDescending;
				} else {
					return NSOrderedSame;
				}
			}
		} else {
			return [symbol1 compare:symbol2 options:NSCaseInsensitiveSearch];
		}
	}
}

- (void)updateSearchResults:(NSArray *)results forSearch:(NSString *)search ofType:(NSInteger)type {
	// Discard search results that have arrived too late
	if (![[tickerField text] isEqualToString:search]) return;
		
	NSMutableSet *allSymbols = [NSMutableSet setWithCapacity:[currentSearchResults count]];
	for (POTicker *t in currentSearchResults) {
		[allSymbols addObject:[t symbol]];
	}
		
	NSMutableArray *newTickers = [NSMutableArray arrayWithCapacity:16];
	for (POTicker *t in results) {
		if (![allSymbols containsObject:[t symbol]]) {
			[newTickers addObject:t];
		}
	}
		
	NSArray *newCurrentSearchResults = [[currentSearchResults arrayByAddingObjectsFromArray:newTickers] sortedArrayUsingFunction:&searchSort context:search];
	[currentSearchResults release];
	currentSearchResults = [newCurrentSearchResults retain];
	
	[searchTable reloadData];
	
	if (type == PORemoteResults) {
		showingRemoteResults = YES;
	} else if (type == POLocalResults) {
		showingLocalResults = YES;
	}
	
	if (showingLocalResults && showingRemoteResults) {
		[indicatorView stopAnimating];
	}
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (currentSearchResults ? [currentSearchResults count] : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	POTickerCell *cell = (POTickerCell *) [tableView dequeueReusableCellWithIdentifier:kTickerCellId];
	if (!cell) {
		cell = [[[POTickerCell alloc] initWithFrame:CGRectZero reuseIdentifier:kTickerCellId] autorelease];
	}
	POTicker *ticker = [currentSearchResults objectAtIndex:[indexPath row]];
	[cell setSymbol:[ticker symbol] name:[[ticker name] uppercaseString]];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	POTicker *ticker = [currentSearchResults objectAtIndex:[indexPath row]];
	settingTickerToResult = YES;
	[tickerField setText:[ticker symbol]];
	settingTickerToResult = NO;
	
	[indicatorView stopAnimating];
	
	[self tickerFieldDone:self];
}

#pragma mark UIActionSheetDelegate

// Action sheet used if position already exists with selected ticker symbol
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == [actionSheet firstOtherButtonIndex]) {
		// Setting sender to a UIActionSheet indicates we should merge positions.
		[self done:actionSheet];
	}
}

@end
