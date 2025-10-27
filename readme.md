
# Drone_pick-place
Gazebo simulation of a x500 drone using ros2 and li_slam_ros2 and Matlab Navigation Toolbox.


## Requirements

 - Docker
 - Nvidia-toolkit
 - x11-server-utils
>If you don't want to use Nvidia-toolkit use sudo ./run_no_nvidia.sh instead of sudo ./run.sh

## Installation
**Clone the repository:**

    git clone https://github.com/ING-RB/Drone_pick-place.git

**From Drone_pick-place folder:**

    cd docker_ws
    sudo ./build.sh
    cd ..
    sudo ./run.sh

**From the container terminal you just opened:**

    cd install
    ./setup.sh
    exit

## Demo
You will need 3 terminals.
### TERMINAL 1:
**From Drone_pick-place folder:**

    sudo ./run.sh

**From the container terminal you just opened:**
Launch matlab (you need internet connection)

    /usr/local/MATLAB/R2025a/bin/matlab

Log in and run (in Matlab) the script /home/ros_workspace/MATLAB/Path_planning/Path_Planning_ss3dROS.m

>**!!!Important:** Wait until the "Ready to receive path requests" message appears on the console

### TERMINAL 2:
**From Drone_pick-place folder:**

    sudo ./exec.sh

**From the container terminal you just opened:**
   

    cd /home/ros_workspace/Micro-XRCE-DDS-Agent/build
    make install
    ldconfig /usr/local/lib/
    cd /home/ros_workspace
    source /opt/ros/humble/setup.bash  && source /home/ros_workspace/LI-SLAM/install/setup.bash && source /home/ros_workspace/drone/install/setup.bash && export GZ_PLUGIN_PATH=${GZ_PLUGIN_PATH}:/home/ros_workspace/Attach_plugin/build
    ros2 launch scanmatcher lio.launch.py

>**NOTE 1**: at the first launch the drone can have unexpected behaviour, it's raccomanded to wait until everything is initialized, stop (Ctrl + C) and launch again ros2 launch scanmatcher lio.launch.py

>**NOTE 2**: if your computer doesn't slow down the simulation too much you can enable the last PointCloud2 in the left panel in rviz2 to show map built by the SLAM module

>**!!!Important**: Wait until the "Ready for takeoff!" message appears on the terminal

### TERMINAL 3:
**From Drone_pick-place folder:**

    sudo ./exec.sh

**From the container terminal you just opened:**

    source /opt/ros/humble/setup.bash  && source /home/ros_workspace/LI-SLAM/install/setup.bash  && source /home/ros_workspace/drone/install/setup.bash && export GZ_PLUGIN_PATH=${GZ_PLUGIN_PATH}:/home/ros_workspace/Attach_plugin/build
    ros2 run px4_ros_com offboard_control.py

## TROUBLESHOOTING
**The drone doesn't appear in gazebo OR "Ready for takeoff!" message doesn't appear:**
Ctrl + C and launch again the command ros2 launch scanmatcher lio.launch.py

**After offboard_control.py seems stuck after "Path request sent" message:**
- make sure matlab is running Path_Planning_ss3dROS.m
- Ctrl + C, then click on matlab console window to wake up matlab and launch again the command ros2 run px4_ros_com offboard_control.py

**QGround Control doesn't start:**
From the container terminal run:

    echo $DISPLAY
If it's different from :1 you need to edit the file /home/ros_workspace/LI-SLAM/src/li_slam_ros2/scanmatcher/launch/lio.launch.py.

Change the row:

    cmd=["runuser -l utente -c 'export DISPLAY=:1 && /home/ros_workspace/QGroundControl-x86_64.AppImage'"],

With:

    cmd=["runuser -l utente -c 'export DISPLAY=:<your $DISPLAY> && /home/ros_workspace/QGroundControl-x86_64.AppImage'"],

Then, from the container terminal run:

    cd /home/ros_workspace/LI-SLAM
    colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release


