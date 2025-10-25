classdef Time < ros.internal.mixin.InternalAccess & ...
        robotics.core.internal.mixin.Unsaveable & handle
%This class is for internal use only. It may be removed in the future.

%Time Access ROS 2 time functionality
%   Normally, ROS 2 will use your computer's system clock as a time
%   source (system time). When you are connected to a robot simulation
%   or play back logged data, ROS 2 might publish time information on
%   the "/clock" topic (simulation time). The simulation time can be
%   accelerated or slowed in comparison to your system time.
%   The Time object gives you access to either the system or simulation
%   time, depending on your ROS 2 network configuration. This can be
%   used to timestamp messages or to measure time in the ROS 2 network.
%
%   TIMEOBJ = ros.internal.ros2.Time(NODE) returns a ROS 2 time object
%   TIMEOBJ for accessing time functionality. The object will be
%   attached to the ROS 2 node NODE. NODE cannot be empty.
%
%   Time properties:
%      CurrentTime       - (Read-Only) The current ROS 2 time
%      IsSimulationTime  - (Read-Only) Indicate if simulation time is used
%
%
%   Examples:
%       % Crreate a ROS 2 node
%       node = ros2node("/testTime");
%
%       % Create the time object given ROS 2 node as input
%       timeobj = ros.internal.ros2.Time(node);
%
%       % Get the current system or simulation time
%       timeobj.CurrentTime
%
%
%   See also ROS2TIME.

%   Copyright 2022-2024 The MathWorks, Inc.

    properties(Dependent, SetAccess = private)
        %CurrentTime - The current ROS 2 time
        %   This property will show the simulation time published on the
        %   "/clock" topic if the "/use_sim_time" ROS parameter is set to
        %   true. Otherwise, this will return the system time.
        CurrentTime

        %CurrentSystemTime - The current system time
        %   This property returns the system time.
        CurrentSystemTime
    end

    properties (Transient, SetAccess = private)
        %IsSimulationTime - Indicate if simulation time is used
        %   This property will be "true" if the "/use_sim_time" ROS parameter
        %   was set to true.
        IsSimulationTime = false
    end

    properties (Transient, Access = ?ros.internal.mixin.InternalAccess)
        %InternalNode - Internal representation of the node object
        %   Node required to get time information
        InternalNode = []

        %ServerNodeHandle - Designation of the node on the server
        %   Node handle required to get time information
        ServerNodeHandle = []
    end

    properties(Constant)
        MsgType = 'builtin_interfaces/Time';
    end

    methods
        function obj = Time(node)
        % node cannot be empty
            narginchk(1,1)
            validateattributes(node,{'ros2node'},{'scalar'}, ...
                               'ros.internal.ros2.Time','node');
            % Save the internal node information for later use
            obj.InternalNode = node.InternalNode;
            obj.ServerNodeHandle = node.ServerNodeHandle;
        end

        function currentTime = get.CurrentTime(obj)
        %get.CurrentTime Retrieve the current ROS 2 system time

            timeStruct = getCurrentTime(obj.InternalNode, ...
                                        obj.ServerNodeHandle, ...
                                        false);

            msgStruct.MessageType = obj.MsgType;
            msgStruct.sec = timeStruct.sec;
            msgStruct.nanosec = timeStruct.nsec;
            currentTime = msgStruct;
            obj.IsSimulationTime = timeStruct.issimtime;
        end

        function currentSystemTime = get.CurrentSystemTime(obj)
        %get.CurrentSystemTime Retrieve the current system time

            timeStruct = getCurrentTime(obj.InternalNode, ...
                                        obj.ServerNodeHandle, ...
                                        true);
            msgStruct.MessageType = obj.MsgType;
            msgStruct.sec = timeStruct.sec;
            msgStruct.nanosec = timeStruct.nsec;
            currentSystemTime = msgStruct;
        end

        function delete(obj)
            obj.InternalNode = [];
            obj.ServerNodeHandle = [];
        end
    end

    methods (Hidden)
        function isSimulationTime = IsUsingSimTime(obj)
            %IsUsingSimTime Returns IsSimulationTime as true if and only if the
            % /use_sim_time parameter was set to true for the node.
            timeStruct = getCurrentTime(obj.InternalNode, ...
                obj.ServerNodeHandle, ...
                false);
            obj.IsSimulationTime = timeStruct.issimtime;
            isSimulationTime = obj.IsSimulationTime;
        end
    end
end
