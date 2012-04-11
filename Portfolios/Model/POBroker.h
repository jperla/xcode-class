//
//  POBroker.h
//  Portfolio
//
//  Created by Adam Ernst on 11/20/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface POBroker : NSObject {
	NSString *name;
	NSString *resourceName; /* Name of the PNG image resource */
	NSString *url;
	// ...
}

+ (NSArray *)allBrokers;

+ (POBroker *)brokerWithName:(NSString *)newName resourceName:(NSString *)newResourceName url:(NSString *)newUrl;

- (id)initWithName:(NSString *)newName resourceName:(NSString *)newResourceName url:(NSString *)newUrl;

@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *resourceName;
@property (nonatomic, readonly, copy) NSString *url;

@end
