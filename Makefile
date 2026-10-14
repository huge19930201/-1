# SDK 用 16.5，最低部署 iOS 15（多巴胺最低要求）
TARGET := iphone:clang:16.5:15.0
ARCHS := arm64e

# rootless：所有文件装到 /var/jb（多巴胺越狱）
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WXKBToolbarTweak
WXKBToolbarTweak_FILES = Tweak.x
WXKBToolbarTweak_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
