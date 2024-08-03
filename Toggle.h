//
//  Toggle.h
//  CCMeters14
//
//  Copyright © 2024 Sticktron. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Toggle : UIView

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UILabel *label;

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image;

@end
