classdef PurePursuit < nav.algs.internal.PurePursuitBase

    %This class is for internal use only. It may be removed in the future.

    %PUREPURSUIT Create a controller to follow a set of waypoints
    %   The pure pursuit controller is a geometric controller for following
    %   a path. Given a set of waypoints, the pure pursuit controller
    %   computes linear and angular velocity control inputs for a given
    %   pose of a differential drive robot.
    %
    %   PP = robotics.PUREPURSUIT returns a pure pursuit system object, PP,
    %   that computes linear and angular velocity inputs for a differential
    %   drive robot using the PurePursuit algorithm.
    %
    %   PP = robotics.PUREPURSUIT('PropertyName', PropertyValue, ...) returns
    %   a pure pursuit object, PP, with each specified property set to
    %   the specified value.
    %
    %   Step method syntax:
    %
    %   [V, W] = step(PP, POSE, WAYPTS) finds the linear velocity, V, and the
    %   angular velocity, W, for a 3-by-1 input vector POSE and an N-by-2
    %   input vector WAYPTS using the pure pursuit algorithm. The POSE is the
    %   current position, [x y orientation] of the robot. The WAYPTS are
    %   waypoints to be followed, [x y] locations. The output velocities V and W can
    %   be applied to a real or simulated differential drive robot to drive
    %   it along the desired waypoint sequence.
    %
    %   The WAYPTS can contain NaN values. The NaN values will be
    %   ignored. If all WAYPTS are NaN, then zero velocity output will be
    %   returned. If there is only one waypoint, then the output velocities
    %   will drive the robot towards that point.
    %
    %   PUREPURSUIT methods:
    %
    %   step        - Compute linear and angular velocity control commands
    %   release     - Allow property value changes
    %   reset       - Reset internal states to default
    %   clone       - Create pure pursuit object with same property values
    %   isLocked    - Locked status (logical)
    %   info        - Get additional information about the object
    %
    %   PUREPURSUIT properties:
    %
    %   MaxAngularVelocity      - Desired maximum angular velocity
    %   LookaheadDistance       - Lookahead distance to compute controls
    %   DesiredLinearVelocity   - Desired constant linear velocity
    %
    %   Example:
    %
    %       % Create a pure pursuit object
    %       pp = nav.slalgs.internal.PurePursuit;
    %
    %       % Assign a sequence of waypoints
    %       waypoints = [0 0;1 1;3 4];
    %
    %       % Compute control inputs for initial pose [x y theta]
    %       [v, w] = step(pp, [0 0 0], waypoints);
    %
    %   See also controllerPurePursuit, mobileRobotPRM.

    %   Copyright 2014-2023 The MathWorks, Inc.
    %
    %   References:
    %
    %   [1] J. M. Snider, "Automatic Steering Methods for Autonomous
    %       Automobile Path Tracking", Robotics Institute, Carnegie Mellon
    %       University, Pittsburgh, PA, USA, Tech. Report CMU-RI-TR-09-08,
    %       Feb. 2009.
    %#codegen
    %#ok<*EMCA>

    properties (Nontunable)
        %TargetDirPort Show TargetDir output port
        TargetDirPort (1, 1) logical = false;
        %DesiredLinearVelocityPort Specify desired linear velocity from
        % input port
        DesiredLinearVelocityPort (1, 1) logical = false;
        %LookaheadDistancePort Specify lookahead distance from input port
        LookaheadDistancePort (1, 1) logical = false;
    end
    
    properties (Constant, Hidden)
        DesiredLinearVelocitySet = matlab.system.SourceSet({'PropertyOrInput', ...
            'SystemBlock', 'DesiredLinearVelocityPort', 1, "Desired" + newline + "Linear Velocity"});
        LookaheadDistanceSet = matlab.system.SourceSet({'PropertyOrInput', ...
            'SystemBlock', 'LookaheadDistancePort', 2, "Lookahead" + newline + "Distance"});
    end

    properties (Access = {?nav.algs.internal.PurePursuitBase})
        WaypointsInternal
    end

    methods
        function obj = PurePursuit(varargin)
        %PurePursuit Constructor
            setProperties(obj,nargin,varargin{:},...
                              'DesiredLinearVelocity', 'MaxAngularVelocity', ...
                              'LookaheadDistance');
        end
    end

    methods (Access = protected)
        function setupImpl(obj,curPose, waypts)
            if obj.getExecPlatformIndex()
                % In Simulink initialize Waypoints with max-size of the
                % var-size signal. First argument decides the datatype.
                %inType = propagatedInputDataType(obj,1);
                sz = propagatedInputSize(obj,2);
                obj.WaypointsInternal = nan(sz, 'like', curPose);
            else
                % For MATLAB assign Waypoints based on input size
                obj.WaypointsInternal = nan(size(waypts), class(curPose));
            end

            obj.LookaheadPoint = zeros(1,2, 'like', curPose);
            obj.LastPose = zeros(1,3, 'like', curPose);
            obj.ProjectionPoint = nan(1,2, 'like', curPose);
            obj.ProjectionLineIndex = cast(0, 'like', curPose);
        end

        function validateInputsImpl(obj, curPose, waypts)
        %validateInputsImpl Validate inputs before setupImpl is called
            obj.validatePose(curPose, 'validateInputsImpl', 'pose');
            obj.validateWaypoints(waypts, 'validateInputsImpl', 'waypoints');

            isDataTypeEqual = isequal(class(curPose), class(waypts));

            coder.internal.errorIf(~isDataTypeEqual, ...
                                   'nav:navslalgs:purepursuit:DataTypeMismatch', ...
                                   class(curPose), class(waypts));
        end

        function varargout = stepImpl(obj,curPose,waypts)
        %stepImpl Compute control commands

            currentPose = obj.validatePose(curPose, 'step', 'pose');
            obj.validateWaypoints(waypts, 'step', 'waypoints');

            paddedWaypts = nan(size(obj.WaypointsInternal), 'like', currentPose);
            paddedWaypts(1:size(waypts,1), :) = waypts;

            if ~isequaln(obj.WaypointsInternal, paddedWaypts)
                % Reset computation if waypoints have changed.
                obj.WaypointsInternal = paddedWaypts;
                obj.ProjectionLineIndex = cast(0, 'like', currentPose);
            end

            [v, w, ~, targetDir] = obj.stepInternal(currentPose,waypts);

            if obj.TargetDirPort
                varargout = {v,w,targetDir};
            else
                varargout = {v,w};
            end
        end

        function varargout = getOutputSizeImpl(obj)
        %getOutputSizeImpl Return size for each output port

        % linear velocity is scalar
            varargout{1} = 1;
            % angular velocity is scalar
            varargout{2} = 1;

            % TargetDir is scalar
            if obj.TargetDirPort
                varargout{3} = 1;
            end
        end

        function varargout = getOutputDataTypeImpl(obj)
        %getOutputDataTypeImpl Return data type for each output port

        %   Output data type depends on the data-type of the first
        %   input argument

        % linear velocity
            varargout{1} = propagatedInputDataType(obj,1);
            % angular velocity
            varargout{2} = propagatedInputDataType(obj,1);

            % TargetDir is scalar
            if obj.TargetDirPort
                varargout{3} = propagatedInputDataType(obj,1);
            end
        end

        function varargout = isOutputComplexImpl(obj)
        %isOutputComplexImpl Return true for each output port with complex data

        % linear velocity is real
            varargout{1} = false;
            % angular velocity is real
            varargout{2} = false;

            % TargetDir is real
            if obj.TargetDirPort
                varargout{3} = false;
            end
        end

        function varargout = isOutputFixedSizeImpl(obj)
        %isOutputFixedSizeImpl Return true for each output port with fixed size

        % linear velocity is fixed size
            varargout{1} = true;
            % angular velocity is fixed size
            varargout{2} = true;

            % lookahead point is fixed size
            if obj.TargetDirPort
                varargout{3} = true;
            end
        end

        function num = getNumInputsImpl(~)
        %getNumInputsImpl return number of inputs

        % Input is current pose
            num = 2;
        end

        function num = getNumOutputsImpl(obj)
        %getNumOutputsImpl return number of outputs

        % Output is linear velocity, angular velocity and look ahead
        % point.
            if obj.TargetDirPort
                num = 3;
            else
                num = 2;
            end
        end

        function icon = getIconImpl(~)
        %getIconImpl Define icon for System block
            filepath = fullfile(matlabroot, 'toolbox', 'shared', 'nav_rst', 'nav_rst_simulink', 'blockicons', 'PurePursuitIcon.dvg');
            icon = matlab.system.display.Icon(filepath);
        end

        function [name1, name2] = getInputNamesImpl(~)
        % Return input port names for System block
            name1 = 'Pose';
            name2 = 'Waypoints';
        end

        function names = getOutputNamesImpl(obj)
        % Return output port names for System block
            names = ["Linear" + newline + "Velocity", ...
                "Angular" + newline + "Velocity"];
            if obj.TargetDirPort
                names(end+1) = "Target" + newline + "Direction";
            end
        end

        function s = saveObjectImpl(obj)
        %saveObjectImpl Custom save implementation
            s = saveObjectImpl@matlab.System(obj);

            s.ProjectionPoint = obj.ProjectionPoint;
            s.LookaheadPoint = obj.LookaheadPoint;
            s.LastPose = obj.LastPose;
            s.ProjectionLineIndex = obj.ProjectionLineIndex;
            s.WaypointsInternal = obj.WaypointsInternal;
        end

        function loadObjectImpl(obj, svObj, wasLocked)
        %loadObjectImpl Custom load implementation

            obj.ProjectionPoint = svObj.ProjectionPoint;
            obj.LookaheadPoint = svObj.LookaheadPoint;
            obj.LastPose = svObj.LastPose;
            obj.ProjectionLineIndex = svObj.ProjectionLineIndex;
            obj.WaypointsInternal = svObj.WaypointsInternal;

            % Call base class method
            loadObjectImpl@matlab.System(obj,svObj,wasLocked);
        end

        function resetImpl(obj)
        %resetImpl Reset the internal state to defaults
            obj.LookaheadPoint = 0*obj.LookaheadPoint;
            obj.LastPose = 0*obj.LastPose;
            obj.ProjectionPoint = nan*obj.ProjectionPoint;
            obj.ProjectionLineIndex = 0*obj.ProjectionLineIndex;
        end

        function flag = isInputSizeMutableImpl(~,index)
        %isInputSizeMutableImpl Return false if input size is not allowed
        % to change while system is running

        % Pose input is fixed size, waypoints are variable size
            if index == 1
                flag = false;
            else
                flag = true;
            end
        end

        function flag = supportsMultipleInstanceImpl(~)
        %supportsMultipleInstanceImpl Return true to enable support for
        % For-Each Subsystem
            flag = true;
        end
    end

    methods(Access = protected, Static)
        function header = getHeaderImpl
        %getHeaderImpl Define header panel for System block dialog

            header = matlab.system.display.Header('controllerPurePursuit', ...
                                                  'Title', message('nav:navslalgs:purepursuit:PurePursuitTitle').getString, ...
                                                  'Text', message('nav:navslalgs:purepursuit:PurePursuitDescription').getString, ...
                                                  'ShowSourceLink', false);
        end

        function group = getPropertyGroupsImpl
        %getPropertyGroupsImpl Define property section(s) for System block dialog
        
            ParameterInputSectionName = message('Simulink:studio:ToolBarParametersMenu').getString;

            propDesiredLinearVelocityPort = matlab.system.display.internal.Property('DesiredLinearVelocityPort', 'Description', getString(message('nav:navslalgs:purepursuit:DesiredLinearVelocityPortPrompt')));
            propDesiredLinearVelocity = matlab.system.display.internal.Property('DesiredLinearVelocity','Description',getString(message('nav:navslalgs:purepursuit:DesiredLinearVelocityPrompt')));
            propMaxAngularVelocity = matlab.system.display.internal.Property('MaxAngularVelocity','Description',getString(message('nav:navslalgs:purepursuit:MaxAngularVelocityPrompt')));
            propLookaheadDistancePort = matlab.system.display.internal.Property('LookaheadDistancePort', 'Description', getString(message('nav:navslalgs:purepursuit:LookaheadDistancePortPrompt')));
            propLookaheadDistance = matlab.system.display.internal.Property('LookaheadDistance','Description',getString(message('nav:navslalgs:purepursuit:LookaheadDistancePrompt')));
            propTargetDirPort = matlab.system.display.internal.Property('TargetDirPort','Description',getString(message('nav:navslalgs:purepursuit:TargetDirPortPrompt')));

            group = matlab.system.display.Section(...
                'Title', ParameterInputSectionName, ...
                'PropertyList', {propDesiredLinearVelocityPort, propDesiredLinearVelocity, propMaxAngularVelocity, propLookaheadDistancePort, propLookaheadDistance, propTargetDirPort} ...
                );
        end
    end

end
