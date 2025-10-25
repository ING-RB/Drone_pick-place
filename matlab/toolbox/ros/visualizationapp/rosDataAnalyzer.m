function rosDataAnalyzer
%ROSDATAANALYZER Visualize and annotate ROS and ROS 2 data
%   ROSDATAANALYZER launches the ROS Data Analyzer app to visualize and
%   annotate ROS and ROS 2 data from bag files and data published in live 
%   networks. It supports ROS bag file of .bag extension and ROS 2 bag file
%   of .db3 and .mcap extension. You can load all the files associated with
%   a ROS 2 bag folder by loading the metadata.yaml file. 
%   You can specify ros master URI for ros1 and ros domain ID for ros2 to
%   visualize live data published in a ros(2) network. 
%   You can create multiple visualizers within the app and view different
%   ROS messages simultaneously. The app supports these visualizers:
%       Image
%       Point Cloud
%       Laser Scan
%       Odometry
%       XY
%       Time Plot
%       Message
%
%   For each visualizer, you can filter the supported messages in the bag file
%   for visualization. You can fast forward, and rewind based on the message
%   timestamp or elapsed time while playing the bag file. You can also pause,
%   and play the bag frame-by-frame. The app also displays information about
%   the bag file contents after loading the bag file. You can also save a
%   snapshot of the visualization window at any particular instance of time.
%
%   Example:
%       % Launch the app
%       rosDataAnalyzer;
%
%   See also rosbagwriter, rosbagreader, ROSBAG, ros2bagreader,
%   ros2bagwriter, rospublisher, rossubscriber, ros2publisher,
%   ros2subscriber

%   Copyright 2023 The MathWorks, Inc.

ros.internal.RosDataAnalyzer;
end
