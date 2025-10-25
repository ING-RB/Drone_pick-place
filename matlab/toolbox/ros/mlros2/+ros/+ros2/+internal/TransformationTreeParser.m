classdef (Abstract)TransformationTreeParser < handle
    %   Copyright 2023 The MathWorks, Inc.

    properties (Constant, Access = protected)
        %DefaultDynamicBroadcasterQoS - Default to declare depth qos setting
        DefaultDynamicBroadcasterQoS = struct('Depth',100)

        %DefaultStaticBroadcasterQoS - Default to declare depth and durability qos settings
        DefaultStaticBroadcasterQoS = struct('Depth',1,'Durability','transientlocal')

        %DefaultDynamicListenerQoS - Default to declare depth qos setting
        DefaultDynamicListenerQoS = struct('Depth',100)

        %DefaultStaticListenerQoS - Default to declare depth and durability qos settings
        DefaultStaticListenerQoS = struct('Depth',100,'Durability','transientlocal')
    end

    properties(Dependent, SetAccess = protected)
        DynamicBroadcasterQoS
        StaticBroadcasterQoS
        DynamicListenerQoS
        StaticListenerQoS
    end

    properties (Constant, Access = protected)
        %HistoryValues - Possible values for History property
        HistoryValues = {'keeplast', 'keepall'}

        %ReliabilityValues - Possible values for Reliability property
        ReliabilityValues = {'reliable', 'besteffort'}

        %DurabilityValues - Possible values for Durability property
        DurabilityValues = {'transientlocal', 'volatile'}

        %LivelinessValues
        LivelinessValues = {'automatic', 'default', 'manual'}
    end

    % All dependent properties are read from the server
    methods
        % All dependent properties are read from the server
        function dynamicBroadcasterQoS = get.DynamicBroadcasterQoS(obj)
            %get.History Custom getter for History property

            % Allow errors to be thrown from getServerInfo
            info = getServerInfo(obj);
            if info.dynamicBroadcasterQoS.qosdeadline==0
                info.dynamicBroadcasterQoS.qosdeadline=Inf;
            end
            if info.dynamicBroadcasterQoS.qoslifespan==0
                info.dynamicBroadcasterQoS.qoslifespan=Inf;
            end
            if info.dynamicBroadcasterQoS.qosleaseduration==0
                info.dynamicBroadcasterQoS.qosleaseduration=Inf;
            end
            dynamicBroadcasterQoS = obj.displayQoS(info.dynamicBroadcasterQoS);
        end

        function staticBroadcasterQoS = get.StaticBroadcasterQoS(obj)
            %get.Depth Custom getter for Depth property

            % Allow errors to be thrown from getServerInfo
            info = getServerInfo(obj);
            if info.staticBroadcasterQoS.qosdeadline==0
                info.staticBroadcasterQoS.qosdeadline=Inf;
            end
            if info.staticBroadcasterQoS.qoslifespan==0
                info.staticBroadcasterQoS.qoslifespan=Inf;
            end
            if info.staticBroadcasterQoS.qosleaseduration==0
                info.staticBroadcasterQoS.qosleaseduration=Inf;
            end
            staticBroadcasterQoS = obj.displayQoS(info.staticBroadcasterQoS);
        end

        function dynamicListenerQoS = get.DynamicListenerQoS(obj)
            %get.Reliability Custom getter for Reliability property

            % Allow errors to be thrown from getServerInfo
            info = getServerInfo(obj);
            if info.dynamicListenerQoS.qosdeadline==0
                info.dynamicListenerQoS.qosdeadline=Inf;
            end
            if info.dynamicListenerQoS.qoslifespan==0
                info.dynamicListenerQoS.qoslifespan=Inf;
            end
            if info.dynamicListenerQoS.qosleaseduration==0
                info.dynamicListenerQoS.qosleaseduration=Inf;
            end
            dynamicListenerQoS = obj.displayQoS(info.dynamicListenerQoS);
        end

        function staticListenerQoS = get.StaticListenerQoS(obj)
            %get.Durability Custom getter for Durability property

            % Allow errors to be thrown from getServerInfo
            info = getServerInfo(obj);
            if info.staticListenerQoS.qosdeadline==0
                info.staticListenerQoS.qosdeadline=Inf;
            end
            if info.staticListenerQoS.qoslifespan==0
                info.staticListenerQoS.qoslifespan=Inf;
            end
            if info.staticListenerQoS.qosleaseduration==0
                info.staticListenerQoS.qosleaseduration=Inf;
            end
            staticListenerQoS = obj.displayQoS(info.staticListenerQoS);
        end
    end

    methods (Access = protected)
        function [validTargetFrame, validSourceFrame, sourceTime, timeout] = ...
                parseGetTransformInput(obj, defaults, targetFrame, sourceFrame, varargin)
            %parseGetTransformInput Parse arguments for "getTransform" method
            %   The following syntaxes are valid:
            %   - getTransform('TARGETFRAME', 'SOURCEFRAME')
            %   - getTransform('TARGETFRAME', 'SOURCEFRAME', SOURCETIME)
            %   - getTransform('TARGETFRAME', 'SOURCEFRAME', 'Timeout', TIMEOUT)
            %   - getTransform('TARGETFRAME', 'SOURCEFRAME', SOURCETIME, 'Timeout', TIMEOUT)
            import ros.internal.Parsing.validateROS2Time;
            import ros.internal.Parsing.validateTimeout;

            % Convert all strings to character vectors
            if ~isempty(varargin)
                [varargin{:}] = convertStringsToChars(varargin{:});
            end

            if isfield(defaults, 'Timeout')
                % Parse "Timeout" name-value pair
                assert(length(varargin) <= 3);
            else
                % Only parse the (optional) source time input
                assert(length(varargin) <= 1);
                defaults.Timeout = 0;
            end

            % Validate frame names
            [validTargetFrame, validSourceFrame] = obj.validateTargetAndSourceFrame(targetFrame, sourceFrame, 'getTransform');

            switch length(varargin)
                case 0
                    % Syntax: getTransform('TARGETFRAME', 'SOURCEFRAME')
                    % Return defaults.
                    sourceTime = ros2time(defaults.SourceTime);
                    timeout = defaults.Timeout;

                case 1
                    % Syntax: getTransform('TARGETFRAME', 'SOURCEFRAME', SOURCETIME)
                    sourceTime = validateROS2Time(varargin{1}, 'getTransform', 'sourceTime');
                    timeout = defaults.Timeout;

                case 2
                    % Syntax: getTransform('TARGETFRAME', 'SOURCEFRAME', 'Timeout', TIMEOUT)
                    validatestring(varargin{1}, {'Timeout'}, 'getTransform', 'timeout');
                    sourceTime = ros2time(defaults.SourceTime);
                    timeout = validateTimeout(varargin{2}, 'getTransform', 'timeout');

                case 3
                    % Syntax: getTransform('TARGETFRAME', 'SOURCEFRAME', SOURCETIME, 'Timeout', TIMEOUT)
                    sourceTime = validateROS2Time(varargin{1}, 'getTransform', 'sourceTime');
                    validatestring(varargin{2}, {'Timeout'}, 'getTransform', 'timeout');
                    timeout = validateTimeout(varargin{3}, 'getTransform', 'timeout');
            end
        end

        function [validTargetFrame, validSourceFrame, sourceTime] = ...
                parseCanTransformInput(obj, defaultSourceTime, targetFrame, sourceFrame, varargin)
            %parseCanTransformInput Parse arguments for "canTransform" method
            %   The following syntaxes are valid:
            %   - canTransform('TARGETFRAME', 'SOURCEFRAME')
            %   - canTransform('TARGETFRAME', 'SOURCEFRAME', SOURCETIME)
            import ros.internal.Parsing.validateROS2Time;

            assert(length(varargin) <= 1);

            % Validate frame names
            [validTargetFrame, validSourceFrame] = obj.validateTargetAndSourceFrame(targetFrame, sourceFrame, 'canTransform');

            switch length(varargin)
                case 0
                    % Syntax: canTransform('TARGETFRAME', 'SOURCEFRAME')
                    % Return default
                    sourceTime = ros2time(defaultSourceTime);

                case 1
                    % Syntax: canTransform('TARGETFRAME', 'SOURCEFRAME', SOURCETIME)
                    sourceTime = validateROS2Time(varargin{1}, 'canTransform', 'sourceTime');
            end

        end

        function [validTargetFrame, validSourceFrame, msg, sourceTime] = ...
                parseTransformInput(obj, defaultSourceTime, targetFrame, msg, varargin)
            %parseTransformInput Parse arguments for "transform" method
            %   The following syntaxes are valid:
            %   - transform(tftree, targetFrame, msg)
            %   - transform(tftree, targetFrame, msg, 'msgtime')
            %   - transform(tftree, targetFrame, msg, sourceTime)
            import ros.internal.Parsing.validateROS2Time;

            assert(length(varargin) <= 1);

            % Validate message type. All message types have a header.
            msgType = {'geometry_msgs/QuaternionStamped', ...
                'geometry_msgs/Vector3Stamped', ...
                'geometry_msgs/PointStamped', ...
                'geometry_msgs/PoseStamped', ...
                'sensor_msgs/PointCloud2'};
            validateattributes(msg, {'struct'}, {'scalar'}, 'transform', 'msg')
            if ~isfield(msg, 'MessageType') || ~any(strcmp(msg.MessageType, msgType))
                if iscell(msgType)
                    msgType = strjoin(msgType, ', ');
                end
                error(message('ros:mlroscpp:message:InputTypeMismatch', msgType))
            end

            % Validate frame names
            sourceFrame = msg.header.frame_id;
            validTargetFrame = obj.validateFrame(targetFrame, 'transform', 'targetFrame');
            validSourceFrame = obj.validateFrame(sourceFrame, 'transform', 'msg.header.frame_id');

            % Convert all strings to character vectors
            if ~isempty(varargin)
                [varargin{:}] = convertStringsToChars(varargin{:});
            end

            switch length(varargin)
                case 0
                    % Syntax: transform(tftree, targetFrame, msg)
                    % Return default
                    sourceTime = ros2time(defaultSourceTime);

                case 1
                    % Syntax: transform(tftree, targetFrame, msg, 'msgtime')
                    %         transform(tftree, targetFrame, msg, sourceTime)

                    sourceTimeSpec = varargin{1};
                    validateattributes(sourceTimeSpec, ...
                        {'char', 'string', 'numeric', 'ros2time', 'struct'}, ...
                        {}, 'transform', 'sourceTime');

                    if ischar(sourceTimeSpec)
                        % Syntax: transform(tftree, targetFrame, msg, 'msgtime')
                        validatestring(sourceTimeSpec, {'msgtime'}, 'transform', 'sourceTime');
                        sourceTime = msg.header.stamp;
                    else
                        % Syntax: transform(tftree, targetFrame, msg, sourceTime)
                        sourceTime = varargin{1};
                    end
                    sourceTime = validateROS2Time(sourceTime, 'transform', 'sourceTime');
            end
        end

        function validBufferTime = parseBufferTime(~, bufferTime)
            %parseBufferTime Parse the input to the BufferTime setter

            validateattributes(bufferTime, {'numeric'}, {'nonempty', 'scalar', 'real', 'positive', ...
                'nonnan', 'finite', '<', ros.internal.Parsing.MaxTimeNumeric}, ...
                'ros2tf', 'BufferTime');

            validBufferTime = double(bufferTime);
        end

        function [validTargetFrame, validSourceFrame] = ...
                validateTargetAndSourceFrame(obj, targetFrame, sourceFrame, funcName)
            validTargetFrame = obj.validateFrame(targetFrame, funcName, 'targetFrame');
            validSourceFrame = obj.validateFrame(sourceFrame, funcName, 'sourceFrame');
        end

        function validFrameName = validateFrame(~, frameName, funcName, varName)
            %validateFrame Validate a frame name and return a name that is always valid
            %   This function will remove a leading slash (/) if it exists
            %   (consistent with ROS C++ and Python). If the frame name
            %   starts with two slashes, an error is displayed.

            % Filter out non-string, non-char input
            validateattributes(frameName, {'char','string'}, {'nonempty','scalartext'}, funcName, varName);

            frameNameChar = convertStringsToChars(frameName);
            validFrameName = regexprep(frameNameChar,'^/+','');
            
            % Verify again to avoid empty string after removing leading
            % slashes
            validateattributes(validFrameName, {'char','string'}, {'nonempty','scalartext'}, funcName, varName);

        end

        function [frameNameNoSlash, isStripped] = stripLeadingSlash(~, frameName)
            %stripLeadingSlash Remove the first slash, if it exists
            %   strncmp will return "false" if frameName is not a character
            %   vector.
            if strncmp(frameName, '/', 1)
                frameNameNoSlash = frameName(2:end);
                isStripped = true;
            else
                frameNameNoSlash = frameName;
                isStripped = false;
            end
        end

        function parser = addQOSToParser(obj, parser, className)
            %addQOSToParser Add QOS names and defaults to input parse
            % QOS settings empty by default to use ROS 2 defaults.
            % className is the name to be shown in error messages if the
            % arguments parsed are invalid.

            addParameter(parser, 'History', '', ...
                @(x) validateStringParameter(x, ...
                obj.HistoryValues, ...
                className, ...
                'History'))
            addParameter(parser, 'Depth', [], ...
                @(x) validateattributes(x, ...
                {'numeric'}, ...
                {'scalar', 'nonnegative', 'finite'}, ...
                className, ...
                'Depth'))
            addParameter(parser, 'Reliability', '', ...
                @(x) validateStringParameter(x, ...
                obj.ReliabilityValues, ...
                className, ...
                'Reliability'))
            addParameter(parser, 'Durability', '', ...
                @(x) validateStringParameter(x, ...
                obj.DurabilityValues, ...
                className, ...
                'Durability'))
            addParameter(parser,'Deadline',[], ...
                         @(x) validateattributes(x, ...
                                                 {'double'}, ...
                                                 {'scalar', 'positive', 'nonnan'}, ...
                                                 className, ...
                                                 'Deadline'))
            addParameter(parser,'Lifespan',[], ...
                         @(x) validateattributes(x, ...
                                                 {'double'}, ...
                                                 {'scalar', 'positive', 'nonnan'}, ...
                                                 className, ...
                                                 'Lifespan'))
            addParameter(parser, 'Liveliness', '', ...
                @(x) validateStringParameter(x, ...
                obj.LivelinessValues, ...
                className, ...
                'Liveliness'));
            addParameter(parser,'LeaseDuration',[], ...
                         @(x) validateattributes(x, ...
                                                 {'double'}, ...
                                                 {'scalar', 'positive', 'nonnan'}, ...
                                                 className, ...
                                                 'LeaseDuration'))
            addParameter(parser, 'AvoidROSNamespaceConventions', [], ...
                         @(x) validateattributes(x,{'logical'},{'nonempty'}, ...
                         className,'AvoidROSNamespaceConventions'))

            function validateStringParameter(value, options, className, name)
                % Separate function to suppress output and just validate
                validatestring(value, options, className, name);
            end
        end

        function qosSettings = getQosSettings(obj, qosInputs)
            %getQosSettings Handle input of possible QOS values
            %   Return a struct only containing explicitly set values, set as
            %   integers corresponding to the ROS 2 middleware enumerations

            % Non-existent fields in the QOS structure will result in
            % the default QOS setting values being used
            % validatestring has already guaranteed unique match with allowed
            % values, so now just needs index
            qosSettings = struct;
            if ~isempty(qosInputs.History)
                historyVal = char(qosInputs.History);
                historyIdx = find(strncmpi(historyVal, ...
                    obj.HistoryValues, ...
                    numel(historyVal)));
                qosSettings.history = int32(historyIdx);
            end
            if ~isempty(qosInputs.Depth)
                qosSettings.depth = uint64(qosInputs.Depth);
            end
            if ~isempty(qosInputs.Reliability)
                reliabilityVal = char(qosInputs.Reliability);
                reliabilityIdx = find(strncmpi(reliabilityVal, ...
                    obj.ReliabilityValues, ...
                    numel(reliabilityVal)));
                qosSettings.reliability = int32(reliabilityIdx);
            end
            if ~isempty(qosInputs.Durability)
                durabilityVal = char(qosInputs.Durability);
                durabilityIdx = find(strncmpi(durabilityVal, ...
                    obj.DurabilityValues, ...
                    numel(durabilityVal)));
                qosSettings.durability = int32(durabilityIdx);
            end
            if ~isempty(qosInputs.Deadline)
                qosSettings.deadline = qosInputs.Deadline;
            end
            if ~isempty(qosInputs.Lifespan)
                qosSettings.lifespan = qosInputs.Lifespan;
            end
            if ~isempty(qosInputs.Liveliness)
                livelinessVal = char(qosInputs.Liveliness);
                livelinessIdx = find(strncmpi(livelinessVal, ...
                                              obj.LivelinessValues, ...
                                              numel(livelinessVal)));
                qosSettings.liveliness = int32(livelinessIdx);
            end
            if ~isempty(qosInputs.LeaseDuration)
                qosSettings.leaseduration = qosInputs.LeaseDuration;
            end
            if ~isempty(qosInputs.AvoidROSNamespaceConventions)
                qosSettings.avoidrosnamespaceconventions = qosInputs.AvoidROSNamespaceConventions;
            end
        end

        function qosString = displayQoS(obj,structQoS)
            %displayQoS Return a string containing QoS name with field in a QoS struct.
            %No need to check the input struct since they have been verified during
            %object creation.

            qosString = sprintf(['History: %s, Depth: %d, Reliability: %s, Durability: %s, ' ...
                'Deadline: %f, Lifespan: %f, Liveliness: %s, Lease Duration: %f'], ...
                obj.HistoryValues{structQoS.qoshistory}, ...
                structQoS.qosdepth, ...
                obj.ReliabilityValues{structQoS.qosreliability}, ...
                obj.DurabilityValues{structQoS.qosdurability}, ...
                structQoS.qosdeadline, ...
                structQoS.qoslifespan, ...
                obj.LivelinessValues{structQoS.qosliveliness}, ...
                structQoS.qosleaseduration);
        end
    end

    methods (Abstract, Access = protected)
        %getServerInfo Retrieve object properties from the node server
        %   The output, INFO, must be a struct containing properties
        %   "DynamicBroadcasterQoS", "StaticBroadcasterQoS",
        %   "DynamicListenerQoS", and "StaticListenerQoS", with the
        %   corresponding value provided by the user. Validity of the
        %   values provided by the user ensured by addQOSToParser, if used
        %   with an inputParser.
        info = getServerInfo(obj)
    end
end
