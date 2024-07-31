//
//  Toggle.m
//  CCMeters14
//
//  Copyright © 2024 Sticktron. All rights reserved.
//

#import "Toggle.h"

#define SIZE 60
#define BUTTON_HEIGHT 48
#define LABEL_HEIGHT 10


@interface Toggle ()
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *title;
@end

@implementation Toggle

- (instancetype)initWithImage:(UIImage *)image title:(NSString *)title {
	if (self = [super initWithFrame:CGRectMake(0, 0, SIZE, SIZE)]) {
		_image = image;
		_title = title;
		[self setup];
	}
	return self;
} 

- (void)setup {
	
	// Button...
	
	_button = [UIButton buttonWithType:UIButtonTypeCustom];
	_button.frame = CGRectMake((SIZE - BUTTON_HEIGHT) / 2, 0, BUTTON_HEIGHT, BUTTON_HEIGHT);
	_button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
	_button.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
	_button.tintColor = UIColor.whiteColor;
	_button.layer.compositingFilter = @"linearDodgeBlendMode";
	_button.alpha = 0.5;
	_image = [_image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[_button setImage:_image forState:UIControlStateNormal];	
	[self addSubview:_button];
	
	// Label ...
	
	_label = [[UILabel alloc] init];
	_label.frame = CGRectMake(0, SIZE - LABEL_HEIGHT, SIZE, LABEL_HEIGHT);
	_label.font = [UIFont systemFontOfSize:9 weight:UIFontWeightSemibold];
	_label.textAlignment = NSTextAlignmentCenter;
	_label.textColor = UIColor.whiteColor;
	_label.layer.compositingFilter = @"linearDodgeBlendMode";
	_label.alpha = 0.5;
	_label.text = _title;
	[self addSubview:_label];
}

@end
