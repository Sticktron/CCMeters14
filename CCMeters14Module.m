//
//  CCMeters14Module.m
//  CCMeters14
//
//  Copyright © Sticktron. All rights reserved.
//

#define DEBUG_PREFIX @" [CCMeters14Module] >> "
#import "DebugLog.h"

#import "CCMeters14Module.h"
#import "CCMeters14ViewController.h"

@implementation CCMeters14Module

//override the init to initialize the contentViewController (and the backgroundViewController if you have one)
- (instancetype)init {
    if ((self = [super init])) {
        DebugLog(@"init()");
        _contentViewController = [[CCMeters14ViewController alloc] init];
	}
    return self;
}

@end
