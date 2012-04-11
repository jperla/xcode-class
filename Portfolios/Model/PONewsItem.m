//
//  PONewsItem.m
//  Portfolios
//
//  Created by Adam Ernst on 3/7/09.
//  Copyright 2009 cosmicsoft. All rights reserved.
//

#import "PONewsItem.h"

#define kTitleKey @"title"
#define kUrlKey @"url"

@implementation PONewsItem

@synthesize title, url;

+ (PONewsItem *)newsItemWithTitle:(NSString *)aTitle url:(NSString *)aUrl {
	return [[[PONewsItem alloc] initWithTitle:aTitle url:aUrl] autorelease];
}

- (id)initWithTitle:(NSString *)aTitle url:(NSString *)aUrl {
	if (self = [super init]) {
		title = [aTitle copy];
		url = [aUrl copy];
	}
	return self;
}

- (void)dealloc {
	[title release];
	[url release];
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		title = [[decoder decodeObjectForKey:kTitleKey] retain];
		url = [[decoder decodeObjectForKey:kUrlKey] retain];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:title forKey:kTitleKey];
	[encoder encodeObject:url forKey:kUrlKey];
}

@end
