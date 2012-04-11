//
//  POStockDetailController.h
//  Portfolios
//
//  Created by Adam Ernst on 3/15/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>


@class POPosition;

@interface POStockDetailController : UIViewController {
	POPosition *position;
	
	IBOutlet UILabel *volumeLabel;
	IBOutlet UILabel *peLabel;
	IBOutlet UILabel *dividendLabel;
	IBOutlet UILabel *marketCapLabel;
	IBOutlet UILabel *epsLabel;
	
	IBOutlet UILabel *dayLabel;
	IBOutlet UILabel *yearLabel;
}

@property (nonatomic, retain) POPosition *position;

@property (nonatomic, retain) UILabel *volumeLabel;
@property (nonatomic, retain) UILabel *peLabel;
@property (nonatomic, retain) UILabel *dividendLabel;
@property (nonatomic, retain) UILabel *marketCapLabel;
@property (nonatomic, retain) UILabel *epsLabel;
@property (nonatomic, retain) UILabel *dayLabel;
@property (nonatomic, retain) UILabel *yearLabel;

@end
