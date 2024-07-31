//
//  Toggle.h
//  CCMeters14
//
//  Copyright © 2024 Sticktron. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Toggle : UIView
@property (nonatomic, strong) UIButton *button;
- (instancetype)initWithImage:(UIImage *)image title:(NSString *)title;
@end
