//
//  CCMeters14Module.h
//  CCMeters14
//
//  Copyright © 2024 Sticktron. All rights reserved.
//

#import <ControlCenterUIKit/CCUIContentModule.h>
#import "CCMeters14ViewController.h"

@interface CCMeters14Module : NSObject <CCUIContentModule>

//This is what controls the view for the default UIElements that will appear before the module is expanded
@property (nonatomic, readonly) CCMeters14ViewController* contentViewController;
//This is what will control how the module changes when it is expanded
@property (nonatomic, readonly) UIViewController* backgroundViewController;

@end
