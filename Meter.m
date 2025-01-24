//
//  Meter.m
//  CCMeters14
//
//  Copyright © Sticktron. All rights reserved.
//

#import "Meter.h"

@interface UIImage (CCMeters14)
+ (id)imageNamed:(id)name inBundle:(id)bundle;
@end


@implementation Meter

- (instancetype)initWithName:(NSString *)name title:(NSString *)title {
    if (self = [super init]) {
        _name = name;
        _title = title;
		
		[self setup];
    }
    return self;
}

- (void)setup {
	
	// create icon...
    _icon = [[UIButton alloc] init];
	_icon.userInteractionEnabled = NO;
    NSBundle *bundle = [NSBundle bundleWithPath:@"/Library/ControlCenter/Bundles/CCMeters14.bundle"];
    UIImage *iconImage = [UIImage imageNamed:_name inBundle:bundle];
	iconImage = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[_icon setImage:iconImage forState:UIControlStateNormal];
    _icon.tintColor = UIColor.whiteColor;
    _icon.layer.compositingFilter = @"linearDodgeBlendMode";
    _icon.alpha = 0.5;
            
    // test border
    // _icon.layer.borderWidth = 1;
    // _icon.layer.borderColor = UIColor.greenColor.CGColor;
    
	
	// create label...
    _label = [[UILabel alloc] init];
    _label.font = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
	_label.textAlignment = NSTextAlignmentCenter;
    _label.textColor = UIColor.whiteColor;
	_label.text = _title;
	
    // test border
    // label.layer.borderWidth = 1;
    // label.layer.borderColor = UIColor.greenColor.CGColor;
}

@end
