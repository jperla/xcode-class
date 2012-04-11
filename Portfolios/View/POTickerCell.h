//
//  POTickerCell.h
//  Portfolios
//
//  Created by Adam Ernst on 5/9/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface POTickerCell : UITableViewCell {
	UILabel *symbolLabel;
	UILabel *nameLabel;
}

- (void)setSymbol:(NSString *)symbol name:(NSString *)name;

@end
