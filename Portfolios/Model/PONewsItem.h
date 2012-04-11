//
//  PONewsItem.h
//  Portfolios
//
//  Created by Adam Ernst on 3/7/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PONewsItem : NSObject <NSCoding> {
	NSString *title;
	NSString *url;
}

+ (PONewsItem *)newsItemWithTitle:(NSString *)aTitle url:(NSString *)aUrl;
- (id)initWithTitle:(NSString *)aTitle url:(NSString *)aUrl;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *url;

@end
