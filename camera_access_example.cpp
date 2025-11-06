// 示例：如何在C++代码中访问相机数据
// 编译: g++ camera_access_example.cpp -o camera_test
// 运行: ./camera_test

#include <iostream>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/videodev2.h>
#include <cstring>

class CameraChecker {
public:
    // 检查video设备是否存在且可访问
    static bool checkVideoDevice(const char* device) {
        std::cout << "Checking device: " << device << std::endl;
        
        int fd = open(device, O_RDWR);
        if (fd < 0) {
            std::cerr << "❌ Cannot open " << device << ": " 
                      << strerror(errno) << std::endl;
            return false;
        }
        
        // 查询设备能力
        struct v4l2_capability cap;
        if (ioctl(fd, VIDIOC_QUERYCAP, &cap) < 0) {
            std::cerr << "❌ Cannot query device capabilities" << std::endl;
            close(fd);
            return false;
        }
        
        std::cout << "✅ Device opened successfully" << std::endl;
        std::cout << "   Driver: " << cap.driver << std::endl;
        std::cout << "   Card: " << cap.card << std::endl;
        std::cout << "   Bus: " << cap.bus_info << std::endl;
        std::cout << "   Capabilities: 0x" << std::hex << cap.capabilities << std::dec << std::endl;
        
        // 检查是否支持视频捕获
        if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE)) {
            std::cerr << "⚠️  Device does not support video capture" << std::endl;
            close(fd);
            return false;
        }
        
        std::cout << "✅ Device supports video capture" << std::endl;
        
        // 列出支持的格式
        listFormats(fd);
        
        close(fd);
        return true;
    }
    
    // 列出设备支持的视频格式
    static void listFormats(int fd) {
        std::cout << "\nSupported formats:" << std::endl;
        
        struct v4l2_fmtdesc fmt;
        memset(&fmt, 0, sizeof(fmt));
        fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        
        int i = 0;
        while (ioctl(fd, VIDIOC_ENUM_FMT, &fmt) >= 0) {
            std::cout << "  [" << i << "] " << fmt.description 
                      << " (fourcc: " << fourccToString(fmt.pixelformat) << ")" 
                      << std::endl;
            fmt.index++;
            i++;
        }
        
        if (i == 0) {
            std::cout << "  ⚠️  No formats reported" << std::endl;
        }
    }
    
    // 将fourcc代码转换为字符串
    static std::string fourccToString(uint32_t fourcc) {
        char buf[5];
        buf[0] = (fourcc >> 0) & 0xFF;
        buf[1] = (fourcc >> 8) & 0xFF;
        buf[2] = (fourcc >> 16) & 0xFF;
        buf[3] = (fourcc >> 24) & 0xFF;
        buf[4] = '\0';
        return std::string(buf);
    }
};

int main(int argc, char** argv) {
    std::cout << "========================================" << std::endl;
    std::cout << "Camera Access Test" << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << std::endl;
    
    // 检查常见的video设备
    const char* devices[] = {
        "/dev/video0",
        "/dev/video1",
        "/dev/video2",
        "/dev/video3",
        "/dev/video4",
        "/dev/video5"
    };
    
    bool foundAny = false;
    for (const char* dev : devices) {
        if (access(dev, F_OK) == 0) {
            foundAny = true;
            std::cout << "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" << std::endl;
            CameraChecker::checkVideoDevice(dev);
        }
    }
    
    std::cout << "\n========================================" << std::endl;
    if (!foundAny) {
        std::cout << "❌ No video devices found!" << std::endl;
        std::cout << "\nThis means:" << std::endl;
        std::cout << "  • Camera drivers may not be initialized" << std::endl;
        std::cout << "  • RN6854 chips need configuration" << std::endl;
        std::cout << "  • Run initialization scripts first" << std::endl;
        std::cout << "\nCheck:" << std::endl;
        std::cout << "  • Run: ls -l /dev/video*" << std::endl;
        std::cout << "  • Run: ./simple_camera_check.sh" << std::endl;
        return 1;
    } else {
        std::cout << "✅ Camera devices are accessible!" << std::endl;
        std::cout << "\nYou can now:" << std::endl;
        std::cout << "  • Use V4L2 API to capture frames" << std::endl;
        std::cout << "  • Use OpenCV: cv::VideoCapture" << std::endl;
        std::cout << "  • Use GStreamer pipelines" << std::endl;
    }
    std::cout << "========================================" << std::endl;
    
    return 0;
}

/* 
简单的采集示例（伪代码）：

int fd = open("/dev/video0", O_RDWR);

// 1. 设置格式
struct v4l2_format fmt;
fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
fmt.fmt.pix.width = 1920;
fmt.fmt.pix.height = 1080;
fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
ioctl(fd, VIDIOC_S_FMT, &fmt);

// 2. 请求缓冲区
struct v4l2_requestbuffers req;
req.count = 4;
req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
req.memory = V4L2_MEMORY_MMAP;
ioctl(fd, VIDIOC_REQBUFS, &req);

// 3. 映射缓冲区（省略详细代码）
// 4. 队列缓冲区
// 5. 开始采集
enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
ioctl(fd, VIDIOC_STREAMON, &type);

// 6. 读取帧
struct v4l2_buffer buf;
ioctl(fd, VIDIOC_DQBUF, &buf);  // 取出帧
// ... 处理数据 ...
ioctl(fd, VIDIOC_QBUF, &buf);   // 归还缓冲区

// 7. 停止采集
ioctl(fd, VIDIOC_STREAMOFF, &type);
close(fd);
*/
