#!/usr/bin/env python3
"""
示例：如何在Python代码中访问相机数据
运行: python3 camera_access_example.py
"""

import os
import sys
import glob

def check_video_devices():
    """检查系统中的video设备"""
    print("=" * 50)
    print("Camera Device Detection (Python)")
    print("=" * 50)
    print()
    
    # 查找所有video设备
    video_devices = glob.glob('/dev/video*')
    
    if not video_devices:
        print("❌ No video devices found!")
        print()
        print("This means:")
        print("  • Camera system is not initialized")
        print("  • No /dev/videoX device nodes exist")
        print("  • Python code cannot access cameras yet")
        print()
        print("Run: ./simple_camera_check.sh")
        return False
    
    print(f"✅ Found {len(video_devices)} video device(s):")
    for dev in sorted(video_devices):
        print(f"   • {dev}")
    print()
    
    return True

def check_opencv():
    """检查OpenCV是否可用"""
    try:
        import cv2
        print("✅ OpenCV installed (cv2 available)")
        print(f"   Version: {cv2.__version__}")
        return True
    except ImportError:
        print("⚠️  OpenCV not installed")
        print("   Install: pip3 install opencv-python")
        return False

def check_v4l2():
    """检查v4l2是否可用"""
    try:
        import v4l2
        print("✅ python-v4l2 installed")
        return True
    except ImportError:
        print("⚠️  python-v4l2 not installed")
        print("   Install: pip3 install v4l2")
        return False

def test_opencv_capture(device_id=0):
    """测试OpenCV采集"""
    try:
        import cv2
        
        print()
        print(f"Testing OpenCV capture on /dev/video{device_id}...")
        
        cap = cv2.VideoCapture(device_id)
        
        if not cap.isOpened():
            print(f"❌ Cannot open /dev/video{device_id}")
            return False
        
        print("✅ Camera opened successfully")
        
        # 获取属性
        width = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
        height = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
        fps = cap.get(cv2.CAP_PROP_FPS)
        
        print(f"   Resolution: {int(width)}x{int(height)}")
        print(f"   FPS: {fps}")
        
        # 尝试读取一帧
        ret, frame = cap.read()
        if ret:
            print("✅ Successfully captured a frame")
            print(f"   Frame shape: {frame.shape}")
        else:
            print("❌ Cannot capture frame")
        
        cap.release()
        return ret
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def example_usage():
    """显示使用示例"""
    print()
    print("=" * 50)
    print("Python Code Examples")
    print("=" * 50)
    print()
    
    print("方法1: 使用OpenCV (推荐)")
    print("-" * 40)
    print("""
import cv2

# 打开摄像头
cap = cv2.VideoCapture(0)  # 0 表示 /dev/video0

if cap.isOpened():
    # 读取一帧
    ret, frame = cap.read()
    if ret:
        print(f"Frame shape: {frame.shape}")
        # frame 是 numpy 数组，可以直接处理
        
        # 显示（如果有GUI）
        # cv2.imshow('Camera', frame)
        # cv2.waitKey(0)
        
    cap.release()
""")
    
    print()
    print("方法2: 使用v4l2 (底层控制)")
    print("-" * 40)
    print("""
import v4l2
import fcntl

fd = open('/dev/video0', 'rb+', buffering=0)

# 查询设备能力
cap = v4l2.v4l2_capability()
fcntl.ioctl(fd, v4l2.VIDIOC_QUERYCAP, cap)
print(f"Driver: {cap.driver.decode()}")
print(f"Card: {cap.card.decode()}")

fd.close()
""")
    
    print()
    print("方法3: 使用GStreamer")
    print("-" * 40)
    print("""
import gi
gi.require_version('Gst', '1.0')
from gi.repository import Gst

Gst.init(None)

# 创建pipeline
pipeline_str = "v4l2src device=/dev/video0 ! videoconvert ! autovideosink"
pipeline = Gst.parse_launch(pipeline_str)
pipeline.set_state(Gst.State.PLAYING)
""")

def main():
    # 1. 检查video设备
    if not check_video_devices():
        sys.exit(1)
    
    # 2. 检查可用的库
    print("=" * 50)
    print("Available Libraries")
    print("=" * 50)
    print()
    
    opencv_available = check_opencv()
    v4l2_available = check_v4l2()
    
    print()
    
    # 3. 如果OpenCV可用，尝试采集
    if opencv_available:
        video_devices = glob.glob('/dev/video*')
        if video_devices:
            # 测试第一个设备
            device_id = int(video_devices[0].replace('/dev/video', ''))
            test_opencv_capture(device_id)
    
    # 4. 显示使用示例
    example_usage()
    
    print()
    print("=" * 50)
    print("Summary")
    print("=" * 50)
    print()
    
    video_devices = glob.glob('/dev/video*')
    if video_devices and opencv_available:
        print("✅ 系统就绪！可以在Python代码中获取相机数据")
        print()
        print("快速开始:")
        print("  python3 -c \"import cv2; cap = cv2.VideoCapture(0); print('OK' if cap.isOpened() else 'FAIL')\"")
    else:
        print("⚠️  需要完成以下步骤:")
        if not video_devices:
            print("  1. 初始化相机系统（创建/dev/video设备）")
        if not opencv_available:
            print("  2. 安装 OpenCV: pip3 install opencv-python")
    print()

if __name__ == "__main__":
    main()
