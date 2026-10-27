# 无人机代码与本地编译（Ubuntu 24.04 / Jazzy / Harmonic）

## 代码已接入仓库
采用 Git 子模块，GitHub 上点击目录可以跳转到对应源码。不是仅放网址清单：父仓库记录每个源码目录的固定 commit，下载命令会在电脑上恢复完整源码和 PX4 的嵌套依赖。不要用 GitHub 的 Download ZIP，它不会包含子模块源码。

| 目录 | 来源与用途 |
|---|---|
| uav/PX4-Autopilot | PX4/PX4-Autopilot v1.16.0，飞控及 SITL |
| uav/Micro-XRCE-DDS-Agent | eProsima/Micro-XRCE-DDS-Agent v2.4.3，通信代理 |
| uav/ros2_ws/src/px4_msgs | PX4/px4_msgs release/1.16，匹配固件的消息定义 |
| uav/ros2_ws/src/px4_ros_com | PX4/px4_ros_com，官方 C++ / Python 示例 |
| uav/references/python-offboard | ARK-Electronics/ROS2_PX4_Offboard_Example，旧版 Python 参考 |
| uav/references/ego-planner-swarm | ZJU-FAST-Lab/ego-planner-swarm ros2_version，后续规划参考 |

全部固定 SHA 见 uav/versions.json。各上游许可证和版权声明随子模块保留，根目录 COPYING 针对之前导入的 GPLv3 地面机器人代码，不替代各子模块许可证。
ARK 原教程基于 Ubuntu 22.04/Humble/PX4 1.15，不纳入本次构建；EGO 分支也未验证 Jazzy/PX4 集成。

## 1. 下载核心源码
新终端先退出 conda，若提示符仍有 (base)，继续 conda deactivate。
首次下载：
```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/Ekko-77-hub/ROS.git
cd ROS
bash scripts/uav_fetch.sh
```
已有 ~/projects/ROS：
```bash
cd ~/projects/ROS
git status
git pull --ff-only
bash scripts/uav_fetch.sh
```
若有未提交修改，先保留并解决拉取冲突，不要强制覆盖。脚本不使用 --remote，按父仓库记录的版本下载。

按需下载两个研究参考仓库：
```bash
git submodule update --init --recursive -- uav/references/python-offboard uav/references/ego-planner-swarm
```

## 2. 安装编译依赖（本机执行，需要 sudo）
已有 ROS 2 Jazzy 和 Gazebo Harmonic。上游 v1.16.0 的 ubuntu.sh 支持 Ubuntu 24.04；先阅读脚本，它会 apt 安装依赖、配置 Gazebo 源并安装 Python 依赖（Python 3.11+ 使用 --break-system-packages）。这是依赖安装步骤，与下面不含 sudo 的编译步骤分开。
```bash
cd ~/projects/ROS
bash uav/PX4-Autopilot/Tools/setup/ubuntu.sh --no-nuttx
sudo apt update
sudo apt install python3-colcon-common-extensions ros-jazzy-eigen3-cmake-module libeigen3-dev
```
仅做 SITL，无须安装 NuttX 真机工具链。若依赖安装失败，保留错误，不要继续声称构建通过。

## 3. 检查并编译
```bash
cd ~/projects/ROS
bash scripts/uav_build.sh --check
bash scripts/uav_build.sh --all
```
默认并行任务数 2；可用 UAV_BUILD_JOBS=4 bash scripts/uav_build.sh --all 调整 PX4 和 Agent 并行度。ROS 包采用顺序构建。
也可分别执行 --ros、--agent、--px4，失败时只重试对应部分。
日志在 uav/logs/，使用 pipefail 保留真实错误码。脚本不启动仿真、不解锁、不自动执行起飞。

## 4. 构建成功后先检查通信
先退出之前的 wpb_home Gazebo 仿真，避免混淆。

终端一：启动本仓库构建的 Agent：
```bash
cd ~/projects/ROS
export LD_LIBRARY_PATH="$PWD/uav/agent_install/lib:$PWD/uav/agent_install/lib64:${LD_LIBRARY_PATH:-}"
./uav/agent_install/bin/MicroXRCEAgent udp4 -p 8888
```

终端二：启动 PX4 SITL 与 Gazebo x500：
```bash
cd ~/projects/ROS/uav/PX4-Autopilot
make px4_sitl gz_x500
```

终端三：加载无人机工作空间并查看实际话题：
```bash
cd ~/projects/ROS
source /opt/ros/jazzy/setup.bash
source uav/ros2_ws/install/setup.bash
ros2 pkg executables px4_ros_com
ros2 topic list -t
```
在列表中找到实际 vehicle_local_position 和 vehicle_status 话题再 echo/hz，注意新消息可能有版本后缀，不能只凭示例硬编码话题断言通信正常。PX4 输出通常需要 best_effort QoS：
```bash
# 用实际话题替换 <位置话题>：
# ros2 topic echo <位置话题> --qos-reliability best_effort --once
# ros2 topic hz <位置话题>
```

## 5. 先读 Python 示例，再做仿真飞行
官方 Python 源码：
uav/ros2_ws/src/px4_ros_com/src/examples/offboard_py/offboard_control.py
安装后的入口：
ros2 run px4_ros_com offboard_control.py

该示例会请求 Offboard 和解锁，达到约 5m 后请求降落。它是教学例程，没有本项目要求的完整状态机、定位超时及可靠降落确认。确认只有 SITL 接入、定位和状态正常后，才单独运行；不要同时运行 C++ 和 Python 控制例程。Ctrl+C 并不等于无人机立即安全降落，停止心跳会触发 PX4 配置的失联行为，应在仿真中通过 QGroundControl 观察和接管。默认构建不运行任何此类控制节点。

## 已执行与尚未验证
- 已执行：GitHub 版本核对、官方构建脚本及示例接口阅读、本项目脚本语法检查、缺少 Jazzy 时的拒绝执行检查、远端子模块 SHA 核验。
- 尚未验证：Ubuntu 本机依赖安装、ROS 包编译、Agent 编译、PX4 编译、Gazebo GUI、DDS 通信、起降及路径规划。
- 当前会话是云端环境，没有 /opt/ros、colcon、gz，也没有访问用户电脑的 SSH 会话；不能声称已在用户电脑编译。

## 官方依据
- https://github.com/PX4/PX4-Autopilot/blob/v1.16.0/Tools/setup/ubuntu.sh
- https://docs.px4.io/main/en/middleware/uxrce_dds
- https://github.com/PX4/px4_msgs
- https://github.com/PX4/px4_ros_com

## 出错时提供
编译失败后粘贴 uav/logs/ 对应日志最后 80 行，并附 lsb_release -ds、python3 --version、which python3、echo "$ROS_DISTRO" 输出。不要上传 GitHub 凭据。
