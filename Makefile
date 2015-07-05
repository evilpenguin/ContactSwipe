export THEOS_DEVICE_IP = localhost
export THEOS_DEVICE_PORT = 2222
export ARCHS = armv7 arm64
export SDKVERSION = 7.1
export TARGET = iphone:8.3:4.3
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ContactSwipe
ContactSwipe_FILES = Tweak.xm
ContactSwipe_FRAMEWORKS	 = UIKit AddressBook CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
