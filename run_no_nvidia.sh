xhost +
docker run -it --rm --net host --ipc host --privileged \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v ~/.Xauthority:/root/.Xauthority \
    -e DISPLAY=$DISPLAY \
    -e XAUTHORITY=$XAUTHORITY \
    -v ./ros_ws/:/home/ros_workspace \
    -v ./matlab:/usr/local/MATLAB/R2025a \
    -v ./matlab_prefdir:/root/.matlab \
    --name drone \
    ros:drone bash
    
# matlab: matlab install folder
# matlab_prefdir: matlab settings and preferences (so you don't always have to log in)
