# Sử dụng Ubuntu làm nền tảng build ổn định
FROM ubuntu:22.04

# Tránh các câu hỏi tương tác khi install packages
ENV DEBIAN_FRONTEND=noninteractive

# 1. Cài đặt các công cụ cơ bản và thêm kho PPA cho Python 3.9
RUN apt-get update && apt-get install -y \
    software-properties-common gnupg2 curl \
    && add-apt-repository ppa:deadsnakes/ppa -y

# 2. Cài đặt các công cụ thiết yếu cho OpenWRT SDK và Python 3.9
RUN apt-get update && apt-get install -y \
    build-essential ccache ecj fastjar file g++ gawk gettext \
    git libelf-dev libncurses5-dev libncursesw5-dev \
    libssl-dev python3.9 python3.9-dev python3.9-distutils python3-distutils \
    subversion unzip zlib1g-dev wget rsync sudo \
    && apt-get clean

# 3. Tải OpenWRT SDK cho Raspberry Pi 4B (Link chuẩn v23.05.2)
WORKDIR /opt
RUN wget https://archive.openwrt.org/releases/23.05.2/targets/bcm27xx/bcm2711/openwrt-sdk-23.05.2-bcm27xx-bcm2711_gcc-12.3.0_musl.Linux-x86_64.tar.xz \
    && tar -xf openwrt-sdk-*.tar.xz \
    && mv openwrt-sdk-23.05.2-bcm27xx-bcm2711_gcc-12.3.0_musl.Linux-x86_64 openwrt-sdk \
    && rm -f openwrt-sdk-*.tar.xz

# Thiết lập thư mục làm việc cho project
WORKDIR /workspace/openwrt-python-check
COPY . .

# Biên dịch thử một bản local để chạy test trực tiếp trong môi trường container
RUN make -C src/

CMD ["/bin/bash"]