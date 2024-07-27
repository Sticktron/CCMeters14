//
//  CCMeters14ViewController.h
//  CCMeters14
//
//  Copyright © 2024 Sticktron. All rights reserved.
//

#import <UIKit/UIViewController.h>
#import "Headers/CCUIContentModuleContentViewController-Protocol.h"

@interface CCMeters14ViewController : UIViewController <CCUIContentModuleContentViewController>

//these are the dimensions of the module once its expanded
@property (nonatomic, readonly) CGFloat preferredExpandedContentHeight;
@property (nonatomic, readonly) CGFloat preferredExpandedContentWidth;
@property (nonatomic, readonly) BOOL providesOwnPlatter;
@property (nonatomic, readonly) BOOL expanded;
@property (nonatomic, readonly) BOOL small;

//- (instancetype)initWithSmallSize:(BOOL)small;
@end
