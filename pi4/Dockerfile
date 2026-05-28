# 1. Sử dụng Alpine Linux chuẩn kiến trúc ARM64
FROM --platform=linux/arm64 alpine:latest

# 2. Tạo thư mục tạm bên trong container
WORKDIR /tmp

# 3. Copy file .ipk từ máy thật vào
COPY check_python_1.0-1_aarch64_cortex-a72.ipk /tmp/

# 4. Chạy các lệnh cài đặt môi trường và bung gói phần mềm
RUN tar -xvf check_python_1.0-1_aarch64_cortex-a72.ipk && \
    tar -xvf data.tar.gz && \
    cp ./usr/bin/check_python /usr/bin/ && \
    apk update && apk add python3 && \
    ln -sf /usr/bin/python3 /usr/bin/python3.9

# 5. Thay đổi CMD thành /bin/sh để giữ tương tác
CMD ["/bin/sh"]