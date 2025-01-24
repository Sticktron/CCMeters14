//
//  Toggle.m
//  CCMeters14
//
//  Copyright © Sticktron. All rights reserved.
//

#import "Toggle.h"

#define SIZE 60
#define BUTTON_HEIGHT 48
#define LABEL_HEIGHT 10


@implementation Toggle

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image {
	if (self = [super initWithFrame:CGRectMake(0, 0, SIZE, SIZE)]) {
		
		// Need this for the layer effect composition to work !!!
	    [self.layer setValue:@(NO) forKey:@"allowsGroupBlending"];
		
		_title = title;
		_image = image;
		
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
	_image = [_image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[_button setImage:_image forState:UIControlStateNormal];	
	_button.tintColor = UIColor.whiteColor;
	_button.layer.compositingFilter = @"linearDodgeBlendMode";
	_button.alpha = 0.4;
	[self addSubview:_button];
	
	// Label ...
	
	_label = [[UILabel alloc] init];
	_label.frame = CGRectMake(0, SIZE - LABEL_HEIGHT, SIZE, LABEL_HEIGHT);
	_label.font = [UIFont systemFontOfSize:9 weight:UIFontWeightSemibold];
	_label.textAlignment = NSTextAlignmentCenter;
	_label.textColor = UIColor.whiteColor;
	_label.layer.compositingFilter = @"linearDodgeBlendMode";
	_label.alpha = 0.4;
	_label.text = _title;
	[self addSubview:_label];
}

@end
