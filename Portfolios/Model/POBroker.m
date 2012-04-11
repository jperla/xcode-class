//
//  POBroker.m
//  Portfolio
//
//  Created by Adam Ernst on 11/20/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "POBroker.h"


@implementation POBroker

static NSArray *allBrokers;

+ (NSArray *)allBrokers {
	@synchronized(self) {
		if (allBrokers == nil) {
			allBrokers = [[NSArray arrayWithObjects:
						   [POBroker brokerWithName:@"Schwab" resourceName:@"schwab.png" url:@"https://ofx.schwab.com/cgi_dev/ofx_server"],
						   [POBroker brokerWithName:@"E*TRADE" resourceName:@"etrade.png" url:@"https://ofx.etrade.com/cgi-ofx/etradeofx"],
						   [POBroker brokerWithName:@"TD Ameritrade" resourceName:@"ameritrade.png" url:@"https://ofxs.ameritrade.com/cgi-bin/apps/OFX"],
						   [POBroker brokerWithName:@"Scottrade" resourceName:@"scottrade.png" url:@"https://ofxstl.scottsave.com"],
						   /*[POBroker brokerWithName:@"Fidelity" resourceName:@"fidelity.png" url:@"https://ofx.fidelity.com/ftgw/OFX/clients/download"], 
						   [POBroker brokerWithName:@"Vanguard" resourceName:@"vanguard.png" url:@"https://vesnc.vanguard.com/us/OfxDirectConnectServlet"],*/
						   nil] retain];
		}
	}
	return allBrokers;
}

@synthesize name, resourceName, url;


+ (POBroker *)brokerWithName:(NSString *)newName resourceName:(NSString *)newResourceName url:(NSString *)newUrl {
	return [[[POBroker alloc] initWithName:newName resourceName:newResourceName url:newUrl] autorelease];
}

- (id)initWithName:(NSString *)newName resourceName:(NSString *)newResourceName url:(NSString *)newUrl {
	if (self = [super init]) {
		name = [newName copy];
		resourceName = [newResourceName copy];
		url = [newUrl copy];
	}
	return self;
}

- (void)dealloc {
	[name release];
	[resourceName release];
	[url release];
	[super dealloc];
}

@end
