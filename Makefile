IMAGE_NAME   = openwrt-dev:v1
CONTAINER_WS = /workspace/openwrt-python-check
SDK_PATH     = /opt/openwrt-sdk
PKG_NAME     = check_python
ARCH         = aarch64_cortex-a72

# ─── Target 1: Compile local binary trong container ──────────
all:
	docker run --rm \
		-v $(PWD):$(CONTAINER_WS) \
		-w $(CONTAINER_WS)/src \
		$(IMAGE_NAME) \
		make

# ─── Target 2: Chạy app trong container ──────────────────────
run:
	docker run --rm \
		-v $(PWD):$(CONTAINER_WS) \
		-w $(CONTAINER_WS) \
		$(IMAGE_NAME) \
		./src/check_python

# ─── Target 3: Cross-compile + đóng gói .ipk ─────────────────
package:
	docker run --rm \
		-v $(PWD):$(CONTAINER_WS) \
		$(IMAGE_NAME) /bin/bash -c "\
			mkdir -p $(SDK_PATH)/package/$(PKG_NAME) && \
			cp -r $(CONTAINER_WS)/src $(SDK_PATH)/package/$(PKG_NAME)/src && \
			cp $(CONTAINER_WS)/openwrt/Makefile $(SDK_PATH)/package/$(PKG_NAME)/Makefile && \
			cd $(SDK_PATH) && \
			make defconfig && \
			make package/$(PKG_NAME)/compile V=s && \
			cp bin/packages/$(ARCH)/base/$(PKG_NAME)*.ipk \
			   $(CONTAINER_WS)/"

# ─── Build Docker image ───────────────────────────────────────
build-image:
	docker build -t $(IMAGE_NAME) .

# ─── Clean ───────────────────────────────────────────────────
clean:
	docker run --rm \
		-v $(PWD):$(CONTAINER_WS) \
		-w $(CONTAINER_WS)/src \
		$(IMAGE_NAME) \
		make clean
	rm -f *.ipk

.PHONY: build-image all run package clean