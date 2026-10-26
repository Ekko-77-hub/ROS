# 源码检查与后续实施

## 已确认

- 上游 README 标注 Ubuntu 22.04 / ROS 2 Humble。
- CMakeLists.txt 强制查找并导出 gazebo_ros_pkgs；package.xml 依赖 gazebo_dev、gazebo_ros、gazebo_ros_pkgs。这些是 Classic 依赖，不能原样用于当前 Jazzy/Harmonic。
- wpb_home.model 是 URDF（根元素 robot），不是 SDF；包含 libgazebo_ros_planar_move.so、ray sensor、camera、IMU 等 Classic 插件。
- 原始 planar_move 配置 /cmd_vel、/odom 和 odom TF，但只有对应 Classic 插件成功加载时才有效；不能据此断言 Harmonic 当前存在 /odom 或激光数据。
- 上游 robocup_home.launch.py 生成机器人位置 x=-6.0、y=-0.5、yaw=0.0。这只是上游默认值，不代表用户当前仿真的实际位置。
- 家具通过 spawn_objects.launch.py 独立生成，不只存在于 world 文件中，例如床 (5,-3.9)、沙发 (-1,-3.9)、茶几 (-2.1,-2.2)、书柜 (2,-0.55)、厨房桌 (-3.5,3.7)。坐标单位米，安全余量仍须结合模型碰撞体计算。
- 世界中 RoboCup_Home 模型也有自身 pose，解析墙体需累计模型和 link 的坐标变换，不能把 ground_plane 的 100×100 当作可巡检范围。
- 上游中没有用户自己的 wpb_controller、wpb_home_jazzy.urdf、wpb_home_jazzy.sdf，也没有用户当前的 ros_gz_bridge 配置。

## 建议架构

1. 保留原始参考代码，另行实现 Jazzy 的 wpb_controller，不依赖 Classic。
2. 先检查当前模型和 Gazebo 话题；若没有 odom，核实 Harmonic 真值位姿接口，确认实体、坐标系、时间戳、频率后再适配，不能伪造里程计。
3. 将当前世界、家具及机器人完整碰撞范围投影到平面，留出机身和转弯余量后确定闭合路线；目前不发布猜测的巡检坐标。
4. rclpy 控制节点使用 IDLE / INITIALIZING / TURNING / MOVING / REACHED_WAYPOINT / RETURNING / COMPLETED / ERROR 状态；配置集中管理。先单点，再闭环。
5. 定位缺失、过期、跳变、无进展、任务超时或速度发布者冲突时拒绝运动或停止。完成后持续零速度；退出清理尽力停车，并核实仿真端命令超时保护。
6. 预设路线反馈控制不等于动态避障；基础版本不引入完整 Nav2。

## 需要本地补充

- 实际使用的 wpb_home_jazzy.urdf/.sdf 和 wpb_controller 源码。
- 启动 Gazebo、生成机器人及桥接的实际命令。
- 仿真运行时的接口输出：

```bash
ros2 node list
ros2 topic list -t
ros2 topic info /cmd_vel -v
gz topic -l
```

发现实际定位话题后再检查消息内容和频率；不要假定话题名称。

## 验证记录

已执行：源仓库检索、关键文件阅读和源码快照一致性检查。
尚未验证：Jazzy 编译、Gazebo 启动、定位反馈、单点运动、多点巡检、闭环返回、异常停车。当前执行环境未提供 ROS 2 / Gazebo 命令。
