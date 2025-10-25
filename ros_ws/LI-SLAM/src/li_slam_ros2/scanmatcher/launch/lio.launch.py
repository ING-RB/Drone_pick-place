import os

import launch
import launch_ros.actions

from ament_index_python.packages import get_package_share_directory

from launch.actions import ExecuteProcess

def generate_launch_description():

    mapping_param_dir = launch.substitutions.LaunchConfiguration(
        'mapping_param_dir',
        default=os.path.join(
            get_package_share_directory('scanmatcher'),
            'param',
            'lio.yaml'))

    mapping = launch_ros.actions.Node(
        package='scanmatcher',
        executable='scanmatcher_node',
        parameters=[mapping_param_dir],
        output='screen'
        )

    graphbasedslam = launch_ros.actions.Node(
        package='graph_based_slam',
        executable='graph_based_slam_node',
        parameters=[mapping_param_dir],
        output='screen'
        )
    
    tf_lidar = launch_ros.actions.Node(
        package='tf2_ros',
        executable='static_transform_publisher',
        arguments=['0.15','0','0.01','0','0','0','1','base_link','x500_lidar_2d_0/lidar_sensor_link/sensor']
        )
    
    tf_imu = launch_ros.actions.Node(
        package='tf2_ros',
        executable='static_transform_publisher',
        arguments=['0','0','0','0','0','0','1','base_link','x500_lidar_2d_0/imu_sensor_link/sensor']
        )


    imu_pre = launch_ros.actions.Node(
        package='scanmatcher',
        executable='imu_preintegration',
        remappings=[('/odometry','/odom')],
        parameters=[mapping_param_dir],
        output='screen'
        )

    img_pro = launch_ros.actions.Node(
        package='scanmatcher',
        executable='image_projection',
        parameters=[mapping_param_dir],
        output='screen'
        )

    rviz = launch_ros.actions.Node(
        package='rviz2',
        executable='rviz2',
        arguments=['-d', '/home/ros_workspace/LI-SLAM/src/li_slam_ros2/scanmatcher/rviz/lio_bigloop.rviz']
        )
    
    imu_bridge = launch_ros.actions.Node(
        package='ros_gz_bridge',
        executable='parameter_bridge',
        arguments=[
            '/world/default/model/x500_lidar_2d_0/link/base_link/sensor/imu_sensor/imu@sensor_msgs/msg/Imu@gz.msgs.IMU',
            '--ros-args',
            '--remap',
            '/world/default/model/x500_lidar_2d_0/link/base_link/sensor/imu_sensor/imu:=/imu'
        ],
        output='screen'
    )

    lidar_bridge = launch_ros.actions.Node(
        package='ros_gz_bridge',
        executable='parameter_bridge',
        arguments=[
            '/world/default/model/x500_lidar_2d_0/link/lidar_sensor_link/sensor/sensor/scan/points@sensor_msgs/msg/PointCloud2@gz.msgs.PointCloudPacked',
            '--ros-args',
            '--remap',
            '/world/default/model/x500_lidar_2d_0/link/lidar_sensor_link/sensor/sensor/scan/points:=/input_cloud'
        ],
        output='screen'
    )

    launch_republisher = launch_ros.actions.Node(
        package='republisher',
        executable='republisher_node',
        output='screen'
    )

    attach_bridge = launch_ros.actions.Node(
        package='ros_gz_bridge',
        executable='parameter_bridge',
        arguments=['/Attach@std_msgs/msg/String@gz.msgs.StringMsg'],
        output='screen'
    )

    launch_qgc = ExecuteProcess(
        cmd=["runuser -l utente -c 'export DISPLAY=:1 && /home/ros_workspace/QGroundControl-x86_64.AppImage'"],
        shell=True,
        output='screen'
    )
    launch_MicroXRCEAgent = ExecuteProcess(
        cmd=["MicroXRCEAgent udp4 -p 8888"],
        shell=True,
        output='screen'
    )

    launch_PX4 = ExecuteProcess(
        cwd='/home/ros_workspace/PX4-Autopilot',
        cmd=["make px4_sitl gz_x500_lidar_2d"],
        shell=True,
        output='screen'
        
    )

    return launch.LaunchDescription([
        launch.actions.DeclareLaunchArgument(
            'mapping_param_dir',
            default_value=mapping_param_dir,
            description='Full path to mapping parameter file to load'),
        mapping,
        imu_bridge,
        lidar_bridge,
        attach_bridge,
        tf_lidar,
        tf_imu,
        imu_pre,
        img_pro,
        graphbasedslam,
        rviz,
        launch_qgc,
        launch_MicroXRCEAgent,
        launch_PX4,
        launch_republisher
            ])