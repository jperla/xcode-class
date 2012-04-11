//
//  POChangeLabel.h
//  Portfolio
//
//  Created by Adam Ernst on 2/6/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	POChangeLabelStyleRed,
	POChangeLabelStyleGreen
} POChangeLabelColor;

static const int kGlowTopMargin = 16;
static const int kGlowBottomMargin = 16;
static const int kGlowLeftMargin = 16;
static const int kGlowRightMargin = 16;

@interface POChangeLabel : UILabel {
	BOOL glowing;
	POChangeLabelColor color;
}

@property (nonatomic,getter=isGlowing) BOOL glowing;

- (void)setChange:(NSDecimalNumber *)aChange withValue:(NSDecimalNumber *)aValue;
+ (NSInteger)widthForChange:(NSDecimalNumber *)aChange withValue:(NSDecimalNumber *)aValue;

@end
