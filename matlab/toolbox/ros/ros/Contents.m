% ROS Toolbox
% Version 25.1 (R2025a) 21-Nov-2024
%
% Network Connection and Exploration
%   rosinit            - Initialize the ROS system
%   rosshutdown        - Shut down the ROS system
%   rosaction          - Get information about actions in the ROS network
%   rosmsg             - Get information about messages and message types
%   rosnode            - Get information about nodes in the ROS network
%   rosservice         - Get information about services in the ROS network
%   rostopic           - Get information about topics in the ROS network
%   rosparam           - Get and set values on the parameter server
%   rosdevice          - Connect to remote ROS device
%   ros2device         - Connect to remote ROS 2 device
%
%   ros2               - Retrieve information about ROS 2 network
%   ros2param          - Interact with ROS 2 parameters
%
% Publishers and Subscribers
%   rosmessage         - Create a ROS message
%   rostype            - View available ROS message types
%   rospublisher       - Create a ROS publisher
%   rossubscriber      - Create a ROS subscriber
%
%   ros2message        - Create a ROS 2 message structure
%   ros2node           - Create a ROS 2 node on the specified network
%   ros2type           - View available ROS 2 messages, services, and actions
%   ros2publisher      - Create a ROS 2 publisher
%   ros2subscriber     - Create a ROS 2 subscriber
%
% Services and Actions
%   rossvcclient       - Create a ROS service client
%   rossvcserver       - Create a ROS service server
%   ros2svcclient      - Create a ROS 2 service client
%   ros2svcserver      - Create a ROS 2 service server
%   rosactionclient    - Create a ROS action client
%   rosactionserver    - Create a ROS action server
%   rosActionServerExecuteGoalFcn - Return a function handle for action server callback
%   ros2actionclient   - Create a ROS 2 action client
%   ros2ActionSendGoalOptions - Create a ROS 2 action send goal option
%   ros2actionserver   - Create a ROS 2 action server
%
% ROS Log Files and Transformations
%   rosbag             - Open and parse a rosbag log file
%   rosbagreader       - Access rosbag log file information
%   rosbagwriter       - Write messages to rosbag log files
%   rostime            - Access ROS time functionality
%   rosrate            - Execute fixed-frequency loop using ROS time
%   rosduration        - Create a ROS duration object
%   rostf              - Receive, send, and apply ROS transformations
%
% ROS 2 Log Files and Transformations
%   ros2bagreader      - Open and parse a ros2bag log file
%   ros2bagwriter      - Write messages to ros2bag log files
%   ros2time           - Access ROS 2 time functionality
%   ros2rate           - Execute fixed-frequency loop using ROS 2 time
%   ros2duration       - Create a ROS 2 duration message
%   ros2tf             - Receive, send, and apply ROS 2 transformations
%
% ROS Custom Message Support
%   rosgenmsg            - Generate custom messages from ROS definitions
%   rosRegisterMessages  - Register generated ROS custom messages
%   ros2genmsg           - Generate custom messages from ROS 2 definitions
%   ros2RegisterMessages - Register generated ROS 2 custom messages
%   rosAddons            - Install add-ons for ROS Toolbox
%
% ROS Velodyne Interpretation
%   ousterROSMessageReader      - Create an Ouster ROS message reader object
%   velodyneROSMessageReader    - Create a Velodyne ROS message reader object
%
% Convenience Functions for Specialize Messages
%   rosApplyTransform           - Apply transform to struct message entities
%   rosPlot                     - Plot LiDAR scan data or point cloud data
%   rosReadTransform            - Return transformation from a TransformStamped struct message 
%   rosReadAllFieldNames        - Return all field names in a PointCloud2 struct message
%   rosReadBinaryOccupancyGrid  - Return a BinaryOccupancyGrid object given OccupancyGrid struct message
%   rosReadCartesian            - Return Cartesian (XY) coordinates for a LaserScan struct message
%   rosReadField                - Read data based on given field name in a PointCloud2 struct message
%   rosReadImage                - Convert a Image struct message into a MATLAB image
%   rosReadLidarScan            - Return an object for 2D lidar scan from a LaserScan struct message
%   rosReadOccupancyGrid        - Return an occupancyMap object from a OccupancyGrid struct message
%   rosReadOccupancyMap3D       - Return an occupancyMap3D object from a Octomap struct message
%   rosReadQuaternion           - Return the quaternion from a struct message
%   rosReadRGB                  - Return the RGB color matrix from a PointCloud2 struct message
%   rosReadScanAngles           - Return the scan angles from a PointCloud2 struct message
%   rosReadXYZ                  - Return the (x,y,z) coordinates from a PointCloud2 struct message
%   rosShowDetails              - Print the details of a struct message recursively
%   rosWriteBinaryOccupancyGrid - Write BinaryOccupancyMap to a OccupancyGrid struct message
%   rosWriteCameraInfo          - Write data from stereoParameters or cameraParameters structure to ROS message
%   rosWriteImage               - Write a MATLAB image to a Image struct message
%   rosWriteOccupancyGrid       - Write OccupancyMap to a OccupancyGrid struct message
%   rosWriteXYZ                 - Write points in (x,y,z) coordinates to a ROS/ROS 2 pointcloud2 message struct.
%   rosWriteRGB                 - Write RGB Color information to a ROS/ROS 2 pointcloud2 message struct.
%   rosWriteIntensity           - Write points in intensity data to a ROS/ROS 2 pointcloud2 message struct.
%
% Visualization App
%   rosDataAnalyzer             - Visualize messages in ROS bag and ROS 2 bag file
%   ros2NetworkAnalyzer         - Analyze ros 2 network
%   rosbagViewer                - Visualize and annotate ROS and ROS 2 data
%
% <a href="matlab:demo('toolbox','ROS')">View examples</a> for ROS Toolbox.

% Copyright 2013-2024 The MathWorks, Inc.
