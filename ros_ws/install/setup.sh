cd /home/ros_workspace/PX4-Autopilot
make px4_sitl

cd /home/ros_workspace/install
cp ./model.sdf /home/ros_workspace/PX4-Autopilot/Tools/simulation/gz/models/x500_lidar_2d/model.sdf
cp ./default.sdf /home/ros_workspace/PX4-Autopilot/Tools/simulation/gz/worlds/default.sdf
cp ./4013_gz_x500_lidar_2d /home/ros_workspace/PX4-Autopilot/ROMFS/px4fmu_common/init.d-posix/airframes/4013_gz_x500_lidar_2d

cd /home/ros_workspace/PX4-Autopilot
make px4_sitl

cd /home/ros_workspace/LI-SLAM
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

cd /home/ros_workspace
wget https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl-x86_64.AppImage
chmod +x QGroundControl-x86_64.AppImage


cd /home/ros_workspace/Micro-XRCE-DDS-Agent
mkdir build
cd build
cmake ..
make
make install 
ldconfig /usr/local/lib/ 

cd /usr/local/MATLAB/R2025a/sys/mwds/glnxa64/packages/glnxa64
7z x mathworksservicehost.enc.zip
cd /usr/local/MATLAB/R2025a/bin/glnxa64
7z x libcef.zip