function varargout = ros2time(varargin)
%ROS2TIME Access ROS 2 time functionality
%   T = ROS2TIME returns a default ROS 2 time message. The properties for
%   seconds and nanoseconds are set to 0.
%
%   T = ROS2TIME(TOTALSECS) initializes the time values for seconds and
%   nanoseconds based on the TOTALSECS input. TOTALSECS represents the time
%   in seconds as a floating-point number.
%
%   T = ROS2TIME(SECS,NSECS) initializes the time values based on the SECS
%   (seconds) and NSECS (nanoseconds) inputs. Both inputs have to be
%   integer-values. Large values for NSECS are wrapped automatically and
%   the remainders are added to the value for SECS.
%
%   T = ROS2TIME(NODE,"now") returns the current ROS 2 time as a ROS 2 time
%   message T, using the specified ros2node object, NODE, as the source. If
%   the "/use_sim_time" ROS 2 parameter is set to true, this returns the
%   simulation time published on the "/clock" topic. Otherwise, the
%   function returns your machine's system time. If no output argument is
%   given, the current time (in seconds) is printed on the command window.
%
%   [T, ISSIMTIME] = ROS2TIME(NODE,"now") also returns a boolean ISSIMTIME
%   that indicates if T is simulation time (true) or system time (false).
%
%   T = ROS2TIME(NODE,"now","system") always returns your machine's system
%   time, even if ROS 2 publishes simulation time on the "/clock" topic. If
%   no output argument is given, the system time (in seconds) is printed to
%   the screen.
%
%   The system time in ROS follows the Unix / POSIX time standard. POSIX
%   time is defined as the time that has elapsed since 00:00:00 Coordinated
%   Universal Time (UTC), 1 January 1970, not counting leap seconds.
%
%   ROS2TIME can be used to timestamp messages or to measure time in the
%   ROS 2 network.
%
%   Example:
%
%      % Create time message from seconds and nanoseconds
%      t1 = ROS2TIME(1500,200000)
%
%      % Create time message from total seconds
%      t2 = ROS2TIME(500.14671)
%
%      % Show the current ROS time
%      node = ros2node("/testNode");
%      ROS2TIME(node,"now");
%
%      % Return the current time as a ROS 2 time message
%      t3 = ROS2TIME(node,"now")
%
%      % Timestamp message with current system time
%      point = ros2message("geometry_msgs/PointStamped");
%      point.header.stamp = ROS2TIME(node,"now","system");
%      point.point.x = 5;
%
%   See also ROS2DURATION.

%   Copyright 2022-2024 The MathWorks, Inc.
%#codegen
    coder.extrinsic('ros.codertarget.internal.getEmptyCodegenMsg');
    coder.inline('never');
    % Parse inputs
    coder.internal.narginchk(0,3,nargin);

    isTotalSecs = true;
    if nargin > 0
        % There is at least one argument. Decide which parser to use, based
        % on the data type.
        if isnumeric(varargin{1})
            % varargin{1} is seconds value
            sec = varargin{1};
            nsec = 0;
            if nargin > 1
                % varargin{2} exist and it is the nanoseconds value
                nsec = varargin{2};
                isTotalSecs = false;
            end
            validateattributes(nsec, {'numeric'}, {}, 'ros2time','nsecs');
            isNumericInput = true;
        elseif isa(varargin{1},'ros2node') 
            % varargin{1} must be a ros2node handle
            node = varargin{1};
            % varargin{2} must be provided and it has to be "now"
            % This is to remain parity with ROS 1. Besides, this is a
            % placeholder for future update on supporting other operations.
            coder.internal.assert(nargin>1, 'ros:mlros2:time:EmptyOperation', '"now"');
            operation = varargin{2};
            validatestring(operation,{'now'},'ros2time','operation');
            provider = '';
            if nargin > 2
                provider = convertStringsToChars(varargin{3});
                validatestring(provider,{'','system'},'ros2time','provider');
            end
            isNumericInput = false;
        else
            validateattributes(varargin{1},{'numeric','ros2node'},{'scalar'},'ros2time');
        end
    else
        % No input case is treated as sec = 0, nsec = 0
        sec = 0;
        nsec = 0;
        isNumericInput = true;
    end

    if isempty(coder.target)
        %% Interpreted mode
        if isNumericInput
            % Create a time message for return
            msgStruct.MessageType = 'builtin_interfaces/Time';
            % Parse seconds and nanoseconds and return the time message
            [sec, nsec] = validateTime(sec, nsec, isTotalSecs);
            msgStruct.sec = int32(sec);
            msgStruct.nanosec = uint32(nsec);
            varargout{1} = msgStruct;
            return;
        else
            % ros2time(node,"now",...
            isSystemTime = ~isempty(provider);
            if nargout == 0
                ros2timeImpl(node, isSystemTime);
            else
                [varargout{1:nargout}] = ros2timeImpl(node, isSystemTime);
            end
        end
    else
        %% Codegen mode
        % Create a time message for return
        msgStruct.MessageType = 'builtin_interfaces/Time';
        if isNumericInput
            %% ros2time(1,...)
            [sec, nsec] = validateTime(sec, nsec, isTotalSecs);
            msgStruct.sec = int32(sec);
            msgStruct.nanosec = uint32(nsec);
        else
            %% ros2time(node, 'now', ...)
            msgStruct.sec = int32(0);
            msgStruct.nanosec = uint32(0);
            srcFolder = ros.slros.internal.cgen.Constants.PredefinedCode.Location;
            coder.updateBuildInfo('addIncludePaths',srcFolder);
            coder.updateBuildInfo('addIncludeFiles','mlros2_time.h',srcFolder);
            coder.cinclude('mlros2_time.h');
            isSystemTime = ~isempty(provider);
            isSimTime = coder.nullcopy(false);
            isSimTime = coder.ceval('time2struct', coder.wref(msgStruct), isSystemTime);
        end
        if nargout > 0
            varargout{1} = msgStruct;
        end
        if nargout > 1
            varargout{2} = isSimTime;
        end
    end
end

function varargout = ros2timeImpl(node, isSystemTime)
%ros2timeImpl Actual implementation of ros2time functionality
%   This retrieves either system time or ROS time.

% The operation should be parsed and valid

    timeObj = ros.internal.ros2.Time(node);
    if isSystemTime
        % Return system time
        currentTime = timeObj.CurrentSystemTime;
    else
        % Let ROS 2 decide what time to return
        currentTime = timeObj.CurrentTime;
    end

    if nargout == 0
        printTime(currentTime)
        return
    end
    varargout{1} = currentTime;
    varargout{2} = ~isSystemTime && timeObj.IsSimulationTime;
end

function [sec, nsec] = validateTime(sec,nsec,isTotalSecs)
%validateTime Parse the numeric arguments provided by the user
%   Valid syntaxes:
%   - ROS2TIME(TOTALSECS)
%   - ROS2TIME(SECS,NSECS)

% We already ascertained that there are only 1 or 2 inputs
    if isTotalSecs
        % Syntax: ROS2TIME(TOTALSECS)
        % Parse the floating-point seconds.
        [sec,nsec] = ros.internal.Parsing.validateTotalSignedSeconds(sec,'ros2time','totalSecs');
    else
        % Syntax:
        % - ROS2TIME
        % - ROS2TIME(SECS,NSECS)
        % For ROS 2, it is allowed to have negative time since sec is int32
        % instead of uint32.
        sec = ros.internal.Parsing.validateSignedSeconds(sec,'ros2time','secs');

        % Parse the integer nanoseconds and take the overflow from
        % nanoseconds larger than 1e9 into seconds.
        [nsec, secOverflow] = ros.internal.Parsing.validateSignedNanoseconds(nsec,true,'ros2time','nsecs');
        sec = sec + secOverflow;

        % The resulting time needs to be within the valid time limits.
        % Otherwise, an overflow occurred and we should throw an error.
        coder.internal.assert(ros.internal.Parsing.isValidSignedSecsNsecs(sec,nsec), ...
                              'ros:mlros2:time:ResultTimeInvalid');
    end
end

function printTime(currentTime)
%printTime Print time (in seconds) to the console

    if isempty(currentTime)
        secs = 0;
    else
        secs = double(currentTime.sec) + double(currentTime.nanosec) / 1e9;
    end

    disp([num2str(secs) ' ' message('ros:mlros:time:CurrentTimeSeconds').getString]);
end
