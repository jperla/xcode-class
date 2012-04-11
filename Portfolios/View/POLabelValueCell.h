//
//  POLabelValueCell.h
//  Portfolios
//
//  Created by Adam Ernst on 3/14/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface POLabelValueCell : UITableViewCell {
	UILabel *label;
	UILabel *value;
}

@property(nonatomic, retain) UIFont *labelFont;
@property(nonatomic, retain) UIFont *valueFont;

@property(nonatomic, retain) UIColor *labelTextColor;
@property(nonatomic, retain) UIColor *valueTextColor;

@property(nonatomic, copy) NSString *labelText;
@property(nonatomic, copy) NSString *valueText;

- (id)initWithLabelWidth:(CGFloat)labelWidth reuseIdentifier:(NSString *)anIdentifier;

@end
