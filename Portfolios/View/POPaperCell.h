//
//  POPaperCell.h
//  Portfolio
//
//  Created by Adam Ernst on 2/6/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface POPaperCell : UITableViewCell {
	UIImageView  *shadowView;
	UIView       *topBorder;
}

@property (nonatomic) BOOL showsShadow;
@property (nonatomic) BOOL showsTopBorder;

@end

@interface UITableView (POPaperCellAdditions)

- (void)updatePaperCellsAfterCellMovedFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

@end
