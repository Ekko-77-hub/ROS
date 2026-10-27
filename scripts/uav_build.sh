#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
mode="${1:---check}"
case "$mode" in --check|--ros|--agent|--px4|--all) ;; *) echo "用法: $0 [--check|--ros|--agent|--px4|--all]" >&2; exit 2;; esac
if [[ -n "${CONDA_PREFIX:-}" || -n "${VIRTUAL_ENV:-}" ]]; then
  echo "请退出 conda/虚拟环境，用 Ubuntu 系统 Python 编译。" >&2; exit 1
fi
[[ -f /opt/ros/jazzy/setup.bash ]] || { echo "缺少 /opt/ros/jazzy/setup.bash；需要在已安装 Jazzy 的 Ubuntu 电脑执行。" >&2; exit 1; }
for cmd in git python3 cmake make colcon gz; do
  command -v "$cmd" >/dev/null || { echo "缺少命令: $cmd" >&2; exit 1; }
done
python3 "$root/scripts/uav_verify.py"
if [[ "$mode" == --check ]]; then
  echo "源码版本与基础命令检查通过；尚不代表依赖完整或编译通过。"
  exit 0
fi
# ROS setup 脚本可能读取未定义变量，因此加载时暂时关闭 nounset。
set +u
source /opt/ros/jazzy/setup.bash
set -u
export PATH="/usr/bin:$PATH"
jobs="${UAV_BUILD_JOBS:-2}"
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || { echo "UAV_BUILD_JOBS 必须为正整数" >&2; exit 2; }
mkdir -p "$root/uav/logs"
if [[ "$mode" == --ros || "$mode" == --all ]]; then
  (cd "$root/uav/ros2_ws" && colcon build --symlink-install --packages-select px4_msgs px4_ros_com --executor sequential --cmake-args -DBUILD_TESTING=OFF) 2>&1 | tee "$root/uav/logs/ros-build.log"
fi
if [[ "$mode" == --agent || "$mode" == --all ]]; then
  cmake -S "$root/uav/Micro-XRCE-DDS-Agent" -B "$root/uav/agent_build" -DCMAKE_INSTALL_PREFIX="$root/uav/agent_install" 2>&1 | tee "$root/uav/logs/agent-configure.log"
  cmake --build "$root/uav/agent_build" --parallel "$jobs" 2>&1 | tee "$root/uav/logs/agent-build.log"
  cmake --install "$root/uav/agent_build" 2>&1 | tee "$root/uav/logs/agent-install.log"
fi
if [[ "$mode" == --px4 || "$mode" == --all ]]; then
  (cd "$root/uav/PX4-Autopilot" && DONT_RUN=1 make -j"$jobs" px4_sitl gz_x500) 2>&1 | tee "$root/uav/logs/px4-build.log"
fi
echo "所选构建步骤完成；未启动仿真或飞行控制。"
