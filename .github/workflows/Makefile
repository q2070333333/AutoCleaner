TARGET := iphone:clang:latest:16.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AutoCleaner

AutoCleaner_FILES = Tweak.x
AutoCleaner_CFLAGS = -fobjc-arc
AutoCleaner_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
