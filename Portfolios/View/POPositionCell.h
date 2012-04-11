//
//  POPositionCell.h
//  Portfolio
//
//  Created by Adam Ernst on 2/6/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "POPaperCell.h"

@class POPosition, POChangeLabel;

static const NSInteger POPositionCellDefaultChangeWidth = 50;
static const NSInteger POPositionCellValueWidth = 104;

@interface POPositionCell : POPaperCell {
	POPosition    *position;
	POChangeLabel *changeLabel;
	UILabel       *valueLabel;
	UILabel       *nameLabel;
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (void)setInsertMode;

@property (nonatomic, retain) POPosition *position;
@property (nonatomic) NSInteger changeLabelWidth;

@end
