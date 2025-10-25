cd /home/ros_workspace/PX4-Autopilot
make px4_sitl

cd /home/ros_workspace/install
cp ./model.sdf /home/ros_workspace/PX4-Autopilot/Tools/simulation/gz/models/x500_lidar_2d/model.sdf
cp ./default.sdf /home/ros_workspace/PX4-Autopilot/Tools/simulation/gz/worlds/default.sdf
cp ./4013_gz_x500_lidar_2d /home/ros_workspace/PX4-Autopilot/ROMFS/px4fmu_common/init.d-posix/airframes/4013_gz_x500_lidar_2d

cd /home/ros_workspace/PX4-Autopilot
make px4_sitl

cd /home/ros_workspace/LI-SLAM/build/graph_based_slam/CMakeFiles/graph_based_slam_component.dir/src
unzip graph_based_slam_component.cpp.zip

cd /home/ros_workspace/LI-SLAM/build/scanmatcher/CMakeFiles/scanmatcher_component.dir/src
unzip scanmatcher_component.cpp.zip

cd /home/ros_workspace
wget https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl-x86_64.AppImage
chmod +x QGroundControl-x86_64.AppImage