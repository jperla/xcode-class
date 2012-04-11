//
//  POAccountCell.h
//  Portfolio
//
//  Created by Adam Ernst on 12/2/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "POPaperCell.h"

@class POAccount, POChangeLabel;

static NSInteger POAccountCellDefaultChangeWidth = 38;

@interface POAccountCell : POPaperCell {
	POAccount     *account;
	POChangeLabel *changeLabel;
	UILabel       *valueLabel;
	UILabel       *nameLabel;
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (void)setAccount:(POAccount *)acc;

@property (nonatomic) NSInteger changeLabelWidth;

@end
