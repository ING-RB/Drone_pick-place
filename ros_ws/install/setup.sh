cd /home/ros_workspace/PX4-Autopilot
make px4_sitl

cd /home/ros_workspace/install
cp ./model.sdf /home/ros_workspace/PX4-Autopilot/Tools/simulation/gz/models/x500_lidar_2d/model.sdf
cp ./default.sdf /home/ros_workspace/PX4-Autopilot/Tools/simulation/gz/worlds/default.sdf
cp ./4013_gz_x500_lidar_2d /home/ros_workspace/PX4-Autopilot/ROMFS/px4fmu_common/init.d-posix/airframes/4013_gz_x500_lidar_2d

cd /home/ros_workspace/PX4-Autopilot
make px4_sitl
