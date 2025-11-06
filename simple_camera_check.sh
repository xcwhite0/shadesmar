#!/bin/bash

# 简单的相机状态检查脚本

echo "🎥 Quick Camera Status Check"
echo "=============================="
echo ""

# 定义颜色
G='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; NC='\033[0m'

# 1. 检查I2C设备
echo "1️⃣  I2C Chips:"
i2c_4=$(i2ctransfer -y 4 w1@0x2c 0x00 r1 2>/dev/null)
i2c_3=$(i2ctransfer -y 3 w1@0x2c 0x00 r1 2>/dev/null)

if [ -n "$i2c_4" ]; then
    echo -e "   ${G}✅${NC} i2c-4 (4路AHD): Chip ID $i2c_4"
else
    echo -e "   ${R}❌${NC} i2c-4 (4路AHD): Not detected"
fi

if [ -n "$i2c_3" ]; then
    echo -e "   ${G}✅${NC} i2c-3 (2路AHD): Chip ID $i2c_3"
else
    echo -e "   ${R}❌${NC} i2c-3 (2路AHD): Not detected"
fi
echo ""

# 2. 检查video设备（这是代码能否获取相机数据的关键）
echo "2️⃣  Video Devices (代码访问接口):"
video_count=$(ls /dev/video* 2>/dev/null | wc -l)
if [ $video_count -gt 0 ]; then
    echo -e "   ${G}✅${NC} Found $video_count video device(s):"
    ls /dev/video* | sed 's/^/      /'
    echo ""
    echo -e "   ${G}👉 代码可以访问相机！${NC}"
    echo "   示例代码："
    echo "      fd = open(\"/dev/video0\", O_RDWR);"
else
    echo -e "   ${R}❌${NC} No /dev/video* devices"
    echo -e "   ${R}👉 代码暂时无法访问相机！${NC}"
fi
echo ""

# 3. 检查驱动
echo "3️⃣  Kernel Drivers:"
driver_count=$(lsmod | grep -cE "hobot_mipi|hobot_cam")
if [ $driver_count -gt 0 ]; then
    echo -e "   ${G}✅${NC} Camera drivers loaded ($driver_count)"
else
    echo -e "   ${R}❌${NC} Camera drivers not loaded"
fi
echo ""

# 4. 关键判断
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 总结："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $video_count -gt 0 ]; then
    echo -e "${G}✅ 相机系统就绪，代码可以获取数据${NC}"
    echo ""
    echo "访问方法："
    echo "  • C/C++: open(\"/dev/videoX\"), ioctl(), read()"
    echo "  • Python: cv2.VideoCapture(X) 或 v4l2"
    echo "  • 命令行: v4l2-ctl, ffmpeg"
else
    echo -e "${R}❌ 相机系统未就绪，需要初始化${NC}"
    echo ""
    echo "缺少的步骤："
    echo "  1. RN6854芯片需要配置（通过I2C写寄存器）"
    echo "  2. 系统需要创建video设备节点"
    echo "  3. 可能需要运行厂商提供的初始化脚本"
    echo ""
    echo "检查："
    echo "  • 是否有 'camera_init.sh' 类似的脚本？"
    echo "  • 查看文档中的初始化步骤"
    echo "  • 运行: dmesg | tail -50"
fi
echo ""

# 5. 关于判断哪个AHD相机连接
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔌 判断单个AHD相机是否连接："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  仅检测到I2C芯片不够，需要："
echo ""
echo "方法1: 读取RN6854的视频检测寄存器"
echo "  • 需要RN6854数据手册"
echo "  • 读取特定寄存器位判断各通道视频输入"
echo ""
echo "方法2: 在video设备创建后，检查各通道"
echo "  • 使用 v4l2-ctl 查询信号状态"
echo "  • 尝试采集，看是否有有效帧"
echo ""
echo "方法3: 物理检查"
echo "  • 相机通电后LED是否亮"
echo "  • BNC/航空插头是否连接紧密"
echo ""
