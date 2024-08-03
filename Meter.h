//
//  Meter.h
//  CCMeters14
//
//  Copyright © 2024 Sticktron. All rights reserved.
//

//#import <Foundation/Foundation.h>
//#import <UIKit/UIKit.h>

@interface Meter : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIButton *icon;
@property (nonatomic, strong) UILabel *label;

- (instancetype)initWithName:(NSString *)name title:(NSString *)title;

@end
