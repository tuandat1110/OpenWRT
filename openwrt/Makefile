include $(TOPDIR)/rules.mk

PKG_NAME:=check_python
PKG_RELEASE:=1
PKG_VERSION:=1.0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/check_python
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Check Python 3.9 Version Utility
  DEPENDS:=+python3-light
endef

define Package/check_python/description
  A simple C application to check and log installed Python 3.9 version.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(CURDIR)/src/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/check_python/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/check_python $(1)/usr/bin/
endef

$(eval $(call BuildPackage,check_python))