TARGET = iphone:clang::11.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Pokebox

Pokebox_FILES = $(wildcard *.m) $(wildcard SkittyPrefs/*.m)
Pokebox_INSTALL_PATH = /Library/PreferenceBundles
Pokebox_FRAMEWORKS = UIKit
Pokebox_PRIVATE_FRAMEWORKS = Preferences
Pokebox_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Tofu.plist$(ECHO_END)
