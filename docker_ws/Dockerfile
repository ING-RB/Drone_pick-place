FROM ros:humble
RUN apt update -y
RUN apt upgrade -y
RUN apt install wget -y

# PX4
COPY requirements.txt /tmp/requirements.txt
COPY ubuntu.sh /tmp/ubuntu.sh
RUN bash /tmp/ubuntu.sh
RUN apt install ros-humble-rviz2 -y
RUN apt-get install lsb-release gnupg -y
RUN apt-get install ros-humble-ros-gzharmonic -y
RUN apt install ros-humble-perception-pcl -y
RUN apt-get install ros-humble-libg2o -y
RUN apt install fuse -y
RUN apt install libopengl0 -y
RUN apt install pipewire -y

# NECESSARY USER TO LAUNCH QGROUND CONTROL
RUN useradd -p password -m -U -s /bin/bash utente
RUN usermod -a -G dialout utente

# LI-SLAM
RUN apt-get install software-properties-common -y
RUN add-apt-repository ppa:borglab/gtsam-release-4.1 -y
RUN apt update -y
RUN apt install libgtsam-dev libgtsam-unstable-dev -y
RUN apt install x11-xserver-utils -y

# MATLAB
RUN apt install libgtk2.0-0 -y

# ENTRYPOINT
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]



#ONLY FOR WINDOWS WSL2
#ENV LIBVA_DRIVER_NAME=d3d12
#ENV LD_LIBRARY_PATH=/usr/lib/wsl/lib