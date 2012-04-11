//
//  POPaperCell.m
//  Portfolio
//
//  Created by Adam Ernst on 2/6/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "POPaperCell.h"

@implementation POPaperCell

- (void)dealloc {
	if (shadowView) [shadowView release];
	if (topBorder) [topBorder release];
    [super dealloc];
}

- (BOOL)showsShadow {
	return (shadowView != nil);
}

- (void)setShowsShadow:(BOOL)showShadow {
	if ([self showsShadow] == showShadow) return;
	
	if (showShadow) {
		shadowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shadow.png"]];
		[shadowView setFrame:CGRectMake(0, [self frame].size.height, [self frame].size.width, [shadowView frame].size.height)];
		[shadowView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin];
		[self addSubview:shadowView];
	} else {
		[shadowView removeFromSuperview];
		[shadowView release];
		shadowView = nil;
	}
}

- (BOOL)showsTopBorder {
	return (topBorder != nil);
}

- (void)setShowsTopBorder:(BOOL)showTopBorder {
	if ([self showsTopBorder] == showTopBorder) return;
	
	if (showTopBorder) {
		topBorder = [[UIView alloc] initWithFrame:CGRectMake(0, -1, [self frame].size.width, 1)];
		[topBorder setBackgroundColor:[UIColor colorWithRed:0.416 green:0.404 blue:0.373 alpha:1.0]];
		[self addSubview:topBorder];
	} else {
		[topBorder removeFromSuperview];
		[topBorder release];
		topBorder = nil;		
	}
}

- (void)prepareForReuse {
	[self setShowsShadow:NO];
	[self setShowsTopBorder:NO];
	[super prepareForReuse];
}

@end

@implementation UITableView (POPaperCellAdditions)

- (void)updatePaperCellsAfterCellMovedFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	NSUInteger toRow = [toIndexPath row];
	NSUInteger fromRow = [fromIndexPath row];
	NSUInteger lastRow = [self numberOfRowsInSection:0] - 1;
	
	if (toRow == 0) { // Remove top border from old top cell
		[(POPaperCell *)[self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] setShowsTopBorder:NO];
	}
	if (toRow == lastRow) { // Remove shadow from old bottom cell
		[(POPaperCell *)[self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:lastRow inSection:0]] setShowsShadow:NO];
	}
	if (fromRow == 0) { // Add border to new top cell
		[(POPaperCell *)[self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] setShowsTopBorder:YES];
	}
	if (fromRow == lastRow) { // Add shadow to new bottom cell
		[(POPaperCell *)[self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:lastRow - 1 inSection:0]] setShowsShadow:YES];
	}
	
	POPaperCell *movedCell = (POPaperCell *) [self cellForRowAtIndexPath:fromIndexPath];
	[movedCell setShowsShadow:(toRow == lastRow)];
	[movedCell setShowsTopBorder:(toRow == 0)];	
}

@end
