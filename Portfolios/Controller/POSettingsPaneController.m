//
//  POSettingsPaneController.m
//  Portfolios
//
//  Created by Adam Ernst on 3/16/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POSettingsPaneController.h"
#import "POLabelCell.h"
#import "POSettings.h"


@implementation POSettingsPaneController

- (void)loadView {
	[[self navigationItem] setTitle:NSLocalizedString(@"Settings", @"")];
	[[self navigationItem] setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleDone target:self action:@selector(done:)] autorelease]];
	
	[super loadView];
	[[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
	
	tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [[self view] frame].size.width, [[self view] frame].size.height) style:UITableViewStylePlain];
	[tableView setBackgroundColor:[UIColor clearColor]];
	[tableView setOpaque:NO];
	[tableView setDelegate:self];
	[tableView setDataSource:self];
	[tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	[[self view] addSubview:tableView];
}

- (void)dealloc {
	[tableView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
	// Do nothing
}

/* Much easier than a custom table cell subclass is just these check/uncheck methods. */
- (void)cell:(UITableViewCell *)aCell setChecked:(BOOL)checked {
	if (checked) {
		[aCell setImage:[UIImage imageNamed:@"check.png"]];
		[aCell setSelectedImage:[UIImage imageNamed:@"check.png"]];
	} else {
		[aCell setImage:[UIImage imageNamed:@"check_empty.png"]];
		[aCell setSelectedImage:[UIImage imageNamed:@"check_empty.png"]];
	}
	[aCell setNeedsLayout]; /* Apparently needed to rejigger the cell into realizing it has a new image */
}

#pragma mark Table View Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	
	switch ([indexPath row]) {
		case 1:
		case 5:
			cell = [[[POLabelCell alloc] initWithText:@"" style:POLabelCellStyleCardTop] autorelease];
			break;
		case 4:
		case 9:
			cell = [[[POLabelCell alloc] initWithText:@"" style:POLabelCellStyleCardBottom] autorelease];
			break;
		default:
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:nil] autorelease];
			[cell setIndentationWidth:16.0f];
			[cell setIndentationLevel:1];
			[cell setFont:[UIFont boldSystemFontOfSize:16.0]];
			[cell setTextColor:[UIColor colorWithWhite:0.33 alpha:1.0]];
			[cell setSelectedTextColor:[cell textColor]];
			break;
	}
	
	switch ([indexPath row]) {
		case 0:
			[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
			break;
		case 2:
			[cell setText:NSLocalizedString(@"Show change as value", @"")];
			[self cell:cell setChecked:![[POSettings sharedSettings] showsChangeAsPercent]];
			[cell setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_cell_top.png"]] autorelease]];
			[cell setSelectedBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_cell_top_selected.png"]] autorelease]];
			break;
		case 3:
			[cell setText:NSLocalizedString(@"Show change as percent", @"")];
			[self cell:cell setChecked:[[POSettings sharedSettings] showsChangeAsPercent]];
			[cell setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_cell_bottom.png"]] autorelease]];
			[cell setSelectedBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_cell_bottom_selected.png"]] autorelease]];
			break;
		case 5:
			[(POLabelCell *)cell setText:NSLocalizedString(@"Sort positions list by:", @"")];
			break;
		case 6:
			[cell setText:NSLocalizedString(@"Total Value", @"")];
			[self cell:cell setChecked:[[POSettings sharedSettings] positionListSortOption]==POSettingsPositionListSortTotalValue];
			[cell setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_cell_top.png"]] autorelease]];
			[cell setSelectedBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_cell_top_selected.png"]] autorelease]];
			break;
		case 7:
			[cell setText:NSLocalizedString(@"Day Change", @"")];
			[self cell:cell setChecked:[[POSettings sharedSettings] positionListSortOption]==POSettingsPositionListSortDayChange];
			[cell setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_cell_middle.png"]] autorelease]];
			[cell setSelectedBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_cell_middle_selected.png"]] autorelease]];
			break;
		case 8:
			[cell setText:NSLocalizedString(@"Ticker Symbol", @"")];
			[self cell:cell setChecked:[[POSettings sharedSettings] positionListSortOption]==POSettingsPositionListSortTickerSymbol];
			[cell setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_cell_bottom.png"]] autorelease]];
			[cell setSelectedBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_cell_bottom_selected.png"]] autorelease]];
			break;
	}
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ([indexPath row]) {
		case 0:
			return 12; /* Blank cell */
		case 1:
			return 13; /* Section topper with no text */
		case 4:
			return 33; /* Section bottom with no text */
		case 5:
			return 41; /* Section topper with text */
		case 9:
			return 54; /* Section bottom with text */
		default:
			return 45; /* Rows */
	}
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	BOOL newShowsAsPercent;
	POSettingsPositionListSortOption newOption;
	
	switch ([indexPath row]) {
		case 2: /* Show change as value */
		case 3: /* Show change as percent */
			newShowsAsPercent = ([indexPath row] == 3);
			[[POSettings sharedSettings] setShowsChangeAsPercent:newShowsAsPercent];
			
			[self cell:[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]] setChecked:!newShowsAsPercent];
			[self cell:[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]] setChecked:newShowsAsPercent];
			break;
		case 6: /* Sort by total value */
		case 7: /* Sort by day change */
		case 8: /* Sort by ticker symbol */
			newOption = ([indexPath row] == 6) ? POSettingsPositionListSortTotalValue : (([indexPath row] == 7) ? POSettingsPositionListSortDayChange : POSettingsPositionListSortTickerSymbol);
			[[POSettings sharedSettings] setPositionListSortOption:newOption];
			
			[self cell:[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:6 inSection:0]] setChecked:(newOption == POSettingsPositionListSortTotalValue)];
			[self cell:[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:7 inSection:0]] setChecked:(newOption == POSettingsPositionListSortDayChange)];
			[self cell:[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:8 inSection:0]] setChecked:(newOption == POSettingsPositionListSortTickerSymbol)];
			break;
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)done:(id)sender {
	[[self navigationController] dismissModalViewControllerAnimated:YES];
}

@end
