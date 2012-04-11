//
//  POSelectAccountCell.h
//  Portfolio
//
//  Created by Adam Ernst on 11/25/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	POSelectAccountCellTypeSingleCell,
	POSelectAccountCellTypeTopCell,
	POSelectAccountCellTypeMiddleCell,
	POSelectAccountCellTypeBottomCell
} POSelectAccountCellType;


@interface POSelectAccountCell : UITableViewCell {
	UITextField *field;
	UIButton    *checkbox;
}

- (id)initWithText:(NSString *)text;
- (void)setType:(POSelectAccountCellType)type;

@property (nonatomic,getter=isChecked) BOOL checked;
@property (nonatomic,getter=isEnabled) BOOL enabled;

@end
