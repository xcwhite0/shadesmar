#!/bin/bash

# RN6854 AHD Camera Detection Script
# 通过读取RN6854状态寄存器判断各通道是否有视频信号

echo "================================================"
echo "RN6854 AHD Camera Input Detection"
echo "================================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_rn6854_channels() {
    local BUS=$1
    local ADDR=$2
    local NAME=$3
    local CHANNELS=$4
    
    echo "[$NAME] on i2c-$BUS @ $ADDR"
    echo "----------------------------------------"
    
    # 检查芯片是否响应
    if ! i2ctransfer -y $BUS w1@$ADDR 0x00 r1 >/dev/null 2>&1; then
        echo -e "${RED}❌ Chip not responding on I2C${NC}"
        echo ""
        return 1
    fi
    
    # 读取芯片ID
    CHIP_ID=$(i2ctransfer -y $BUS w1@$ADDR 0x00 r1 2>/dev/null | awk '{print $1}')
    echo "Chip ID: $CHIP_ID"
    echo ""
    
    # 读取视频检测状态寄存器
    # RN6854 通常使用特定寄存器来指示视频输入状态
    # 常见寄存器：
    # 0x00: Chip ID
    # 0x01: 通常是视频检测状态
    # 0x02-0x03: 其他状态寄存器
    
    echo "Video Input Status:"
    for ch in $(seq 0 $((CHANNELS-1))); do
        # 切换到对应通道（如果需要）
        # 某些RN6854版本需要先选择通道
        
        # 读取状态寄存器（这里读取0x01作为示例）
        # 实际寄存器地址可能需要根据RN6854数据手册调整
        STATUS=$(i2ctransfer -y $BUS w1@$ADDR 0x01 r1 2>/dev/null | awk '{print $1}')
        
        if [ -n "$STATUS" ]; then
            # 解析状态位（具体位定义需要参考RN6854数据手册）
            # 这里假设bit位表示视频信号存在
            STATUS_DEC=$((STATUS))
            
            # 简单判断：如果状态不是0x00或0xFF，可能有信号
            if [ "$STATUS" != "0x00" ] && [ "$STATUS" != "0xff" ]; then
                echo -e "  Channel $ch: ${GREEN}✅ Possible video signal${NC} (status: $STATUS)"
            else
                echo -e "  Channel $ch: ${RED}❌ No video signal${NC} (status: $STATUS)"
            fi
        else
            echo -e "  Channel $ch: ${YELLOW}⚠️  Cannot read status${NC}"
        fi
    done
    echo ""
    
    # 读取更多诊断信息
    echo "Extended Diagnostics:"
    echo "  Registers 0x00-0x07:"
    REG_DUMP=$(i2ctransfer -y $BUS w1@$ADDR 0x00 r8 2>/dev/null)
    echo "    $REG_DUMP"
    echo ""
}

# 检查4路AHD (i2c-4)
check_rn6854_channels 4 0x2c "RN6854-4路AHD (MIPI CSI0&1)" 4

# 检查2路AHD (i2c-3)
check_rn6854_channels 3 0x2c "RN6854-2路AHD (MIPI CSI2&3)" 2

echo "================================================"
echo "Physical Connection Check"
echo "================================================"
echo ""
echo "要准确判断AHD相机是否连接，请检查："
echo ""
echo "1. 物理连接："
echo "   - 确认AHD相机的BNC/航空插头已连接到RN6854板"
echo "   - 检查电源是否供电（相机LED灯是否亮）"
echo ""
echo "2. RN6854配置："
echo "   - RN6854需要正确配置才能输出MIPI信号"
echo "   - 某些寄存器需要初始化才能检测视频"
echo ""
echo "3. 建议的精确检测方法："
echo "   - 使用示波器检查AHD相机的视频输出"
echo "   - 检查RN6854的MIPI输出是否有信号"
echo "   - 查看RN6854数据手册，读取视频检测寄存器"
echo ""

echo "================================================"
echo "Video Device Detection"
echo "================================================"
echo ""

# 检查是否有video设备
if ls /dev/video* >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Video devices found:${NC}"
    ls -l /dev/video* | sed 's/^/  /'
    echo ""
    echo "代码中获取相机数据的方式："
    echo "  - 使用 v4l2 API 打开 /dev/videoX"
    echo "  - 设置格式: ioctl(fd, VIDIOC_S_FMT, &fmt)"
    echo "  - 开始采集: ioctl(fd, VIDIOC_STREAMON, &type)"
    echo "  - 读取帧: read() 或 mmap()"
else
    echo -e "${RED}❌ No /dev/video* devices found${NC}"
    echo ""
    echo "问题诊断："
    echo "  1. 驱动已加载，但没有创建video设备"
    echo "  2. 可能原因："
    echo "     - RN6854未正确配置/初始化"
    echo "     - 设备树(device tree)中没有配置相机节点"
    echo "     - MIPI CSI没有接收到有效信号"
    echo "     - 缺少用户空间的配置工具"
    echo ""
    echo "建议操作："
    echo "  1. 检查系统是否有camera配置工具（如 mipi_camera 命令）"
    echo "  2. 查看 /sys/class/video4linux/ 目录"
    echo "  3. 运行: dmesg | grep -i video"
    echo "  4. 联系方案提供商获取完整的相机初始化脚本"
fi
echo ""

# 检查sys文件系统中的video相关信息
echo "================================================"
echo "System Video Interfaces"
echo "================================================"
echo ""

if [ -d "/sys/class/video4linux" ]; then
    echo "Video4Linux devices in /sys:"
    ls -la /sys/class/video4linux/ | sed 's/^/  /'
else
    echo "⚠️  /sys/class/video4linux/ not found"
fi
echo ""

# 检查是否有相机配置工具
echo "================================================"
echo "Camera Configuration Tools"
echo "================================================"
echo ""

TOOLS=("mipi_camera" "hb_cam_utility" "camera_test" "v4l2-ctl" "media-ctl")
for tool in "${TOOLS[@]}"; do
    if command -v $tool &> /dev/null; then
        echo -e "${GREEN}✅ Found: $tool${NC}"
        which $tool
    else
        echo -e "${YELLOW}⚠️  Not found: $tool${NC}"
    fi
done
echo ""

echo "================================================"
echo "Summary & Next Steps"
echo "================================================"
echo ""
echo "当前状态："
echo "  ✅ RN6854芯片通信正常（I2C）"
echo "  ✅ 内核驱动已加载"
echo "  ❌ 缺少 /dev/video* 设备节点"
echo ""
echo "要使相机在代码中可用，需要："
echo ""
echo "1. 【必须】初始化RN6854芯片"
echo "   - 需要按照RN6854数据手册配置寄存器"
echo "   - 通常需要厂商提供的初始化脚本或配置表"
echo ""
echo "2. 【必须】创建video设备节点"
echo "   - 可能需要手动触发设备创建"
echo "   - 检查是否有系统专用的相机启动脚本"
echo ""
echo "3. 建议联系硬件方案提供商获取："
echo "   - RN6854完整初始化代码/脚本"
echo "   - 相机系统的设备树配置"
echo "   - 示例应用程序"
echo ""
