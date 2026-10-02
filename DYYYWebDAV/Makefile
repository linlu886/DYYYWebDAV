ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = Aweme

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DYYYWebDAV
DYYYWebDAV_FILES = DYYYWebDAV.xm Sources/DYConfig.m Sources/DYResolver.m Sources/DYWebDAV.m Sources/DYTransfer.m Sources/DYSettings.m
DYYYWebDAV_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
DYYYWebDAV_FRAMEWORKS = UIKit Foundation Security
DYYYWebDAV_LOGOS_DEFAULT_GENERATOR = internal

include $(THEOS_MAKE_PATH)/tweak.mk

ifeq ($(SCHEME),rootless)
THEOS_PACKAGE_SCHEME = rootless
endif
