#!/bin/bash
set -e

# setup ros2 environment
source "/opt/ros/$ROS_DISTRO/setup.bash" --

cd /home/ros_workspace/Micro-XRCE-DDS-Agent/build
make install 
ldconfig /usr/local/lib/ 

cd /home/ros_workspace


exec "$@"


