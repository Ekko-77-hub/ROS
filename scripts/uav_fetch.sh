#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
git submodule sync --recursive
git submodule update --init --recursive --jobs 2 -- uav/PX4-Autopilot uav/Micro-XRCE-DDS-Agent uav/ros2_ws/src/px4_msgs uav/ros2_ws/src/px4_ros_com
echo "核心源码已下载；Python参考项目和规划器按中文说明单独下载。"
