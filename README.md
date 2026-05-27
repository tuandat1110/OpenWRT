# openwrt-python-check

Tiện ích kiểm tra phiên bản Python 3.9 viết bằng C, được đóng gói thành file `.ipk` cho OpenWRT chạy trên Raspberry Pi 4B (`aarch64_cortex-a72`). Toàn bộ môi trường build được containerize bằng Docker — không cần cài gì trên máy host ngoài Docker.

---

## Mục lục

- [Tổng quan](#tổng-quan)
- [Yêu cầu](#yêu-cầu)
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [Hướng dẫn làm project từng bước](#hướng-dẫn-làm-project-từng-bước)
- [Giải thích từng file & từng dòng code](#giải-thích-từng-file--từng-dòng-code)
- [Các lệnh Make](#các-lệnh-make)
- [Luồng hoạt động](#luồng-hoạt-động)
- [Output mẫu](#output-mẫu)
- [Thông tin phiên bản](#thông-tin-phiên-bản)

---

## Tổng quan

Chương trình `check_python` thực hiện 4 bước:

1. Kiểm tra `python3.9` có tồn tại trong `PATH` không
2. Lấy chuỗi version bằng `python3.9 --version`
3. In kết quả ra terminal
4. Ghi log vào `/tmp/python_ver.log`

Nếu không tìm thấy Python 3.9, chương trình thoát với **exit code khác 0** (chuẩn Unix — shell script có thể bắt được).

---

## Yêu cầu

| Công cụ | Phiên bản |
|---------|-----------|
| Docker | 20.10+ |
| GNU Make | bất kỳ |
| Git | bất kỳ |

> Không cần cài Python, GCC, hay OpenWRT SDK trực tiếp trên máy host. Tất cả đã có trong Docker image.

---

## Cấu trúc thư mục

```
openwrt-python-check/
├── Dockerfile            # Môi trường build: Ubuntu 22.04 + Python 3.9 + OpenWRT SDK
├── Makefile              # Host-level controller — điểm vào chính cho người dùng
├── README.md
├── openwrt/
│   └── Makefile          # OpenWRT package definition — hướng dẫn SDK đóng gói .ipk
└── src/
    ├── check_python.c    # Mã nguồn C — logic chính của ứng dụng
    └── Makefile          # Compile C code (dùng được cả local lẫn cross-compile)
```

| File | Vai trò |
|------|---------|
| `Makefile` (gốc) | Người dùng gõ lệnh ở đây — wrap toàn bộ `docker run` |
| `openwrt/Makefile` | Nói cho OpenWRT SDK biết cách cross-compile và đóng gói `.ipk` |
| `src/Makefile` | Thực sự compile code C (được gọi bởi 2 file trên) |
| `Dockerfile` | Định nghĩa môi trường build: Ubuntu + Python 3.9 + OpenWRT SDK |
| `src/check_python.c` | Logic ứng dụng: kiểm tra Python 3.9, in version, ghi log |

---

## Hướng dẫn làm project từng bước

Phần này mô tả **quá trình tư duy và thứ tự thực hiện** khi xây dựng project từ đầu — không phải chỉ là hướng dẫn chạy lệnh.

---

### Bước 1 — Khởi tạo Git repository

Việc đầu tiên là tạo repo và branch riêng cho tính năng, theo đúng Git Flow.

```bash
mkdir openwrt-python-check
cd openwrt-python-check
git init
git checkout -b feature/python-version-check
```

> **Tại sao tạo branch riêng?**
> Branch `feature/python-version-check` tách biệt code đang phát triển khỏi `main`. Khi xong mới merge — đây là quy trình chuẩn trong team.

---

### Bước 2 — Viết logic C (`src/check_python.c`)

Đây là trái tim của project. Viết file C trước vì tất cả các file còn lại (Makefile, Dockerfile) đều phục vụ việc compile và chạy file này.

```bash
mkdir src
touch src/check_python.c
```

Logic cần làm theo đặc tả:
- Phát hiện Python 3.9 trong PATH
- Đọc chuỗi version
- In ra terminal đúng format
- Ghi log vào `/tmp/python_ver.log`
- Thoát với exit code 1 nếu không tìm thấy Python

> **Tại sao viết bằng C thay vì shell script hay Python?**
> Đây là bài tập về cross-compilation và đóng gói `.ipk` cho OpenWRT — môi trường embedded. C phù hợp hơn vì: binary nhỏ, không cần runtime, chạy được trên mọi kiến trúc sau khi cross-compile.

---

### Bước 3 — Viết Makefile để compile C (`src/Makefile`)

Sau khi có code C, cần cách compile nó. `src/Makefile` phải hoạt động được trong 2 ngữ cảnh:
- **Local**: người dùng gọi trực tiếp → dùng `gcc`
- **Cross-compile**: OpenWRT SDK gọi → dùng `aarch64-gcc`

Giải pháp: không hardcode compiler, nhận `CC`/`CFLAGS`/`LDFLAGS` từ biến môi trường bên ngoài.

```bash
touch src/Makefile
```

---

### Bước 4 — Viết Dockerfile

Vấn đề lớn nhất của project: máy host (x86) không có sẵn OpenWRT SDK và Python 3.9 (Ubuntu 22.04 chỉ có Python 3.10). Giải pháp: đóng gói toàn bộ môi trường vào Docker.

Dockerfile phải làm 3 việc:
1. Thêm PPA deadsnakes → cài Python 3.9
2. Cài build tools + dependencies OpenWRT
3. Tải và giải nén OpenWRT SDK cho Raspberry Pi 4B

```bash
touch Dockerfile
```

---

### Bước 5 — Viết OpenWRT Package Definition (`openwrt/Makefile`)

Để OpenWRT SDK biết cách cross-compile và đóng gói code của mình thành file `.ipk` (định dạng package của OpenWRT), cần viết file "package definition" theo cú pháp macro đặc biệt của OpenWRT Build System.

```bash
mkdir openwrt
touch openwrt/Makefile
```

File này **không phải Makefile thông thường** — nó là file cấu hình dùng macro của OpenWRT, bao gồm: thông tin package, cách copy source, cách cross-compile, và cách cài vào rootfs.

---

### Bước 6 — Viết Makefile gốc (host controller)

Người dùng không nên phải nhớ lệnh `docker run` dài dòng mỗi khi dùng. Makefile gốc đóng vai trò **remote control**: wrap toàn bộ các lệnh docker vào các target ngắn gọn.

```bash
touch Makefile
```

Cần 5 target: `build-image`, `all` (compile), `run`, `package`, `clean`.

---

### Bước 7 — Build và test

```bash
# Build Docker image
make build-image

# Test compile
make

# Test chạy app
make run

# Đóng gói .ipk
make package
```

Kiểm tra output:
```
Detected Python Version: Python 3.9.19
```

Kiểm tra log:
```bash
# Log được ghi vào /tmp/python_ver.log bên trong container
# Để xem: chạy container và cat file đó
docker run --rm openwrt-dev:v1 cat /tmp/python_ver.log
```

---

### Bước 8 — Commit và tag

Dùng **Conventional Commits** để lịch sử Git có ý nghĩa và có thể sinh CHANGELOG tự động.

```bash
git add .
git commit -m "feat: implement check_python logic, multi-layer makefiles and docker integration"

# Tag phiên bản phát hành (annotated tag — có message)
git tag -a v1.0-python-check -m "Release finalized version 1.0 for evaluation"
```

> **Tại sao dùng annotated tag (`-a`) thay vì lightweight tag?**
> Annotated tag lưu thêm thông tin: tác giả, ngày giờ, message. Phù hợp để đánh dấu release. Lightweight tag chỉ là alias của commit, dùng cho bookmark tạm thời.

---

## Giải thích từng file & từng dòng code

---

### `src/check_python.c`

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
```

> Khai báo 3 thư viện chuẩn cần dùng:
> - `stdio.h` → `printf`, `fprintf`, `fopen`, `fgets`, `popen`
> - `stdlib.h` → `system()`
> - `string.h` → `strcspn()` (cắt newline)

---

```c
int check_exist = system("which python3.9 > /dev/null 2>&1");
```

> **`system()`** chạy lệnh shell và trả về exit code của lệnh đó.
> - `which python3.9` → tìm python3.9 trong PATH, trả về `0` nếu có, khác `0` nếu không có
> - `> /dev/null 2>&1` → bỏ toàn bộ output (stdout và stderr) vì ta chỉ cần biết có/không, không cần in ra màn hình
>
> **Tại sao dùng `system()` ở đây thay vì `popen()`?**
> Vì ta chỉ cần biết kết quả có/không (exit code). Dùng `popen()` ở đây sẽ thừa vì `popen()` mở một pipe để đọc text — mà ta không cần đọc gì cả.

---

```c
if (check_exist != 0) {
    fprintf(stderr, "Error: Python 3.9 not found\n");
    return 1;
}
```

> Nếu `which` trả về khác `0` → python3.9 không có trong PATH.
> - `fprintf(stderr, ...)` → in lỗi ra **stderr** (không phải stdout). Đây là chuẩn Unix: thông báo lỗi đi ra stderr, output bình thường đi ra stdout. Nhờ vậy khi dùng pipe (`./check_python | grep ...`) thì lỗi không bị lẫn vào output.
> - `return 1` → thoát với exit code `1` (non-zero = lỗi). Shell script có thể bắt được bằng `if ./check_python; then ... fi`

---

```c
FILE *fp = popen("python3.9 --version 2>&1", "r");
```

> **`popen()`** mở một pipe đến một lệnh shell để đọc output của nó.
> - `"r"` → mở để đọc (read). Ta cần đọc chuỗi "Python 3.9.19" mà lệnh in ra.
> - `2>&1` → redirect stderr vào stdout vì `python3.9 --version` in ra **stderr** trên một số phiên bản Python cũ (đây là quirk lịch sử của CPython).
>
> **Tại sao không dùng `system()` ở đây?**
> Vì cần đọc text output ("Python 3.9.19"). `system()` không cho phép đọc output — nó chỉ trả về exit code.

---

```c
if (fp == NULL) {
    fprintf(stderr, "Error: Failed to run python3.9 --version\n");
    return 1;
}
```

> `popen()` trả về `NULL` nếu không thể tạo pipe (lỗi hệ thống, không đủ bộ nhớ, v.v.). Phải check trước khi dùng — không check sẽ dẫn đến segfault khi đọc từ con trỏ NULL.

---

```c
char version_output[128];
if (fgets(version_output, sizeof(version_output), fp) == NULL) {
    fprintf(stderr, "Error: Failed to read python version output\n");
    pclose(fp);
    return 1;
}
pclose(fp);
```

> - `char version_output[128]` → buffer 128 byte để chứa chuỗi version. Chuỗi "Python 3.9.19\n" chỉ khoảng 16 ký tự, nên 128 là đủ an toàn.
> - `fgets()` đọc 1 dòng từ pipe vào buffer. Trả về `NULL` nếu không đọc được gì.
> - `pclose(fp)` **phải** được gọi để đóng pipe và thu hồi process con — kể cả khi có lỗi. Không đóng → resource leak (zombie process).

---

```c
version_output[strcspn(version_output, "\n")] = 0;
```

> `fgets()` giữ lại ký tự `\n` ở cuối chuỗi. Dòng này cắt bỏ nó.
>
> **Cách hoạt động:** `strcspn(s, "\n")` trả về index của ký tự `\n` đầu tiên trong chuỗi. Gán `= 0` tại vị trí đó → kết thúc chuỗi tại đó (null terminator). Kết quả: "Python 3.9.19\n" → "Python 3.9.19"

---

```c
printf("Detected Python Version: %s\n", version_output);
```

> In ra **stdout** theo đúng format yêu cầu của đặc tả.

---

```c
FILE *log_file = fopen("/tmp/python_ver.log", "w");
if (log_file != NULL) {
    fprintf(log_file, "%s\n", version_output);
    fclose(log_file);
} else {
    fprintf(stderr, "Warning: Could not write to /tmp/python_ver.log\n");
}
return 0;
```

> - `fopen(..., "w")` → mở file để ghi (tạo mới nếu chưa có, ghi đè nếu đã có).
> - Nếu không ghi được (quyền truy cập, disk full): chỉ in **Warning** ra stderr chứ không `return 1`. Lý do: đây là tính năng phụ — không nên fail cả chương trình chỉ vì không ghi được log.
> - `fclose(log_file)` → đóng file để flush buffer xuống disk. Không đóng → dữ liệu có thể bị mất.
> - `return 0` → thành công.

---

### `src/Makefile`

```makefile
TARGET = check_python
OBJS = check_python.o
```

> Khai báo tên binary output và danh sách object files. Tách ra biến để dễ thay đổi sau.

---

```makefile
$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) -o $(TARGET)
```

> **Bước link:** ghép các `.o` files thành binary thực thi.
> - `$(CC)` → compiler (gcc hoặc aarch64-gcc tùy ai gọi)
> - `$(LDFLAGS)` → linker flags (đường dẫn thư viện, v.v.)
> - `-o $(TARGET)` → tên file output

---

```makefile
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
```

> **Bước compile:** chuyển file `.c` thành file `.o` (object file).
> - `%.o: %.c` → pattern rule: bất kỳ `.c` nào → `.o` tương ứng
> - `-c` → chỉ compile, không link
> - `$<` → file source đầu vào (file `.c`)
> - `$@` → file output (file `.o`)
>
> **Tại sao tách compile và link thành 2 bước?**
> Với project lớn có nhiều file `.c`, tách ra giúp Make chỉ compile lại những file đã thay đổi — không cần compile lại toàn bộ.

---

### `openwrt/Makefile`

```makefile
include $(TOPDIR)/rules.mk
```

> Load biến toàn cục của OpenWRT SDK (đường dẫn toolchain, staging dir, v.v.). `TOPDIR` được set bởi SDK khi build.

---

```makefile
PKG_NAME := check_python
PKG_VERSION := 1.0
PKG_RELEASE := 1
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)
```

> Metadata của package:
> - `PKG_NAME` → tên package trong opkg
> - `PKG_VERSION` + `PKG_RELEASE` → tạo thành tên file `.ipk`: `check_python_1.0-1_aarch64.ipk`
> - `PKG_BUILD_DIR` → thư mục tạm để SDK compile (tách biệt với source gốc)

---

```makefile
define Package/check_python
  SECTION := utils
  CATEGORY := Utilities
  TITLE := Check Python 3.9 Version Utility
  DEPENDS := +python3-light
endef
```

> Thông tin hiển thị trong `opkg list`. `DEPENDS := +python3-light` → khi cài package này, opkg sẽ tự động cài `python3-light` nếu chưa có.

---

```makefile
define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(CURDIR)/src/* $(PKG_BUILD_DIR)/
endef
```

> Copy source vào thư mục build tạm. SDK compile ở đó chứ không đụng vào source gốc — tránh làm bẩn working directory.

---

```makefile
define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef
```

> Gọi `src/Makefile` với cross-compiler của SDK:
> - `TARGET_CC` = `aarch64-openwrt-linux-musl-gcc` → compile cho Raspberry Pi 4B, không phải cho máy host
> - `TARGET_CFLAGS` → tối ưu size (`-Os`), chỉ định kiến trúc ARM (`-march=armv8-a+crc`)
> - `TARGET_LDFLAGS` → đường dẫn thư viện musl của SDK

---

```makefile
define Package/check_python/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/check_python $(1)/usr/bin/
endef
```

> Đặt binary vào đúng vị trí trong rootfs. `$(1)` là thư mục root của package image. Khi người dùng chạy `opkg install check_python.ipk` trên router, file sẽ được giải nén vào `/usr/bin/check_python`.

---

```makefile
$(eval $(call BuildPackage,check_python))
```

> Dòng cuối bắt buộc — gọi macro `BuildPackage` của OpenWRT để đăng ký package với Build System. Không có dòng này, SDK sẽ không biết package này tồn tại.

---

### `Dockerfile`

```dockerfile
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
```

> - Base image Ubuntu 22.04 LTS — stable, được OpenWRT SDK hỗ trợ tốt.
> - `DEBIAN_FRONTEND=noninteractive` → tắt các prompt tương tác khi cài apt (như hỏi timezone). Cần thiết khi build Docker vì không có terminal.

---

```dockerfile
RUN apt-get update && apt-get install -y \
    software-properties-common gnupg2 curl \
    && add-apt-repository ppa:deadsnakes/ppa -y
```

> **Tại sao cần PPA deadsnakes?**
> Ubuntu 22.04 LTS chỉ ship Python 3.10 mặc định. Python 3.9 đã EOL nên không còn trong repo chính thức của Ubuntu. PPA `deadsnakes` là nguồn uy tín cung cấp nhiều phiên bản Python (cũ và mới) ngoài repo chính thức.
>
> Không có bước này → `apt install python3.9` sẽ báo `Package not found`.

---

```dockerfile
RUN apt-get update && apt-get install -y \
    build-essential ccache ecj fastjar file g++ gawk gettext \
    git libelf-dev libncurses5-dev libncursesw5-dev \
    libssl-dev python3.9 python3.9-dev python3.9-distutils \
    subversion unzip zlib1g-dev wget rsync sudo \
    && apt-get clean
```

> Hai nhóm package:
> - **Build tools** (`build-essential`, `g++`, `gawk`, v.v.) → cần để compile OpenWRT SDK và code C
> - **Python 3.9 và dev headers** → cần để chạy app và để SDK link thư viện Python nếu cần
>
> `apt-get clean` → xóa cache apt để giảm size Docker image.

---

```dockerfile
WORKDIR /opt
RUN wget https://archive.openwrt.org/releases/23.05.2/targets/bcm27xx/bcm2711/\
    openwrt-sdk-23.05.2-bcm27xx-bcm2711_gcc-12.3.0_musl.Linux-x86_64.tar.xz \
    && tar -xf openwrt-sdk-*.tar.xz \
    && mv openwrt-sdk-*/ openwrt-sdk \
    && rm -f openwrt-sdk-*.tar.xz
```

> Tải OpenWRT SDK cho target `bcm27xx/bcm2711` (Raspberry Pi 4B).
>
> **Tại sao dùng `archive.openwrt.org` thay vì `downloads.openwrt.org`?**
> `downloads.openwrt.org` chỉ giữ các bản **mới nhất**. Bản 23.05.2 đã cũ hơn và đã được chuyển sang `archive.openwrt.org` — kho lưu trữ dài hạn. Nếu dùng `downloads.openwrt.org` sẽ báo 404.
>
> `rm -f openwrt-sdk-*.tar.xz` → xóa file nén sau khi giải nén để giảm size image (file này ~500MB).

---

```dockerfile
WORKDIR /workspace/openwrt-python-check
COPY . .
RUN make -C src/
CMD ["/bin/bash"]
```

> - `COPY . .` → copy toàn bộ project vào image tại thời điểm build
> - `RUN make -C src/` → compile binary ngay khi build image để kiểm tra môi trường hoạt động
> - `CMD ["/bin/bash"]` → khi `docker run` không có lệnh cụ thể thì vào bash shell (tiện debug)

---

### `Makefile` (gốc)

```makefile
IMAGE_NAME = openwrt-dev:v1
CONTAINER_WS = /workspace/openwrt-python-check
SDK_PATH = /opt/openwrt-sdk
PKG_NAME = check_python
ARCH = aarch64_cortex-a72
```

> Khai báo các hằng số dùng chung. Để tên image, path, arch ở đây thay vì hardcode trong từng target → dễ thay đổi sau.

---

```makefile
all:
	docker run --rm \
		-v $(PWD):$(CONTAINER_WS) \
		-w $(CONTAINER_WS)/src \
		$(IMAGE_NAME) \
		make
```

> - `--rm` → xóa container sau khi chạy xong. Không có flag này → container chết nhưng vẫn tồn tại, chiếm disk.
> - `-v $(PWD):$(CONTAINER_WS)` → mount thư mục project hiện tại vào container. Nhờ đó binary được compile nằm trong thư mục của máy host, không mất khi container xóa.
> - `-w $(CONTAINER_WS)/src` → working directory bên trong container là `src/`
> - `make` (cuối) → lệnh chạy trong container → gọi `src/Makefile`

---

```makefile
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
		cp bin/packages/$(ARCH)/base/$(PKG_NAME)*.ipk $(CONTAINER_WS)/"
```

> Đây là target phức tạp nhất — thực hiện 5 việc liên tiếp trong 1 shell session:
> 1. Tạo thư mục package trong SDK
> 2. Copy source và Makefile vào đúng vị trí SDK yêu cầu
> 3. `make defconfig` → generate `.config` mặc định cho SDK
> 4. `make package/check_python/compile V=s` → cross-compile và đóng gói `.ipk` (`V=s` = verbose, in ra toàn bộ lệnh để debug)
> 5. Copy file `.ipk` về thư mục project trên host (qua volume mount)

---

## Các lệnh Make

| Lệnh | Mô tả |
|------|-------|
| `make build-image` | Build Docker image `openwrt-dev:v1` |
| `make` | Compile `check_python` binary bên trong container |
| `make run` | Chạy app trong container, in version + ghi log |
| `make package` | Cross-compile + đóng gói thành file `.ipk` cho aarch64 |
| `make clean` | Xóa object files, binary, và file `.ipk` |

---

## Luồng hoạt động

```
HOST MACHINE
│
├─ make build-image
│   └─► docker build → openwrt-dev:v1
│           ├─ cài Python 3.9 (PPA deadsnakes)
│           ├─ cài build tools
│           └─ tải OpenWRT SDK bcm27xx/bcm2711
│
├─ make  (compile)
│   └─► docker run → src/Makefile → check_python  [gcc local]
│
├─ make run  (test)
│   └─► docker run → ./src/check_python
│           OUTPUT : "Detected Python Version: Python 3.9.19"
│           LOG    : /tmp/python_ver.log
│
└─ make package  (cross-compile + đóng gói)
    └─► docker run
            ├─ copy src/ + openwrt/Makefile → SDK
            ├─ make defconfig
            ├─ make package/check_python/compile
            │   └─ TARGET_CC = aarch64-openwrt-linux-musl-gcc
            └─► check_python_1.0-1_aarch64_cortex-a72.ipk
```

---

## Output mẫu

**Terminal (`make run`):**
```
Detected Python Version: Python 3.9.19
```

**Log file (`/tmp/python_ver.log`):**
```
Python 3.9.19
```

**Khi không tìm thấy Python 3.9:**
```
Error: Python 3.9 not found
```
Exit code: `1`

---

## Thông tin phiên bản

| Yếu tố | Giá trị |
|--------|---------|
| Git Branch | `feature/python-version-check` |
| Git Tag | `v1.0-python-check` |
| Docker Image | `openwrt-dev:v1` (Ubuntu 22.04) |
| OpenWRT SDK | `v23.05.2` — `bcm27xx/bcm2711` |
| Target Platform | Raspberry Pi 4B (`aarch64_cortex-a72`) |
| Commit format | Conventional Commits: `feat:` / `fix:` / `docs:` |

---

## Link github
https://github.com/tuandat1110/OpenWRT.git
