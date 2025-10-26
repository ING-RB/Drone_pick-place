# PX4
cd /home/ros_workspace
git clone https://github.com/PX4/PX4-Autopilot.git --recursive
cd /home/ros_workspace/PX4-Autopilot
make px4_sitl
cd /home/ros_workspace/install
cp ./model.sdf /home/ros_workspace/PX4-Autopilot/Tools/simulation/gz/models/x500_lidar_2d/model.sdf
cp ./default.sdf /home/ros_workspace/PX4-Autopilot/Tools/simulation/gz/worlds/default.sdf
cp ./4013_gz_x500_lidar_2d /home/ros_workspace/PX4-Autopilot/ROMFS/px4fmu_common/init.d-posix/airframes/4013_gz_x500_lidar_2d
cd /home/ros_workspace/PX4-Autopilot
make px4_sitl


# LI-SLAM
cd /home/ros_workspace/LI-SLAM
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release


# Micro-XRCE-DDS-Agent
mkdir /home/ros_workspace/Micro-XRCE-DDS-Agent/build
cd /home/ros_workspace/Micro-XRCE-DDS-Agent/build
cmake ..
make
make install 
ldconfig /usr/local/lib/ 


# Attach_plugin
mkdir /home/ros_workspace/Attach_plugin/build
cd /home/ros_workspace/Attach_plugin/build
cmake ..
make


# drone
cd /home/ros_workspace/drone
colcon build


# MATLAB
cd /usr/local/MATLAB/R2025a/sys/mwds/glnxa64/packages/glnxa64
7z x mathworksservicehost.enc.zip
cd /usr/local/MATLAB/R2025a/bin/glnxa64
7z x libcef.zip


# QGroundControl
cd /home/ros_workspace
wget https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl-x86_64.AppImage
chmod +x QGroundControl-x86_64.AppImage
