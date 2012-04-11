//
//  SgmlContentElement.m
//  Portfolio
//
//  Created by Adam Ernst on 11/24/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "SgmlContentElement.h"


@implementation SgmlContentElement

+ (SgmlContentElement *)contentElementWithName:(NSString *)newName content:(NSString *)newContent {
	return [[[SgmlContentElement alloc] initWithName:newName content:newContent] autorelease];
}

@synthesize content;

- (id)initWithName:(NSString *)newName content:(NSString *)newContent {
	if (self = [super initWithName:newName]) {
		content = [newContent retain];
	}
	return self;
}

- (void)dealloc {
	[content release];
	[super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@>%@</%@>", name, content, name];
}

- (NSArray *)elementsForXPathComponents:(NSArray *)xpath error:(NSError **)error {
	if ([xpath count] == 0) return [NSArray arrayWithObject:self];
	return [NSArray array];
}

@end
