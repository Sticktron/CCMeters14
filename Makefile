ARCHS = arm64 arm64e
TARGET := iphone:clang:14.5:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = CCMeters14
CCMeters14_BUNDLE_EXTENSION = bundle
CCMeters14_FILES = CCMeters14Module.m CCMeters14ViewController.m Meter.m Toggle.m
CCMeters14_CFLAGS = -fobjc-arc
CCMeters14_FRAMEWORKS = UIKit
CCMeters14_PRIVATE_FRAMEWORKS = ControlCenterUIKit FrontBoardServices
CCMeters14_INSTALL_PATH = /Library/ControlCenter/Bundles

include $(THEOS_MAKE_PATH)/bundle.mk
