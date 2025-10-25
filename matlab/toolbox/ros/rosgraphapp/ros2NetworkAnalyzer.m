function ros2NetworkAnalyzer()
%ROS2NETWORKANALYZER Alalyze ros 2 network using this app
%
%   Example:
%       % Launch the app
%       ros2NetworkAnalyzer
%
%   See also ros2node, ros2publisher, ros2subscriber

%   Copyright 2024 The MathWorks, Inc.

    view = ros.internal.rosgraph.view.AppView;
    model = ros.internal.rosgraph.model.RosNetworkModel;
    ros.internal.rosgraph.presentor.AppPresentor.init(model,view)
end

