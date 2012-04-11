//
//  SgmlContentElement.h
//  Portfolio
//
//  Created by Adam Ernst on 11/24/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SgmlElement.h"


@interface SgmlContentElement : SgmlElement {
	NSString *content;
}

+ (SgmlContentElement *)contentElementWithName:(NSString *)newName content:(NSString *)newContent;

- (id)initWithName:(NSString *)newName content:(NSString *)newContent;

@end
