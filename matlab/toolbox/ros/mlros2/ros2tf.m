classdef ros2tf < ros.ros2.internal.TransformationTreeParser &...
        ros.internal.mixin.InternalAccess & ...
        robotics.core.internal.mixin.Unsaveable & handle
    %ros2tf  Receive, send, and apply ROS 2 transformations
    %   ROS 2 uses the tf2_ros transformation library to keep track of the relationship
    %   between multiple coordinate frames. The relative transformations between
    %   these coordinate frames are maintained in a tree structure. Querying
    %   this tree lets you transform messages like poses and points between any two
    %   coordinate frames.
    %
    %   The transformation tree changes over time and by default transformations
    %   are buffered for up to 10 seconds. You can access transformations at
    %   any time in this buffer window and the result will be interpolated to the
    %   exact time you specify.
    %
    %   TFTREE = ros2tf(NODE) creates a ROS 2 transformation
    %   tree object TFTREE. NODE is the ros2node object handle that
    %   the transformation tree should attach to.
    %   You can receive transformations and apply them to different stamped messages.
    %   You can also send static and dynamic transformations to share them with the rest of the ROS network.
    %
    %   TFTREE = ros2tf(___,Name,Value) provides additional options
    %   specified by one or more Name,Value pair arguments. You can specify several
    %   name-value pair arguments in any order as Name1,Value1,...,NameN,ValueN:
    %
    %      "DynamicBroadcasterQoS" - Quality of service settings to be declared for the dynamic
    %                                transform broadcaster while creating transformation tree.
    %                                Specify a structure containing QoS settings such as
    %                                History, Depth, Reliabilityand Durability. These QoS settings are
    %                                used by the TransformBroadCaster of tf2_ros, while broadcasting
    %                                tf2_msgs/TFMessage onto /tf topic.
    %
    %      "StaticBroadcasterQoS" -  Quality of service settings to be declared for the static
    %                                transform broadcaster while creating transformation tree.
    %                                Specify a structure containing QoS settings such as
    %                                History, Depth, Reliability and Durability. These QoS settings are
    %                                used by the StaticTransformBroadCaster of tf2_ros, while broadcasting
    %                                tf2_msgs/TFMessage onto /tf_static topic.
    %
    %      "DynamicListenerQoS"   -  Quality of service settings to be declared for the dynamic
    %                                transform listener while creating transformation tree.
    %                                Specify a structure containing QoS settings such as
    %                                History, Depth, Reliabilityand Durability. These QoS settings
    %                                are used by the TransformListener of tf2_ros, while listening
    %                                to tf2_msgs/TFMessage onto /tf topic.
    %
    %      "StaticListenerQoS"    -  Quality of service settings to be declared for the static
    %                                transform listener while creating transformation tree.
    %                                Specify a structure containing QoS settings such as
    %                                History, Depth, Reliability and Durability.These QoS settings
    %                                are used by the TransformListener of tf2_ros, while listening
    %                                to tf2_msgs/TFMessage onto /tf_static topic.
    %
    %   ros2tf properties:
    %      AvailableFrames        - (Read-only) List of all available coordinate frames
    %      LastUpdateTime         - (Read-only) Time when the last transform was received
    %      BufferTime             - Time (in seconds) for which transformations are buffered
    %      DynamicBroadcasterQoS  - (Read-only) broadcaster QoS settings for dynamic transforms
    %      StaticBroadcasterQoS   - (Read-only) broadcaster QoS settings for static transforms
    %      DynamicListenerQoS     - (Read-Only) listener QoS settings for dynamic transforms
    %      StaticListenerQoS      - (Read-Only) listener QoS settings for static transforms
    %
    %   ros2tf methods:
    %      getTransform       - Return the transformation between two coordinate frames
    %      canTransform       - Verify if transformation is available
    %      transform          - Transform stamped messages into target coordinate frame
    %      sendTransform      - Send a static or dynamic transform to the ROS 2 network
    %
    %   Example:
    %
    %       % This example assumes that some ROS 2 node publishes
    %       % transformations between base_link and camera_depth_frame.
    %       % For example, a real or simulated TurtleBot would do that.
    %
    %        % Create a ROS 2 node on domain id 25.
    %        node = ros2node("/testTf",25);
    %
    %        % Retrieve the transformation tree object
    %        tftree = ros2tf(node)
    %
    %        % Retrieve the transformation tree object by applying QoS settings
    %        % for sending or retrieving dynamic transformations.
    %        tftree = ros2tf(node,...
    %                        "DynamicBroadcasterQoS", struct('Depth', 50), ...
    %                        "DynamicListenerQoS", struct('Reliability','besteffort'), ...
    %                        "StaticBroadcasterQoS", struct('Depth',10), ...
    %                        "StaticListenerQoS", struct('Durability','volatile'))
    %
    %        % Buffer transformations for up to 15 seconds
    %        tftree.BufferTime = 15
    %
    %        % Wait for the transform that takes data from "camera_depth_frame"
    %        % to "base_link". This is blocking until the
    %        % transformation is valid.
    %        tform = getTransform(tftree,"base_link","camera_depth_frame","Timeout",Inf)
    %
    %        % Define a point [3 1.5 0.2] in the camera's coordinate frame
    %        pt = ros2message("geometry_msgs/PointStamped");
    %        pt.header.frame_id = 'camera_depth_frame';
    %        pt.point.x = 3;
    %        pt.point.y = 1.5;
    %        pt.point.z = 0.2;
    %
    %        % Transformation is available, so transform the point into the "base_link" frame
    %        tfPt = transform(tftree,"base_link",pt)
    %
    %        % Display the transformed point coordinates
    %        tfPt.point
    %
    %        % Get the transformation that was valid 1 second ago. Wait for up to
    %        % 2 seconds for the transformation to become available.
    %        sourceTime = ros2time(node,"now");
    %        sourceTime.sec = sourceTime.sec - 1;
    %        tform = getTransform(tftree,"base_link","camera_depth_frame",sourceTime,"Timeout",2)
    %
    %        % Apply the new transformation to the point
    %        tfPt2 = rosApplyTransform(tform,pt)
    %
    %   See also ROS2TF.

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties (Dependent, SetAccess = private)
        %AvailableFrames - List of all available coordinate frames
        %   The list of all coordinate frames in the transformation tree
        %   is returned as a cell array of strings. It is empty
        %   if no frames are in the tree.
        AvailableFrames

        %LastUpdateTime - Time when the last transform was received
        %   The time is returned as a ros2time object. It
        %   is empty if no transforms have been received yet.
        LastUpdateTime
    end

    properties (Dependent)
        %BufferTime - Time (in seconds) for which transformations are buffered
        %   If you change the buffer time from its current value,
        %   the transformation tree and all transformations are
        %   re-initialized.
        %   By default, the buffer length is 10 seconds.
        BufferTime
    end

    properties (Constant, Access = ?matlab.unittest.TestCase)
        %DefaultBufferTime - The default buffer time (in seconds)
        DefaultBufferTime = 10

    end

    properties (Constant, Access = ?ros.internal.mixin.InternalAccess)
        MessageType = 'tf2_msgs/TFMessage';
    end

    properties (Access = private)
        %TfTopicType - The message type of the /tf topic
        TfTopicType

        %TfStaticTopicType - The message type of the /tf_static topic
        TfStaticTopicType
    end

    properties (Transient, Access = ?matlab.unittest.TestCase)
        %InternalNode - Internal representation of the node object
        %   Node required to attach the tfTree
        InternalNode = []

        %ServerNodeHandle - Designation of the node on the server
        %   Node handle required to get tfTree property information
        ServerNodeHandle = []

        %TfHandle - TransformationHandle , Internal representation of
        %   TfTree. Required to call appropriate backend APIs
        TfHandle = []

        %MessageInfo - includes other information for a given message
        MessageInfo = struct.empty
    end

    methods
        function obj = ros2tf(node, varargin)
            %ros2tf Construct a ros2tf transformation tree object

            narginchk(1, inf)
            % Validate that node is a ros2node object
            validateattributes(node, {'ros2node'}, {'scalar', 'nonempty'}, ...
                'ros2tf', 'node', 1);

            % parse name-value pairs
            [paramNameParser, paramStructParser] = getParsers(obj);
            parse(paramNameParser, varargin{:})

            fs = fieldnames(paramNameParser.Results);
            % length must be greater than 0
            fslen = length(fs);
            for i = 1:fslen
                parse(paramStructParser, paramNameParser.Results.(fs{i}));
                % Handle quality of service settings
                fs{i} = getQosSettings(obj, paramStructParser.Results);
            end

            % Handle quality of service settings
            qosSettings = struct('dynamicBroadcasterQos', fs{1}, ...
                'staticBroadcasterQos', fs{3}, ...
                'dynamicListenerQos', fs{2}, ...
                'staticListenerQos', fs{4});

            % Set info based on the message
            setupInfo(obj);

            dllPaths = ros.internal.utilities.getPathOfDependentDlls(obj.MessageType,'ros2');
            returnCall = createTfTree(node.InternalNode, ...
                node.ServerNodeHandle, ...
                obj.MessageInfo.cppFactoryClass, ...
                obj.MessageInfo.cppElementType, ...
                dllPaths, ...
                qosSettings);
            if isempty(returnCall) || ~isstruct(returnCall)
                error(message('ros:mlros2:node:InvalidReturnCallError'))
            elseif ~isfield(returnCall, 'handle') || ...
                    isempty(returnCall.handle)
                error(message('ros:mlros2:node:InvalidReturnCallHandleError'))
            end
            obj.TfHandle = returnCall.handle;
            obj.InternalNode = node.InternalNode;
            obj.ServerNodeHandle = node.ServerNodeHandle;

            node.ListofNodeDependentHandles{end+1} = matlab.internal.WeakHandle(obj);

            % Get topic type of /tf. Default to tf2_msgs/TFMessage if topic does not exist.
            obj.TfTopicType = obj.retrieveTopicType(node, obj.MessageType,'/tf');
            % Get topic type of /tf_static. Default to tf2_msgs/TFMessage if topic does not exist.
            obj.TfStaticTopicType = obj.retrieveTopicType(node, obj.MessageType,'/tf_static');

            function [paramNameParser, paramStructParser] = getParsers(obj)
                % Set up parser
                paramNameParser = inputParser;
                addParameter(paramNameParser,'DynamicBroadcasterQoS', obj.DefaultDynamicBroadcasterQoS, ...
                    @(x) validateattributes(x, ...
                    {'struct'}, ...
                    {'nonempty','scalar'}, ...
                    'ros2tf', ...
                    'DynamicBroadcasterQoS'))
                addParameter(paramNameParser,'StaticBroadcasterQoS', obj.DefaultStaticBroadcasterQoS, ...
                    @(x) validateattributes(x, ...
                    {'struct'}, ...
                    {'nonempty','scalar'}, ...
                    'ros2tf', ...
                    'StaticBroadcasterQoS'))
                addParameter(paramNameParser,'DynamicListenerQoS', obj.DefaultDynamicListenerQoS, ...
                    @(x) validateattributes(x, ...
                    {'struct'}, ...
                    {'nonempty','scalar'}, ...
                    'ros2tf', ...
                    'DynamicListenerQoS'))
                addParameter(paramNameParser,'StaticListenerQoS', obj.DefaultStaticListenerQoS, ...
                    @(x) validateattributes(x, ...
                    {'struct'}, ...
                    {'nonempty','scalar'}, ...
                    'ros2tf', ...
                    'StaticListenerQoS'))

                paramStructParser = inputParser;
                paramStructParser = addQOSToParser(obj,paramStructParser,'ros2tf');
            end
        end

        function tform = getTransform(obj, targetFrame, sourceFrame, varargin)
            %getTransform Return the transformation between two coordinate frames
            %   TF = getTransform(OBJ,TARGETFRAME,SOURCEFRAME) gets and
            %   returns the latest known transformation between two coordinate frames.
            %   TF represents the transformation that takes coordinates
            %   in the SOURCEFRAME into the corresponding coordinates in
            %   the TARGETFRAME. The return TF is empty if this transformation does not
            %   exist in the tree.
            %
            %   TF = getTransform(OBJ,TARGETFRAME,SOURCEFRAME,SOURCETIME)
            %   returns the transformation at the time SOURCETIME. An error
            %   is displayed if the transformation at that time is not
            %   available.
            %
            %   TF = getTransform(___,Name,Value) provides additional options
            %   specified by one or more Name,Value pair arguments. You can
            %   specify several name-value pair arguments in any order as
            %   Name1,Value1,...,NameN,ValueN:
            %
            %      "Timeout"  -  Specifies a timeout period, in seconds.
            %                    If the transformation does not become
            %                    available within the specified period,
            %                    getTransform displays an error message.
            %                    The default value is 0, so that
            %                    getTransform does not wait at all, but
            %                    checks if the transformation is available
            %                    instantly.
            %   If the transformation does not become available and the
            %   timeout period elapses, getTransform displays an error
            %   message and lets MATLAB continue running the current program.
            %
            %   To unblock getTransform and let MATLAB continue running
            %   the program, you can press Ctrl+C at any time.
            %
            %   You can transform messages like point clouds and
            %   vectors directly by calling the "transform" function.
            %
            %   If only TARGETFRAME and SOURCEFRAME are specified
            %   and the transformation is not available, getTransform will
            %   display an error. To check if a
            %   transformation is available, use canTransform.
            %
            %   Example:
            %
            %        % Create the ros2tf object
            %        node = ros2node("tfNode")
            %        tftree = ros2tf(node)
            %
            %        % Wait for the transform that takes data from "base_link"
            %        % to "odom". This calls is blocking until the transformation is available.
            %        tform = getTransform(tftree,"odom","base_link","Timeout",Inf)
            %
            %        % Get the transformation that was valid 3 second ago.
            %        tform = getTransform(tftree,"odom","base_link",ros2time(now).sec - 3)
            %
            %        % Wait for a transformation that is valid a few seconds in the future.
            %        % Use a timeout to wait until the transformation becomes available.
            %        tform = getTransform(tftree,"odom","base_link",ros2time(now).sec + 1,"Timeout",5)
            %
            %   See also canTransform, TRANSFORM.

            narginchk(3,6);
            defaults = struct(...
                'Timeout', 0, ...
                'SourceTime', 0);
            [targetFrame, sourceFrame, sourceTime, timeout] = ...
                obj.parseGetTransformInput(defaults, targetFrame, sourceFrame, varargin{:});

            errorCode = 0;

            try
                % Wait until the end of the timeout
                util = ros.internal.Util.getInstance;
                util.waitUntilTrue( @() canTransform(obj, targetFrame, sourceFrame, ...
                    sourceTime), timeout );
            catch ex
                if ~strcmp(ex.identifier, 'ros:mlros:util:WaitTimeout')
                    % Rethrow exception if an unexpected exception is seen
                    rethrow(ex);
                elseif timeout > 0
                    error(message('ros:mlros:tf:WaitTimeout', num2str(timeout)));
                end
            end

            try
                % If Transform is available, no need to wait again. So
                % the timeout sec = 0 and nanosec = 0 sent to backend.
                tform = lookupTransform(obj.InternalNode, obj.TfHandle, ...
                    targetFrame, sourceFrame, sourceTime.sec, sourceTime.nanosec, 0, 0);
            catch ex
                if isequal(ex.identifier, 'ros:internal:transport:TFConnectivityException')
                    errorCode = 1;
                elseif isequal(ex.identifier, 'ros:internal:transport:TFExtrapolationException')
                    errorCode = 2;
                elseif isequal(ex.identifier, 'ros:internal:transport:TFLookupException')
                    errorCode = 3;
                elseif isequal(ex.identifier, 'ros:internal:transport:TFInvalidArgumentException')
                    errorCode = 4;
                end
            end
            % Handle error accordingly
            obj.handleErrorCode(errorCode,targetFrame,sourceFrame,sourceTime);
        end

        function isTransformAvailable = canTransform(obj, targetFrame, sourceFrame, varargin)
            %canTransform Verify if transformation is available
            %   ISAVAILABLE = canTransform(OBJ,TARGETFRAME,SOURCEFRAME)
            %   verifies if a transformation that takes coordinates
            %   in the SOURCEFRAME into the corresponding coordinates in
            %   the TARGETFRAME is available. ISAVAILABLE is TRUE if that
            %   transformation is available and FALSE otherwise.
            %   Use getTransform to retrieve the transformation.
            %
            %   ISAVAILABLE = canTransform(OBJ,TARGETFRAME,SOURCEFRAME,SOURCETIME)
            %   verifies that the transformation is available for the time
            %   SOURCETIME. If SOURCETIME is outside of the buffer window
            %   for the transformation tree, the function returns FALSE.
            %   Use getTransform with the SOURCETIME argument to retrieve
            %   the transformation.

            narginchk(3,4);

            defaultSourceTime = 0;
            [targetFrame, sourceFrame, sourceTime] = ...
                obj.parseCanTransformInput(defaultSourceTime, targetFrame, sourceFrame, varargin{:});

            % Appropriate error is being thrown from backend in case of
            % failure of the MCOS function call.
            returnCall = canTransform(obj.InternalNode, obj.TfHandle, ...
                targetFrame, sourceFrame, sourceTime.sec, sourceTime.nanosec, 0, 0);

            if isempty(returnCall) || ~isstruct(returnCall) || ...
                    ~isfield(returnCall, 'res') || isempty(returnCall.res)
                error(message('ros:mlros2:node:InvalidReturnCallError'))
            end

            isTransformAvailable = returnCall.res;
        end

        function sendTransform(obj, tf, varargin)
            %sendTransform - Send a transform to the ROS network
            %   sendTransform(OBJ,TF) broadcasts a transform TF to the
            %   ROS 2 network. TF is a scalar message or a message list of type
            %   geometry_msgs/TransformStamped.

            % Accept vector input and validate first message for type
            validateattributes(tf, {'struct'}, ...
                {'vector', 'nonempty'}, ...
                'sendTransform', 'tf');

            msgType = 'geometry_msgs/TransformStamped';
            validateattributes(tf(1), {'struct'}, {'scalar'}, 'sendTransform', 'tf(1)')
            if ~isfield(tf(1), 'MessageType') ...
                    || ~any(strcmp(tf(1).MessageType, msgType))
                if iscell(msgType)
                    msgType = strjoin(msgType, ', ');
                end
                error(message('ros:mlroscpp:message:InputTypeMismatch', msgType))
            end

            defaultValForStatic = false;
            parser = inputParser;
            addParameter(parser, 'UseStatic', defaultValForStatic, ...
                @(x) validateattributes(x, {'logical'}, {}, ...
                'sendTransform',...
                'UseStatic'));
            % Parse the input and assign outputs
            parse(parser, varargin{:});
            useStaticTf = parser.Results.UseStatic;

            % Check for invalid-quaternation
            for i = 1:numel(tf)
                tf(i) = handleInvalidQuaternation(obj, tf(i));
            end

            if useStaticTf
                % broadcasts a transform TF to the ROS 2 network on topic /tf_static.
                sendStaticTransform(obj.InternalNode, obj.TfHandle, tf);
            else
                % Back-end takes care of both scalar case and a list of messages.
                % broadcasts a transform TF to the ROS 2 network on topic /tf.
                sendTransform(obj.InternalNode, obj.TfHandle, tf);
            end
        end

        function tfEntity = transform(obj, targetFrame, msg, varargin)
            %TRANSFORM Transform stamped messages into target coordinate frame
            %   TFMSG = TRANSFORM(OBJ,TARGETFRAME,MSG) retrieves the
            %   latest transformation that takes data from the MSG's coordinate
            %   frame to the TARGETFRAME. The transformation is then applied
            %   to the data in MSG. MSG is a ROS 2 message of a specific type
            %   and the transformed message is returned in TFMSG. An error
            %   is displayed if the transformation does not exist.
            %
            %   TFMSG = TRANSFORM(OBJ,TARGETFRAME,MSG,"msgtime")
            %   uses the timestamp in the header of MSG as source time
            %   to retrieve and apply the transformation.
            %
            %   TFMSG = TRANSFORM(OBJ,TARGETFRAME,MSG,SOURCETIME)
            %   uses the time SOURCETIME to retrieve and apply the
            %   transformation to the MSG.
            %
            %   This function determines the type of the input message
            %   MSG and apply the appropriate transformation method. If a
            %   particular message type cannot be handled by this object,
            %   an error is displayed.
            %
            %   Supported message types include:
            %    - geometry_msgs/QuaternionStamped
            %    - geometry_msgs/Vector3Stamped
            %    - geometry_msgs/PointStamped
            %    - geometry_msgs/PoseStamped
            %    - sensor_msgs/PointCloud2
            %
            %   Example:
            %
            %      % Define a point [3 1.5 0.2] in the camera's coordinate frame
            %      pt = ros2message("geometry_msgs/PointStamped");
            %      pt.Header.FrameId = 'camera_depth_frame';
            %      pt.point.x = 3;
            %      pt.point.y = 1.5;
            %      pt.point.z = 0.2;
            %
            %      % Transform the point into the "base_link" frame
            %      % This assumes that the transformation between "base_link"
            %      % and "camera_depth_frame" is available.
            %      tfPt = transform(tftree,"base_link",pt)
            %
            %      % You can also transform an unstamped point by wrapping
            %      % it into a stamped message
            %      ptUnstamped = ros2message("geometry_msgs/Point");
            %      ptUnstamped.point.x = -7.8;
            %      pt.point = ptUnstamped;
            %
            %      tfPtUnstamped = transform(tftree,"base_link",pt)
            %
            %   See also getTransform.

            defaultSourceTime = 0;
            [targetFrame, sourceFrame, msg, sourceTime] = ...
                obj.parseTransformInput(defaultSourceTime, targetFrame, msg, varargin{:});

            % Lookup the transformation based on the given target frame and
            % the source frame in the message.
            tf = obj.getTransform(targetFrame, sourceFrame, sourceTime);

            % We have a valid transformation. Apply it to the input.
            th = ros.internal.ros2.TransformHelper(tf);
            tfEntity = th.transform(msg);
        end
    end

    methods
        function frameNames = get.AvailableFrames(obj)
            %get.AvailableFrames Retrieve all frame names in the tree

            % Retrieve all names from ROS node
            frames = availableFrames(obj.InternalNode, obj.TfHandle)';

            % Convert list to MATLAB cell array of strings and
            % remove all duplicates. The resulting list is sorted.
            frameNames = unique(frames);
        end

        function updateTime = get.LastUpdateTime(obj)
            %get.LastUpdateTime Retrieve last time the tree was updated

            time = lastUpdateTime(obj.InternalNode, obj.TfHandle);

            if isempty(time) || (isequal(time.sec, 0) && isequal(time.nanosec, 0))
                updateTime = struct.empty(0, 1);
            else
                updateTime = ros2time(time.sec, time.nanosec);
            end
        end

        function bufferTime = get.BufferTime(obj)
            %get.BufferTime Retrieve the current length of the buffer

            cacheTime = getCacheTime(obj.InternalNode, obj.TfHandle);
            bufferTime = double(cacheTime.sec)+1e-9*double(cacheTime.nanosec);
        end

        function set.BufferTime(obj, bufferTime)
            %set.BufferTime Set the length of the buffer

            validBufferTime = obj.parseBufferTime(bufferTime);
            bufferRos2Time = ros2time(validBufferTime);

            % Only re-initialize transformation tree if requested time is
            % different from the current buffer time
            currentBufferTime = getCacheTime(obj.InternalNode, obj.TfHandle);
            currentRos2Time = ros2time(currentBufferTime.sec,currentBufferTime.nanosec);

            if ~isequal(bufferRos2Time,currentRos2Time)
                setCacheTime(obj.InternalNode, obj.TfHandle, ...
                    bufferRos2Time.sec, bufferRos2Time.nanosec);
            end
        end
    end

    methods (Static, Access = ?matlab.unittest.TestCase)
        function tfType = retrieveTopicType(node, defaultType,topicName)
            %retrieveTopicType Retrieve and return the message type of tf
            %   and tf_static topic. They have the message type as tf2_msgs/TFMessage.
            %
            %   This function determines what message type the /tf and /tf_static topic
            %   has and returns it in TFTYPE. If the tf topics does not exist, the
            %   default message type DEFAULTTYPE is returned.

            tfType = defaultType;
            % Resolve the topic name based on the node
            resolvedTopic = resolveName(node, topicName);

            try
                tfType = ros.ros2.internal.NetworkIntrospection.getTypeFromTopicWithNode(...
                    node, ...
                    resolvedTopic);
            catch
                % No need to throw an exception here. Just return the
                % default
                return;
            end

            % Check tfType for validity
            if ~ismember(tfType, {'tf2_msgs/TFMessage'})
                error(message('ros:mlros2:tf:TfTypeNotValid', topicName, tfType, 'tf2_msgs/TFMessage'));
            end
        end
    end

    methods (Access = private)
        function setupInfo(obj)
            %setupInfo Set info based on the message type

            obj.MessageInfo = ros.internal.ros2.getMessageInfo('geometry_msgs/TransformStamped');
            [obj.MessageInfo.cppFactoryClass , obj.MessageInfo.cppElementType] = ...
                ros.internal.ros2.getCPPFactoryClassAndType('geometry_msgs/TransformStamped');
        end

        function handleErrorCode(obj, errorCode, targetFrame, sourceFrame, sourceTime)
            %handleErrorCode Handle the error code returned by lookupTransform
            %   Display an appropriate error message.

            switch errorCode
                case 0
                    % errorCode 0 is not an error condition
                    return;
                case 1
                    % errorCode 1 means the frames are not connected in the
                    % tree. They are in unconnected sub-graphs of the tree.
                    error(message('ros:mlros2:tf:FramesNotConnected', targetFrame, sourceFrame));
                case 2
                    % errorCode 2 means the transformation is outside the current buffer window
                    % The time could be in the future or it could be
                    % further in the past than the start of the buffer
                    % window
                    error(message('ros:mlros2:tf:SourceTimeOutsideBuffer', targetFrame, sourceFrame, ...
                        sprintf('%d:%d', sourceTime.sec, sourceTime.nanosec)));
                case 3
                    % errorCode 3 means that one (or both) of the frames is not in the buffer
                    % Give the user a concrete error message which case
                    % applies.
                    frameName = '';
                    isTargetValid = ismember(targetFrame,obj.AvailableFrames);
                    isSourceValid = ismember(sourceFrame,obj.AvailableFrames);

                    if ~isTargetValid && ~isSourceValid
                        % Both frame names are invalid
                        error(message('ros:mlros:tf:BothFrameNamesNotFound', targetFrame, sourceFrame));
                    end

                    % Only one frame name is invalid. Find out which one.
                    if ~isTargetValid
                        frameName = targetFrame;
                    elseif ~isSourceValid
                        frameName = sourceFrame;
                    end

                    if isempty(frameName)
                        % Frames exist but not connected.
                        obj.handleErrorCode(1,targetFrame,sourceFrame,sourceTime);
                    else
                        error(message('ros:mlros:tf:FrameNameNotFound', frameName));
                    end
                otherwise
                    % errorCode 4 means some other error occurred
                    error(message('ros:mlros:tf:NoValidTransformation', targetFrame, sourceFrame));
            end
        end

        function tf = handleInvalidQuaternation(~, tf)
            % Check if a rotation quaternion in a transformation is invalid.
            % A quaternion is invalid if its L2 norm is 0 or very close to
            % zero. Taking the inverse of such a quaternion leads to invalid
            % results. In that case, use the unit quaternion
            %See g1228205.

            normThresh = 1e-7;
            rot = tf.transform.rotation;
            quatNorm =  sqrt(rot.x^2 + rot.y^2 + rot.z^2 + rot.w^2);
            if quatNorm < normThresh
                rot.x = 0;
                rot.y = 0;
                rot.z = 0;
                rot.w = 1;
                tf.transform.rotation = rot;

                % display warning
                warning(message('ros:mlros2:tf:InvalidQuaternion', ...
                    tf.header.frame_id, tf.child_frame_id));
            end
        end
    end

    methods (Access = {?robotics.core.internal.mixin.Unsaveable, ?matlab.unittest.TestCase})
        function delete(obj)
            %DELETE Delete the ros2tf object
            %   Please note that this function is private to avoid explicit
            %   invocations.

            try
                % Only try to shut down if tree created
                if ~isempty(obj.InternalNode) && ...
                        isvalid(obj.InternalNode) && ...
                        ~isempty(obj.TfHandle)
                    deleteTfTree(obj.InternalNode, obj.TfHandle);
                end
                obj.InternalNode = [];
            catch
                warning(message('ros:mlros:tf:ShutdownError'));
            end
        end
    end

    methods (Access = protected)
        function tfTreeInfo = getServerInfo(obj)
            %getServerInfo Get Tftree properties from node server

            % Ensure properties are valid
            if isempty(obj.InternalNode) || ~isvalid(obj.InternalNode)
                error(message('ros:mlros2:tf:InvalidInternalNodeError'))
            elseif isempty(obj.ServerNodeHandle) || isempty(obj.TfHandle)
                error(message('ros:mlros2:tf:InvalidServerHandleError'))
            end

            % Extract node information
            try
                nodeInfo = nodeinfo(obj.InternalNode, ...
                    obj.ServerNodeHandle, []);
            catch ex
                newEx = MException(message('ros:mlros2:tf:GetInfoError'));
                throw(newEx.addCause(ex));
            end
            tfTreeHandles = [nodeInfo.tfTrees.handle];
            whichTfTree = obj.TfHandle == tfTreeHandles;
            if ~any(whichTfTree)
                % Must be the wrong handle(s) if this Tftree exists
                error(message('ros:mlros2:tf:InvalidServerHandleError'))
            elseif nnz(whichTfTree) > 1
                % Duplicate Tf handles found, error on node side
                error(message('ros:mlros2:tf:DuplicateTFHandlesError'))
            end
            tfTreeInfo = nodeInfo.tfTrees(whichTfTree);
        end
    end

    %----------------------------------------------------------------------
    % MATLAB Code-generation
    %----------------------------------------------------------------------
    methods (Static = true, Access = private)
        function name = matlabCodegenRedirect(~)
            name = 'ros.internal.codegen.ros2tf';
        end
    end
end
