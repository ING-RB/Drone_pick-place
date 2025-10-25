classdef ros2tf < ros.internal.mixin.InternalAccess & ...
        coder.ExternalDependency
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
    %       % This example assumes that some ROS node publishes
    %       % transformations between base_link and camera_depth_frame.
    %       % For example, a real or simulated TurtleBot would do that.
    %
    %        % Create a ROS 2 node on domain id 25.
    %        node = ros2node("/testTf",25);
    %
    %        % Retrieve the transformation tree object
    %        % Use struct message format for better performance
    %        tftree = ros2tf(node)
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
    %#codegen

    properties (Access = private)
        %TransformHelper - helper handle for MATLABROS2Transform
        TransformHelper
    end

    properties (Dependent)
        %BufferTime - Time (in seconds) for which transformations are buffered
        %   If you change the buffer time from its current value, the
        %   transformation tree and all transformations are re-initialized.
        %   By default, the buffer length is 10 seconds.
        BufferTime
    end

    properties (Dependent, SetAccess = private)
        %AvailableFrames - List of all available coordinate frames
        %   The list of all coordinate frames in the transformation tree
        %   is returned as a cell array of strings. It is empty
        %   if no frames are in the tree.
        AvailableFrames

        %LastUpdateTime - Time when the last transform was received
        %   The time is returned as a ros.msg.Time object. It
        %   is empty if no transforms have been received yet.
        LastUpdateTime
    end

    properties (Constant)
        %DefaultBufferTime - The default buffer time (in seconds)
        DefaultBufferTime = 10
        %DefaultSourceTime - The default source time (in seconds)
        DefaultSourceTime = 0
    end

    properties (SetAccess = immutable)
        %History - The message queue mode
        DynamicBroadcasterQoS

        %Depth - The message queue size
        StaticBroadcasterQoS

        %Reliability - The delivery guarantee of messages
        DynamicListenerQoS

        %Durability - The persistence of messages
        StaticListenerQoS
    end

    methods
        function obj = ros2tf(node, varargin)
            %ros2tf Construct a transformation tree object
            %   Please see the class documentation (help
            %   ros2tf) for more details.

            % Check input arguments
            coder.inline('never');
            narginchk(1, inf);

            %% Check input arguments
            % Validate input ros2node
            validateattributes(node, {'ros2node'}, {'scalar'}, ...
                'ros2tf','node');

            % Parse NV pairs
            nvPairs = struct('DynamicBroadcasterQoS',uint32(0),...
                'StaticBroadcasterQoS',uint32(0),...
                'DynamicListenerQoS',uint32(0),...
                'StaticListenerQoS',uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pOuterStruct = coder.internal.parseParameterInputs(nvPairs,pOpts,varargin{:});
            dynamicBroadcasterQoS = coder.internal.getParameterValue(pOuterStruct.DynamicBroadcasterQoS,struct,varargin{:});
            staticBroadcasterQoS = coder.internal.getParameterValue(pOuterStruct.StaticBroadcasterQoS,struct,varargin{:});
            dynamicListenerQoS = coder.internal.getParameterValue(pOuterStruct.DynamicListenerQoS,struct,varargin{:});
            staticListenerQoS = coder.internal.getParameterValue(pOuterStruct.StaticListenerQoS,struct,varargin{:});

            validateattributes(dynamicBroadcasterQoS,{'struct'},{'scalar','nonempty'},'ros2tf','DynamicBroadcasterQoS');
            validateattributes(staticBroadcasterQoS,{'struct'},{'scalar','nonempty'},'ros2tf','StaticBroadcasterQoS');
            validateattributes(dynamicListenerQoS,{'struct'},{'scalar','nonempty'},'ros2tf','DynamicListenerQoS');
            validateattributes(staticListenerQoS,{'struct'},{'scalar','nonempty'},'ros2tf','StaticListenerQoS');

            mProps = {'DynamicBroadcasterQoS', 'StaticBroadcasterQoS', 'DynamicListenerQoS', 'StaticListenerQoS'};
            nvPairsInner = struct('History',uint32(0),...
                'Depth',uint32(0),...
                'Reliability',uint32(0),...
                'Durability',uint32(0),...
                'Deadline',double(0), ...
                'Lifespan',double(0), ...
                'Liveliness',uint32(0), ...
                'LeaseDuration',double(0), ...
                'AvoidROSNamespaceConventions',false);

            dynamicBroadcasterQoSCpp = coder.opaque('rmw_qos_profile_t', ...
                'rmw_qos_profile_default', 'HeaderFile', 'rmw/qos_profiles.h');
            staticBroadcasterQoSCpp = coder.opaque('rmw_qos_profile_t', ...
                'rmw_qos_profile_default', 'HeaderFile', 'rmw/qos_profiles.h');
            dynamicListenerQoSCpp = coder.opaque('rmw_qos_profile_t', ...
                'rmw_qos_profile_default', 'HeaderFile', 'rmw/qos_profiles.h');
            staticListenerQoSCpp = coder.opaque('rmw_qos_profile_t', ...
                'rmw_qos_profile_default', 'HeaderFile', 'rmw/qos_profiles.h');

            fs = {dynamicBroadcasterQoS,staticBroadcasterQoS,dynamicListenerQoS,staticListenerQoS};
            qosProfilesCpp = {dynamicBroadcasterQoSCpp, staticBroadcasterQoSCpp, dynamicListenerQoSCpp, staticListenerQoSCpp};
            % length must be greater than 0
            fslen = length(fs);
            for val = 1:fslen
                pInnerStruct = coder.internal.parseParameterInputs(nvPairsInner,pOpts,fs{val});
                if ~isfield(fs{val},'History')
                    qosHistory = 'keeplast';
                else
                    qosHistory = convertStringsToChars(coder.internal.getParameterValue(pInnerStruct.History,'keeplast',fs{val}));
                end
                validateStringParameter(qosHistory,{'keeplast', 'keepall'},'ros2tf','History');

                if ~isfield(fs{val},'Depth')
                    if isequal(val,2)
                        qosDepth = 1;
                    else
                        qosDepth = 100;
                    end
                else
                    qosDepth = coder.internal.getParameterValue(pInnerStruct.Depth,1,fs{val});
                end
                validateattributes(qosDepth,{'numeric'},...
                    {'scalar','nonempty','integer','nonnegative'},...
                    'ros2tf','Depth');

                if ~isfield(fs{val},'Reliability')
                    qosReliability = 'reliable';
                else
                    qosReliability = convertStringsToChars(coder.internal.getParameterValue(pInnerStruct.Reliability,'reliable',fs{val}));
                end
                validateStringParameter(qosReliability,{'reliable', 'besteffort'},'ros2tf','Reliability');

                if ~isfield(fs{val},'Durability')
                    if isequal(val,2) || isequal(val,4)
                        qosDurability = 'transientlocal';
                    else
                        qosDurability = 'volatile';
                    end
                else
                    qosDurability = convertStringsToChars(coder.internal.getParameterValue(pInnerStruct.Durability,'volatile',fs{val}));
                end
                validateStringParameter(qosDurability,{'transientlocal', 'volatile'},'ros2tf','Durability');

                if ~isfield(fs{val}, 'Deadline')
                    qosDeadline = 0;
                else
                    qosDeadline = coder.internal.getParameterValue(pInnerStruct.Deadline,0,fs{val});
                end
                if qosDeadline==Inf
                    qosDeadline=0;
                end
                validateattributes(qosDeadline,{'double'},{'scalar', 'nonnegative', 'nonnan'},'ros2tf','Deadline');

                if ~isfield(fs{val}, 'Lifespan')
                    qosLifespan = 0;
                else
                    qosLifespan = coder.internal.getParameterValue(pInnerStruct.Lifespan,0,fs{val});
                end
                if qosLifespan==Inf
                    qosLifespan=0;
                end
                validateattributes(qosLifespan,{'double'},{'scalar', 'nonnegative', 'nonnan'},'ros2tf','Lifespan');

                if ~isfield(fs{val},'Liveliness')
                    qosLiveliness = 'automatic';
                else
                    qosLiveliness = convertStringsToChars(coder.internal.getParameterValue(pInnerStruct.Liveliness,'automatic',fs{val}));
                end
                validateStringParameter(qosLiveliness,{'automatic','default','manual'},'ros2tf','Liveliness');

                if ~isfield(fs{val}, 'LeaseDuration')
                    qosLeaseDuration = 0;
                else
                    qosLeaseDuration = coder.internal.getParameterValue(pInnerStruct.LeaseDuration,0,fs{val});
                end
                if qosLeaseDuration==Inf
                    qosLeaseDuration=0;
                end
                validateattributes(qosLeaseDuration,{'double'},{'scalar', 'nonnegative', 'nonnan'},'ros2tf','LeaseDuration');

                if ~isfield(fs{val}, 'AvoidROSNamespaceConventions')
                    qosAvoidROSNamespaceConventions = false;
                else
                    qosAvoidROSNamespaceConventions = coder.internal.getParameterValue(pInnerStruct.AvoidROSNamespaceConventions,false,fs{val});
                end
                validateattributes(qosAvoidROSNamespaceConventions,{'logical'},{'nonempty'},'ros2tf','AvoidROSNamespaceConventions');

                qosProfilesCpp{val} = ros.ros2.internal.setQOSProfile(qosProfilesCpp{val}, ...
                    qosHistory, ...
                    qosDepth, ...
                    qosReliability, ...
                    qosDurability, ...
                    qosDeadline, ...
                    qosLifespan, ...
                    qosLiveliness, ...
                    qosLeaseDuration, ...
                    qosAvoidROSNamespaceConventions);

                % allocate qos settings fields for each qos property
                obj.(mProps{val}) = struct('History', qosHistory, 'Depth', qosDepth, 'Reliability', qosReliability, 'Durability', qosDurability, 'Deadline', qosDeadline, ...
                    'Lifespan', qosLifespan, 'Liveliness', qosLiveliness, 'LeaseDuration', qosLeaseDuration, 'AvoidROSNamespaceConventions', qosAvoidROSNamespaceConventions);
            end

            % Store input arguments
            obj.DynamicBroadcasterQoS = obj.(mProps{1});
            obj.StaticBroadcasterQoS = obj.(mProps{2});
            obj.DynamicListenerQoS = obj.(mProps{3});
            obj.StaticListenerQoS = obj.(mProps{4});

            % Create an instance of MATLABROS2Transform object and store
            % handle to TransformHelper
            obj.TransformHelper = coder.opaque('std::unique_ptr<MATLABROS2Transform>', 'HeaderFile', 'mlros2_transform.h');
            obj.TransformHelper = coder.ceval('std::unique_ptr<MATLABROS2Transform>(new MATLABROS2Transform());//');

            coder.ceval('MATLABROS2Transform_createTfTree', ...
                obj.TransformHelper, node.NodeHandle, ...
                qosProfilesCpp{1},qosProfilesCpp{2}, ...
                qosProfilesCpp{3}, qosProfilesCpp{4});

            % Trigger generation of ros2_structmsg_conversion.h file
            % (g2585525)
            ros2message('geometry_msgs/TransformStamped');
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

            coder.inline('never');
            % Validate input arguments
            coder.internal.narginchk(3,6,nargin);
            targetFrame = convertStringsToChars(targetFrame);
            sourceFrame = convertStringsToChars(sourceFrame);
            validateattributes(targetFrame, {'char','string'},{'nonempty'},...
                'getTransform','targetFrame');
            validateattributes(sourceFrame, {'char','string'},{'nonempty'},...
                'getTransform','sourceFrame');

            % Default sourceTime and timeout are both 0
            defaultTime = 0;
            if isempty(varargin)
                % Syntax: getTransform('TARGETFRAME','SOURCEFRAME')
                sourceTime = ros2time(defaultTime);
            elseif isnumeric(varargin{1}) || isstruct(varargin{1})
                % Syntax:
                % getTransform('TARGETFRAME','SOURCEFRAME',SOURCETIME) or
                % getTransform('TARGETFRAME','SOURCEFRAME',SOURCETIME,'Timeout',timeout)
                sourceTime = ros.internal.Parsing.validateROS2Time(varargin{1},'getTransform','sourceTime');
                indx = 2;
            else
                % Syntax:
                % getTransform('TARGETFRAME','SOURCEFRAME','Timeout',timeout)
                sourceTime = ros2time(defaultTime);
                indx = 1;
            end

            timeout = 0;
            if nargin>4
                % Retrieve name-value pairs
                % Can only be either
                % getTransform('TARGETFRAME','SOURCEFRAME','Timeout',timeout)
                % or
                % getTransform('TARGETFRAME','SOURCEFRAME',SOURCETIME,'Timeout',timeout)
                nvPairs = struct('Timeout',uint32(0));
                pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
                pStruct = coder.internal.parseParameterInputs(nvPairs,pOpts,varargin{indx:end});
                timeout = coder.internal.getParameterValue(pStruct.Timeout,defaultTime,varargin{indx:end});
                validateattributes(timeout,{'numeric'},...
                    {'scalar','nonempty','positive'},'getTransform','Timeout');
            end

            if isfinite(timeout)
                timeoutStruct = ros2time(timeout);
            else
                % Address syntax:
                % getTransform('TARGETFRAME','SOURCEFRAME','Timeout',inf)
                % Wait until transformation is available
                while(~canTransform(obj,targetFrame,sourceFrame,sourceTime))
                    % Avoid optimizing away
                    coder.ceval('//',targetFrame);
                end
                timeoutStruct = ros2time(defaultTime);
            end

            % Note: there is no failure here since there is no backend MCOS
            % function call as what we did in MATLAB interpretation.
            % When passing to coder.ceval as input argument, a new variable
            % need to be created so that there is no string/char conflict.
            targetFrameRef = targetFrame;
            sourceFrameRef = sourceFrame;

            tform = ros2message("geometry_msgs/TransformStamped");
            coder.cinclude('<functional>');
            coder.ceval('MATLABROS2Transform_lookupTransform', ...
                obj.TransformHelper, coder.wref(tform),coder.rref(targetFrameRef), uint32(size(targetFrameRef,2)),...
                coder.rref(sourceFrameRef), uint32(size(sourceFrameRef, 2)), ...
                sourceTime.sec, sourceTime.nanosec, timeoutStruct.sec, timeoutStruct.nanosec);
        end

        function sendTransform(obj, tf, varargin)
            %sendTransform - Send a transform to the ROS network
            %   sendTransform(OBJ,TF) broadcasts a transform TF to the
            %   ROS 2 network. TF is a scalar message or a message list of type
            %   geometry_msgs/TransformStamped.

            % Validate input arguments
            coder.internal.narginchk(2,4,nargin);
            validateattributes(tf,'struct',{'vector','nonempty'},'sendTransform','tf');

            if ~isequal(tf(1).MessageType, 'geometry_msgs/TransformStamped')
                coder.internal.error('ros:mlroscpp:message:InputTypeMismatch','geometry_msgs/TransformStamped');
            end

            % Parse NV pairs
            nvPairs = struct('UseStatic',uint32(0));
            pOpts = struct('PartialMatching',true,'CaseSensitivity',false);
            pStruct = coder.internal.parseParameterInputs(nvPairs,pOpts,varargin{:});
            useStaticTf = coder.internal.getParameterValue(pStruct.UseStatic,false,varargin{:});
            validateattributes(useStaticTf, {'logical'}, {}, ...
                'sendTransform',...
                'UseStatic');

            coder.cinclude('<functional>');
            if useStaticTf
                for i = 1:numel(tf)
                    % broadcasts a transform TF to the ROS 2 network on topic /tf_static.
                    coder.ceval('MATLABROS2Transform_sendStaticTransform', ...
                        obj.TransformHelper, tf(i));
                end
            else
                for i = 1:numel(tf)
                    % broadcasts a transform TF to the ROS 2 network on topic /tf.
                    coder.ceval('MATLABROS2Transform_sendTransform', ...
                        obj.TransformHelper, tf(i));
                end
            end
        end

        function isAvailable = canTransform(obj, targetFrame, sourceFrame, varargin)
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

            coder.inline('never');
            coder.cinclude('<functional>');
            % Validate input arguments
            coder.internal.narginchk(3,4,nargin);
            targetFrame = convertStringsToChars(targetFrame);
            sourceFrame = convertStringsToChars(sourceFrame);
            validateattributes(targetFrame, {'char','string'},{'nonempty'},...
                'canTransform','targetFrame');
            validateattributes(sourceFrame, {'char','string'},{'nonempty'},...
                'canTransform','sourceFrame');

            if isempty(varargin)
                % Syntax: canTransfrom('TARGETFRAME','SOURCEFRAME')
                sourceTime = ros2time(obj.DefaultSourceTime);
            else
                % Syntax: canTransfrom('TARGETFRAME','SOURCEFRAME',SOURCETIME)
                % return FALSE if SOURCETIME is outside of the buffer
                % window
                sourceTime = ros.internal.Parsing.validateROS2Time(varargin{1},'canTransform','sourceTime');
                if ((uint32(sourceTime.sec) + 1e-9*sourceTime.nanosec) > obj.DefaultBufferTime)
                    isAvailable =  false;
                    return;
                end
            end

            % Note: there is no failure here since there is no backend MCOS
            % function call as what we did in MATLAB interpretation.
            % When passing to coder.ceval as input argument, a new variable
            % need to be created so that there is no string/char conflict.
            targetFrameRef = targetFrame;
            sourceFrameRef = sourceFrame;
            isAvailable = false;
            coder.ceval('MATLABROS2Transform_canTransform', ...
                obj.TransformHelper, coder.wref(isAvailable), coder.rref(targetFrameRef), uint32(size(targetFrameRef,2)),...
                coder.rref(sourceFrameRef), uint32(size(sourceFrameRef, 2)), ...
                sourceTime.sec, sourceTime.nanosec);
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

            coder.inline('never');
            % Validate input arguments
            % message type validation will be handled by rosApplyTransform
            coder.internal.narginchk(3,4,nargin);
            targetFrame = convertStringsToChars(targetFrame);
            validateattributes(targetFrame, {'char','string'},{'nonempty'},...
                'transform','targetFrame');

            % Extract source time
            if isempty(varargin)
                % Syntax: transform(OBJ,TARGETFRAME,MSG)
                sourceTime = obj.DefaultSourceTime;
            elseif isequal(varargin{1},"msgtime")
                % Syntax: transform(OBJ,TARGETFRAME,MSG,"msgtime")
                sourceTime = uint32(msg.header.stamp.sec) + 1e-9*msg.header.stamp.nanosec;
            else
                % Syntax: transform(OBJ,TARGETFRAME,MSG,SOURCETIME)
                % User specified timeout
                validateattributes(varargin{1},{'numeric'},...
                    {'scalar','nonempty','real','nonnegative'},'transform','SOURCETIME');
                sourceTime = varargin{1};
            end

            % Lookup the transformation based on the given target frame and
            % the source frame in the messsage.
            sourceFrame = msg.header.frame_id;
            tf = obj.getTransform(targetFrame,sourceFrame,sourceTime);

            % We have a valid transformation. Apply it to the input.
            tfEntity = rosApplyTransform(tf, msg);
        end

        function bufferTime = get.BufferTime(obj)
            %get.BufferTime - getter for BufferTime

            coder.inline('never');
            coder.cinclude('<functional>');

            currentSec = int32(0);
            currentNsec = uint32(0);
            cacheTimeStatus = false;
            coder.ceval('MATLABROS2Transform_getCacheTime', obj.TransformHelper, coder.wref(cacheTimeStatus), coder.ref(currentSec),coder.ref(currentNsec));

            validSecs = double(currentSec);
            validNSecs = double(currentNsec);
            if isequal(cacheTimeStatus, 0)
                cacheTime = ros2time(validSecs,validNSecs);
            else
                cacheTime = ros2time(obj.DefaultBufferTime,0);
            end
            bufferTime = double(cacheTime.sec) + 1e-9*double(cacheTime.nanosec);
        end

        function set.BufferTime(obj, bufferTime)
            %set.BufferTime - setter for BufferTime

            coder.inline('never');
            coder.cinclude('<functional>');
            % Validate valid bufferTime
            validateattributes(bufferTime, {'numeric'}, {'nonempty', 'scalar', 'real', 'positive', ...
                'nonnan', 'finite', '<', ros.internal.Parsing.MaxTimeNumeric}, ...
                'ros2tf', 'BufferTime');
            validBufferTime = double(bufferTime);
            bufferRosTime = ros2time(validBufferTime);

            % Only re-initialize transformation tree if requrested time is
            % different from the current buffer time
            currentRosTime = ros2time(obj.BufferTime);

            % Set cache time if bufferRosTime is not equal to
            % currentRosTime
            if ~isequal(bufferRosTime,currentRosTime)
                coder.ceval('MATLABROS2Transform_setCacheTime', obj.TransformHelper, bufferRosTime.sec, bufferRosTime.nanosec);
            end
        end

        function frameNames = get.AvailableFrames(obj)
            %get.AvailableFrames Retrieve all frame names in the tree

            % Retrieve all names from ROS 2 node

            numberOfFrames = int32(0);
            coder.cinclude('<functional>');
            coder.ceval('MATLABROS2Transform_updateAndGetNumOfFrames', obj.TransformHelper, coder.wref(numberOfFrames));
            frameNames = cell(numberOfFrames,1);

            for key=1:numel(frameNames)
                index = int32(key-1);
                frameNameLength = int32(0);
                coder.ceval('MATLABROS2Transform_getFrameNameLength', obj.TransformHelper,index, coder.wref(frameNameLength));
                frameEntry = char(zeros(1,frameNameLength));
                coder.ceval('MATLABROS2Transform_getAvailableFrame', obj.TransformHelper,index,coder.wref(frameEntry));
                frameNames{key} = frameEntry;
            end
        end

        function updateTime = get.LastUpdateTime(obj)
            %get.LastUpdateTime Retrieve last time the tree was updated

            coder.inline('never');
            doNotOptimize(obj);
            coder.internal.assert(false, 'ros:mlroscpp:codegen:UnsupportedMethodCodegen', ...
                'get.LastUpdateTime');
            updateTime = ros2time(0);
        end
    end

    methods (Static)
        function ret = getDescriptiveName(~)
            ret = 'ROS 2 TransformationTree';
        end

        function ret = isSupportedContext(bldCtx)
            ret = bldCtx.isCodeGenTarget('rtw');
        end

        function updateBuildInfo(buildInfo,bldCtx)
            if bldCtx.isCodeGenTarget('rtw')
                srcFolder = ros.slros.internal.cgen.Constants.PredefinedCode.Location;
                addIncludeFiles(buildInfo,'mlros2_transform.h',srcFolder);
                addIncludeFiles(buildInfo,'mlros2_qos.h',srcFolder);
            end
        end
    end

    methods (Access = private)
        function doNotOptimize(obj)
            %DONOTOPTIMIZE - avoid optimizing away codes during Code Generation
            coder.ceval('//',coder.wref(obj.TransformHelper));
        end
    end
end

function validateStringParameter(value, options, funcName, varName)
% Separate function to suppress output and just validate
validatestring(value, options, funcName, varName);
end
