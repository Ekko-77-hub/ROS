# ROS 2 地面机器人与 PX4 无人机学习

无人机源码已作为固定版本 Git 子模块接入。请先阅读 [无人机下载、编译与运行说明](docs/uav_setup_zh.md)。本仓库尚未在用户 Ubuntu 电脑完成编译和飞行验证。

# wpb_home 巡检学习项目

目标环境：Ubuntu 24.04 / ROS 2 Jazzy / Gazebo Harmonic。

## 当前已导入的代码

`src/wpr_simulation2/` 是 [6-robot/wpr_simulation2](https://github.com/6-robot/wpr_simulation2) 的完整源码快照，提交 `cd677ca41e6435550599311d8100ec4cf254eeab`。上游文件保持原样；额外添加 `COLCON_IGNORE`，防止 colcon 在 Jazzy 中误编译 Classic 功能包。`COPYING` 补充 GPLv3 许可证全文，上游 `package.xml` 声明 GPLv3；原始作者、文件内声明及上游 README 均保留。

**这是原始参考代码，尚不是可运行的 Jazzy/Harmonic 自主巡检实现。** 不要在 Ubuntu 24.04 上执行上游 `install_for_humble.sh`。不要把上游 Classic 模型覆盖到本地已转换的 Harmonic 模型。

## 重点阅读

| 文件 | 用途 |
|---|---|
| `src/wpr_simulation2/worlds/robocup_home.world` | 场地墙体 |
| `src/wpr_simulation2/models/wpb_home.model` | URDF 格式机器人模型，包含 Classic 插件 |
| `src/wpr_simulation2/meshes/` | 场景和机器人网格、纹理 |
| `src/wpr_simulation2/launch/robocup_home.launch.py` | 原始场景启动和生成位置 |
| `src/wpr_simulation2/launch/spawn_objects.launch.py` | 家具生成位置，规划路线时必须一起检查 |
| `src/wpr_simulation2/demo_cpp/4_velocity_command.cpp` | Twist 速度发布示例 |
| `src/wpr_simulation2/demo_cpp/8_waypoint_navigation.cpp` | 上游航点示例，不能直接视为本项目巡检器 |
| `docs/inspection.md` | 实际检查结果和后续架构 |

## 获取

```bash
git clone https://github.com/Ekko-77-hub/ROS.git
cd ROS
```

当前不提供巡检启动命令：本地改造模型、定位接口和安全路线尚未确认。
