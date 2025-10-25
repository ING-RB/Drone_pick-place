function duration  = ros2duration(varargin)
%ROS2DURATION Create a ROS 2 duration message
%   D = ROS2DURATION returns a default ROS 2 duration message. The
%   properties for seconds and nanoseconds are set to 0.
%
%   D = ROS2DURATION(TOTALSECS) initializes the time values for seconds and
%   nanoseconds based on the TOTALSECS input. TOTALSECS represents the time
%   in seconds as a floating-point number.
%
%   D = ROS2DURATION(SECS,NSECS) initializes the time values based on the
%   SECS (seconds) and NSECS (nanoseconds) inputs. Both inputs have to be
%   integer-values. Large values for NSECS are wrapped automatically and
%   the remainders are added to the value for SECS.
%
%   Example:
%
%      % Create duration message from seconds and nanoseconds
%      d1 = ROS2DURATION(200,100000)
%
%      % Create duration message for total seconds
%      d2 = ROS2DURATION(500.14671)
%
%      % Add the duration to a time
%      node = ros2node("/test");
%      t1 = ros2time(node,"now","system");
%      t2 = ros2time(t1.sec+d2.sec,t1.nanosec+d2.nanosec);
%
%   See also ROS2TIME.

%   Copyright 2022 The MathWorks, Inc.
%#codegen

    coder.internal.narginchk(0,2,nargin);
    if nargin < 1
        % Syntax: ROS2DURATION
        sec = 0;
        nsec = 0;
    elseif nargin < 2
        % Syntax: ROS2DURATION(TOTALSEC)
        [sec,nsec] = ros.internal.Parsing.validateTotalSignedSeconds(varargin{1},'ros2duration','totalSecs');
    else
        % Syntax: ROS2DURATION(SECS,NSECS)
        % Parse the integer seconds
        sec = ros.internal.Parsing.validateSignedSeconds(varargin{1},'ros2duration','secs');

        % Parse the integer nanoseconds and take the overflow from
        % nanoseconds larger than 1e9 into seconds.
        [nsec, secOverflow] = ros.internal.Parsing.validateSignedNanoseconds(varargin{2},true,'ros2duration','nsecs');
        sec = sec + secOverflow;

        % The resulting time needs to be within the valid time limits.
        % Otherwise, an overflow occurred and we should throw an error.
        coder.internal.assert(ros.internal.Parsing.isValidSignedSecsNsecs(sec,nsec), ...
                              'ros:mlros2:duration:ResultDurationInvalid');
    end

    % Generate duration message
    duration = ros2message('builtin_interfaces/Duration');
    duration.sec = int32(sec);
    duration.nanosec = uint32(nsec);
end
