#!/bin/bash

echo "================================================"
echo "Camera System Diagnostics"
echo "================================================"
echo ""

# 1. I2C设备检测
echo "1. I2C Device Detection"
echo "------------------------"
check_camera() {
    local BUS=$1
    local ADDR=$2
    local NAME=$3
    
    echo "[$NAME] i2c-$BUS @ $ADDR:"
    if i2ctransfer -y $BUS w1@$ADDR 0x00 r1 >/dev/null 2>&1; then
        CHIP_ID=$(i2ctransfer -y $BUS w1@$ADDR 0x00 r1 2>/dev/null | awk '{print $1}')
        echo "  ✅ Detected - Chip ID: $CHIP_ID"
    else
        echo "  ❌ Not detected"
    fi
}

check_camera 4 0x2c "RN6854-4路AHD"
check_camera 3 0x2c "RN6854-2路AHD"
echo ""

# 2. 内核驱动检查
echo "2. Kernel Drivers"
echo "------------------------"
echo "Loaded camera/video modules:"
lsmod | grep -E "video|camera|isp|mipi|csi|gc2053|rn6854" || echo "  No specific camera modules found"
echo ""

# 3. 视频设备节点
echo "3. Video Device Nodes"
echo "------------------------"
if ls /dev/video* >/dev/null 2>&1; then
    for dev in /dev/video*; do
        echo "  📹 $dev"
        if command -v v4l2-ctl &> /dev/null; then
            v4l2-ctl -d $dev --info 2>/dev/null | head -5 | sed 's/^/     /'
        fi
    done
else
    echo "  ❌ No /dev/video* devices found"
fi
echo ""

# 4. Media设备
echo "4. Media Devices"
echo "------------------------"
if ls /dev/media* >/dev/null 2>&1; then
    for dev in /dev/media*; do
        echo "  📺 $dev"
        if command -v media-ctl &> /dev/null; then
            media-ctl -d $dev -p 2>/dev/null | head -10 | sed 's/^/     /'
        fi
    done
else
    echo "  ℹ️  No /dev/media* devices found"
fi
echo ""

# 5. I2C总线信息
echo "5. I2C Bus Information"
echo "------------------------"
if command -v i2cdetect &> /dev/null; then
    echo "Scanning i2c-3:"
    i2cdetect -y -r 3 2>/dev/null | sed 's/^/  /'
    echo ""
    echo "Scanning i2c-4:"
    i2cdetect -y -r 4 2>/dev/null | sed 's/^/  /'
else
    echo "  ℹ️  i2cdetect not available"
fi
echo ""

# 6. 设备树信息
echo "6. Device Tree Camera Nodes"
echo "------------------------"
if [ -d /proc/device-tree ]; then
    echo "Camera-related device tree nodes:"
    find /proc/device-tree -name "*camera*" -o -name "*mipi*" -o -name "*csi*" -o -name "*isp*" 2>/dev/null | head -10 | sed 's/^/  /'
    if [ $? -ne 0 ]; then
        echo "  ℹ️  No camera nodes found in device tree"
    fi
else
    echo "  ℹ️  Device tree not accessible"
fi
echo ""

# 7. 内核日志（最近的相机相关消息）
echo "7. Recent Kernel Messages (camera/i2c/mipi)"
echo "------------------------"
dmesg | grep -iE "camera|mipi|csi|i2c-[34]|video|rn6854|gc2053" | tail -20 | sed 's/^/  /'
echo ""

# 8. 系统信息
echo "8. System Information"
echo "------------------------"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo ""

echo "================================================"
echo "Diagnostics Complete"
echo "================================================"
echo ""
echo "Next Steps:"
echo "  1. Check if /dev/video* devices exist"
echo "  2. If not, check kernel logs for driver errors"
echo "  3. Verify device tree configuration includes camera nodes"
echo "  4. Test video capture: v4l2-ctl -d /dev/video0 --list-formats-ext"
