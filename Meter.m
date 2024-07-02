//
//  Meter.m
//  CCMeters14
//
//  Copyright © 2024 Sticktron. All rights reserved.
//

#import "Meter.h"

@implementation Meter

- (instancetype)initWithName:(NSString *)name title:(NSString *)title {
    if (self = [super init]) {
        _name = name;
        _title = title;
        _enabled = YES;
    }
    return self;
}

@end
