//
//  POLabelCell.h
//  Portfolio
//
//  Created by Adam Ernst on 11/21/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
	POLabelCellStyleGrouped,
	POLabelCellStyleCardTop,
	POLabelCellStyleCardBottom
} POLabelCellStyle;

@interface POLabelCell : UITableViewCell {
	UILabel *label;
	POLabelCellStyle style;
}

- (id)initWithText:(NSString *)newText style:(POLabelCellStyle)style;
- (CGFloat)height;

@property(nonatomic, retain) UIFont *font;
@property(nonatomic, retain) UIColor *textColor;
@property(nonatomic) POLabelCellStyle style;

@end
