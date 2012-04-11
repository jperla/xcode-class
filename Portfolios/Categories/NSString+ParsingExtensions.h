//
//  NSString+ParsingExtensions.h
//  Portfolios
//
//  Created by Adam Ernst on 3/21/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (ParsingExtensions)

-(NSArray *)csvRows;
- (NSDecimalNumber *)decimalNumberByParsingWithLocale:(NSLocale *)locale;

@end
