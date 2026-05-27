#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main() {
    // 1. Kiểm tra python3.9 có tồn tại không bằng lệnh 'which'
    int check_exist = system("which python3.9 > /dev/null 2>&1");
    if (check_exist != 0) {
        fprintf(stderr, "Error: Python 3.9 not found\n");
        return 1; // Thoát với mã lỗi non-zero
    }

    // 2. Chạy lệnh để lấy phiên bản và đọc output qua popen
    FILE *fp = popen("python3.9 --version 2>&1", "r");
    if (fp == NULL) {
        fprintf(stderr, "Error: Failed to run python3.9 --version\n");
        return 1;
    }

    char version_output[128];
    if (fgets(version_output, sizeof(version_output), fp) == NULL) {
        fprintf(stderr, "Error: Failed to read python version output\n");
        pclose(fp);
        return 1;
    }
    pclose(fp);

    // Xóa ký tự xuống dòng ở cuối nếu có
    version_output[strcspn(version_output, "\n")] = 0;

    // 3. In ra terminal theo đúng format yêu cầu: "Detected Python Version: 3.9.x"
    printf("Detected Python Version: %s\n", version_output);

    // 4. Ghi log vào /tmp/python_ver.log
    FILE *log_file = fopen("/tmp/python_ver.log", "w");
    if (log_file != NULL) {
        fprintf(log_file, "%s\n", version_output);
        fclose(log_file);
    } else {
        fprintf(stderr, "Warning: Could not write to /tmp/python_ver.log\n");
    }

    return 0;
}