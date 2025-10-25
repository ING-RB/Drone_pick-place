function rosbagViewer
%ROSBAGVIEWER Visualize messages in ROS bag and ROS 2 bag file
%   ROSBAGVIEWER launches the Rosbag Viewer app to visualize messages in a
%   ROS bag and ROS 2 bag file. It supports ROS bag file of .bag extension
%   and ROS 2 bag file of .db3 extension. You can load all the files 
%   associated with a ROS 2 bag folder by loading the metadata.yaml file.
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
%       rosbagViewer;
%
%   See also rosbagwriter, rosbagreader, ROSBAG, ros2bagreader,
%   ros2bagwriter

%   Copyright 2022-2023 The MathWorks, Inc.

%For backward compatibility rosDataAnalyzer app will be opened when user
%enters this API.

ros.internal.RosDataAnalyzer;
end
