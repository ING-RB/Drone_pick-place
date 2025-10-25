classdef waypointTrajectory < matlab.System ...
        & matlab.system.mixin.FiniteSource ...
        & fusion.scenario.internal.mixin.PlatformTrajectory ...
        & scenario.internal.mixin.Perturbable
%WAYPOINTTRAJECTORY Waypoint trajectory generator
%   TRAJ = WAYPOINTTRAJECTORY(POINTS, T) returns a System object, TRAJ,
%   that generates a trajectory based on the specified waypoints POINTS and
%   times T. POINTS is an N-by-3 matrix that specifies the positions along
%   the trajectory. T is an N-element vector that specifies the times at
%   which the trajectory crosses the corresponding waypoints.  If T is
%   unspecified, then it is inferred from either the 'Velocities' or
%   'Groundspeed' name-value pairs described below.
%
%   TRAJ = WAYPOINTTRAJECTORY(..., 'Name', value) returns a
%   WAYPOINTTRAJECTORY System object by specifying its properties as
%   name-value pair arguments.  Unspecified properties have default values.
%   See the list of properties below.
%
%   Step method syntax:
%
%   [POS, ORIENT, VEL, ACC, ANGVEL] = step(TRAJ) outputs a frame of 
%   trajectory data based on the specified waypoints.
%
%   The outputs of WAYPOINTTRAJECTORY are defined as follows:
%
%       POS       Position in the local navigation coordinate system 
%                 specified as a real finite N-by-3 array in meters. N is
%                 specified by the SamplesPerFrame property.
%
%       ORIENT    Orientation with respect to the local navigation 
%                 coordinate system specified as a quaternion N-element
%                 column vector or a 3-by-3-by-N rotation matrix. Each
%                 quaternion or rotation matrix is a frame rotation from
%                 the local navigation coordinate system to the current
%                 body coordinate system. N is specified by the
%                 SamplesPerFrame property.
%
%       VEL       Velocity in the local navigation coordinate system 
%                 specified as a real finite N-by-3 array in meters per
%                 second. N is specified by the SamplesPerFrame property.
%
%       ACC       Acceleration in the local navigation coordinate system 
%                 specified as a real finite N-by-3 array in meters per
%                 second squared. N is specified by the SamplesPerFrame
%                 property.
%
%       ANGVEL    Angular velocity in the local navigation coordinate 
%                 system specified as a real finite N-by-3 array in radians
%                 per second. N is specified by the SamplesPerFrame
%                 property.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   WAYPOINTTRAJECTORY methods:
%
%   step               - See above description for use of this method
%   lookupPose         - Return pose information for a given set of times
%   perturbations      - Define perturbations to the trajectory
%   perturb            - Apply perturbations to the trajectory
%   release            - Allow property value and input characteristics to 
%                        change, and release WAYPOINTTRAJECTORY resources
%   clone              - Create WAYPOINTTRAJECTORY object with same 
%                        property values
%   isLocked           - Display locked status (logical)
%   reset              - Reset the states of the WAYPOINTTRAJECTORY
%   isDone             - True if entire trajectory has been output
%
%   WAYPOINTTRAJECTORY construction properties:
%
%   Waypoints          - Waypoints in the navigation frame (m)
%   TimeOfArrival      - Time at each waypoint (s)
%   Velocities         - Velocities at each waypoint (m/s)
%   Course             - Horizontal direction of travel (degrees)
%   GroundSpeed        - Groundspeed at each waypoint (m/s)
%   ClimbRate          - Climbrate at each waypoint (m/s)
%   JerkLimit          - Longitudinal jerk constraint (m/s^3) 
%   InitialTime        - Duration before first waypoint (s)
%   WaitTime           - Duration to wait at each waypoint (s) 
%   Orientation        - Orientation at each waypoint
%   AutoPitch          - Align orientation (pitch) with direction of travel
%   AutoBank           - Align orientation (roll) to counteract centripetal
%                        force
%   ReferenceFrame     - Axes convention ('NED' or 'ENU')
%
%   WAYPOINTTRAJECTORY tunable properties:
%
%   SampleRate      - Sample rate of trajectory (Hz)
%   SamplesPerFrame - Number of samples in the output
%
%   % EXAMPLE 1: Visualize specified waypoints and computed position.
%   % Record the generated position and verify that it passes through the
%   % specified waypoints.
%   Fs = 50;
%   wps = [0 0 0;
%          1 0 0;
%          1 1 0;
%          1 2 0;
%          1 3 0];
%   t = 0:(size(wps,1)-1);
%   
%   % create trajectory
%   traj = waypointTrajectory(wps, t, 'SampleRate', Fs);
%   
%   % lookup pose information for entire trajectory
%   pos = lookupPose(traj, t(1):1/Fs:t(end));
%
%   % Plot generated positions and specified waypoints.
%   plot(pos(:,1),pos(:,2), wps(:,1),wps(:,2), '--o')
%   title('Position')
%   xlabel('X (m)')
%   ylabel('Y (m)')
%   zlabel('Z (m)')
%   legend({'Position', 'Waypoints'})
%
%   % EXAMPLE 2: Generate a racetrack trajectory by specifying the velocity
%   % and orientation at each waypoint.
%   Fs = 100;
%   wps = [0 0 0;
%          20 0 0;
%          20 5 0;
%          0 5 0;
%          0 0 0];
%   t = cumsum([0 10 1.25*pi 10 1.25*pi]).';
%   vels = [2 0 0;
%          2 0 0;
%          -2 0 0;
%          -2 0 0;
%          2 0 0];
%   eulerAngs = [0 0 0;
%                0 0 0;
%                180 0 0;
%                180 0 0;
%                0 0 0];
%   q = quaternion(eulerAngs, 'eulerd', 'ZYX', 'frame');
%   
%   traj = waypointTrajectory(wps, 'SampleRate', Fs, ...
%       'TimeOfArrival', t, 'Velocities', vels, 'Orientation', q);
%   
%   % fetch pose information one buffer frame at a time
%   [pos, orient, vel, acc, angvel] = traj();
%   i = 1;
%   spf = traj.SamplesPerFrame;
%   while ~isDone(traj)
%       idx = (i+1):(i+spf);
%       [pos(idx,:), orient(idx,:), ...
%           vel(idx,:), acc(idx,:), angvel(idx,:)] = traj();
%       i = i+spf;
%   end
%   % Plot generated positions and specified waypoints.
%   plot(pos(:,1),pos(:,2), wps(:,1),wps(:,2), '--o')
%   title('Position')
%   xlabel('X (m)')
%   ylabel('Y (m)')
%   zlabel('Z (m)')
%   legend({'Position', 'Waypoints'})
%   axis equal
%
%   See also KINEMATICTRAJECTORY

%   Copyright 2018-2022 The MathWorks, Inc.

%#codegen

    properties
        % SampleRate Sampling rate (Hz)
        % Specify the sampling frequency of the trajectory as a positive
        % scalar. The default value is 100. This property is tunable.
        SampleRate = 100;
    end
    properties(Nontunable)
        % SamplesPerFrame Number of samples per output frame
        % Specify the number of samples to buffer into each output frame.
        % The default value is 1.
        SamplesPerFrame = 1;
    end
    
    properties (SetAccess = private)
        % Waypoints Positions in the navigation frame (m)
        % Specify the position at each waypoint as an N-by-3 matrix in
        % meters. The default value is [0 0 0; 0 0 0].
        %
        % This property may only be set in the constructor.
        Waypoints;
        
        % TimeOfArrival Time at each waypoint (s)
        % Specify the times at which the trajectory crosses the
        % corresponding waypoints as an N-element vector. If it is not
        % specified, then it is inferred from each waypoint.
        %
        % This property may only be set in the constructor.
        TimeOfArrival;
        
        % Velocities Velocity in the navigation frame at each waypoint (m/s)
        % Specify the velocities at the corresponding waypoints as an
        % N-by-3 matrix. If it is not specified, then it is inferred from
        % each waypoint.
        %
        % This property may only be set in the constructor.
        Velocities;
        
        % Course Horizontal direction of travel (degrees)
        % Specify the course as an N-element vector, COURSE, at the
        % corresponding waypoints and times. If neither 'Velocities' nor
        % 'Course' are specified, then course is inferred from the
        % waypoints.
        %
        % This property may only be set in the constructor when
        % 'Velocities' is unspecified.
        Course;
        
        % GroundSpeed Groundspeed at each waypoint (m/s)
        % Specify the groundspeed at the corresponding waypoints as an
        % N-element matrix. Specify a positive speed value for forward
        % motion and a negative speed value for reverse motion. A positive
        % speed value cannot be adjacent to a negative speed value and must
        % be separated by at least one zero speed.
        %
        % This property may only be set in the constructor when
        % 'Velocities' is unspecified.
        GroundSpeed;

        % ClimbRate Climbrate at each waypoint (m/s)
        % Specify the climbrate at the corresponding waypoints as an
        % N-element matrix. If it is not specified, then it is inferred from
        % each waypoint.
        %
        % This property may only be set in the constructor when
        % 'Velocities' is unspecified.
        ClimbRate;

        % JerkLimit Longitudinal jerk constraint (m/s^3) 
        % When specified, waypointTrajectory uses a horizontal trapezoidal
        % magnitude acceleration profile between each waypoint using the
        % specified jerk limit.  
        % 
        % This property may not be used while specifying the time-of-arrival
        % instants at each waypoint.
        %
        % If neither JerkLimit or TimeOfArrival are specified, then
        % waypointTrajectory uses horizontal constant magnitude-acceleration 
        % paths between waypoints.
        JerkLimit = NaN;

        % InitialTime Duration before trajectory starts (s)
        % InitialTime is the amount of time before the trajectory begins.
        % Positions, orientations, and their respective derivatives
        % encountered before this time are reported as NaN (not-a-number).
        %
        % This property cannot be used while specifying the time-of-arrival
        % instants at each waypoint. 
        InitialTime (1,1) {mustBeNonnegative} = 0;

        % WaitTime Duration to wait at each waypoint (s)
        % WaitTime pauses the trajectory at the corresponding waypoint.
        % Specify WaitTime as a vector of non-negative values with the same
        % number elements as the number of waypoints. Specify a zero to
        % indicate no wait time is desired. A wait time can only be non-zero
        % when the speed at the corresponding waypoint is set to zero.  
        %
        % This property cannot be used while specifying the time-of-arrival
        % instants at each waypoint. 
        WaitTime;
    end

    properties (Access = private)
        % Rotation matrix orientation at each waypoint
        RotMats;
        % Quaternion orientation at each waypoint
        Quaternions;
        
        GravitationalAcceleration = 9.8
    end
    
    properties (SetAccess = private, Dependent)
        % Orientation Orientation at each waypoint
        % Specify the orientation at the corresponding waypoints as a
        % quaternion N-element vector or a 3-by-3-by-N rotation matrix.
        % Each quaternion or rotation matrix is a frame rotation from the
        % local navigation coordinate system to the current body coordinate
        % system. If it is not specified, then yaw is set to the direction
        % of travel at each waypoint, and pitch and roll are subject to the
        % settings of AutoPitch and AutoBank, respectively.
        %
        % This property may only be set in the constructor.
        Orientation;
    end
    
    properties (SetAccess = private)
        % AutoPitch Align orientation (pitch) with direction of travel.
        % Set AutoPitch to true to automatically align the pitch of the
        % trajectory to the direction of travel.  If set to false, then
        % pitch is set to zero (level orientation).  
        %
        % This property may only be set in the constructor when
        % 'Orientation' is unspecified.
        AutoPitch = false;
        
        % AutoBank Align orientation (roll) to counteract centripetal force
        % Set AutoBank to true to automatically align the roll of the
        % trajectory to counteract centripetal acceleration.  If set to 
        % false, then roll is set to zero (flat orientation).  
        %
        % This property may only be set in the constructor when
        % 'Orientation' is unspecified.
        AutoBank = false;
        
        % ReferenceFrame Axes convention ('NED' or 'ENU')
        % Specify the axes convention used as either 'NED' (north-east-down)
        % or 'ENU' (east-north-up).  
        % The default value is 'NED'.
        ReferenceFrame = 'NED';
    end
    
    properties (Constant, Hidden)
        ReferenceFrameSet = matlab.system.StringSet( ...
            fusion.internal.frames.ReferenceFrame.getOptions);
    end
    
    properties (Nontunable, Access = private)
        IsWaypointsSpecified = false;
        IsTimeOfArrivalSpecified = false;
        IsVelocitiesSpecified = false;
        IsCourseSpecified = false;
        IsGroundSpeedSpecified = false;
        IsClimbRateSpecified = false;
        IsJerkLimitSpecified = false;
        IsInitialTimeSpecified = false;
        IsWaitTimeSpecified = false;
        IsOrientationSpecified = false;
        
        IsOrientationQuaternion = true;
    end
    
    properties (Access = private)
        % Position interpolant parameters.
        HorizontalCumulativeDistance;
        HorizontalDistancePiecewisePolynomial;
        HorizontalSpeedPiecewisePolynomial;
        HorizontalAccelerationPiecewisePolynomial;
        HorizontalJerkPiecewisePolynomial;
        HorizontalCurvatureInitial;
        HorizontalCurvatureFinal;
        HorizontalInitialPosition;
        HorizontalPiecewiseLength;
        VerticalDistancePiecewisePolynomial;
        VerticalSpeedPiecewisePolynomial;
        VerticalAccelerationPiecewisePolynomial;
        VerticalJerkPiecewisePolynomial;
        PathDuration;
        CourseAlignment;

        % Orientation interpolant parameters.
        SegmentTimes;
        RadianSlewAngles;
        AxesOfRotation;
        RadianAngularVelocities;
        ExitCourse;

        % Internal states.
        CurrentTime;
        IsDoneStatus;
    end
    
    properties (Hidden, SetAccess = protected)
        CurrentPosition
        CurrentVelocity
        CurrentAcceleration
        CurrentOrientation
        CurrentAngularVelocity
        CurrentPoseValid = false
    end
    
    methods
        function val = get.Orientation(obj)
            if obj.IsOrientationQuaternion
                val = obj.Quaternions;
            else
                val = obj.RotMats;
            end
        end
        
        function obj = waypointTrajectory(varargin)
            setProperties(obj, varargin{:});
            setupInterpolants(obj);
            obj.CurrentTime = 0;
            setPose(obj, 0);
            obj.IsDoneStatus = false;
        end
        
        function [position, orientation, velocity, acceleration, angularVelocity] = lookupPose(obj, sampleTimes)
            %LOOKUPPOSE - return pose information for a given set of times
            %   [POS, ORIENT, VEL, ACC, ANGVEL] = lookupPose(TRAJ, SAMPTIMES)
            %   returns the pose information for the specified sampleTimes.  
            %   Specify SAMPTIMES as a real-valued vector.  If any individual 
            %   sample time is beyond the valid timerange of the trajectory, 
            %   then the corresponding pose information is returned as NaN.
            validateattributes(sampleTimes,{'double'},{'real','vector','nonnegative'},'','SAMPTIMES');
            [position, orientation, velocity, acceleration, angularVelocity] = lookupPoses(obj, sampleTimes(:));
        end
        
        function set.SampleRate(obj, val)
            validateattributes(val, {'double'}, ...
                {'real','finite','positive','scalar'}, ...
                '', ...
                'SampleRate');
            obj.SampleRate = val;
        end
        
        function set.SamplesPerFrame(obj, val)
            validateattributes(val, {'double'}, ...
                {'real','finite','positive','scalar','integer'}, ...
                '', ...
                'SamplesPerFrame');
            obj.SamplesPerFrame = val;
        end
        
        function offsets = perturb(obj)
            %PERTURB Apply perturbations to the object
            % OFFSETS = PERTURB(OBJ) apply the perturbations defined for
            % the object. Object properties will be perturbed by an offset
            % as defined in the perturbations. See the perturbations
            % method. OFFSETS is a struct with fields Property and Offset,
            % which provide the offset value in this call to perturb.
            
            release(obj);
            offsets = struct('Property', {}, 'Offset', {}, 'PerturbedValue', {});
            for i = 1:numel(obj.pPerturbations)
                perturbation = obj.pPerturbations(i);
                os = offset(obj, perturbation);
                if any(os,'all')
                    obj.(perturbation.Property) = obj.(perturbation.Property) + os;
                    offsets = [offsets; struct(...
                        'Property' , perturbation.Property, ...
                        'Offset', os, ...
                        'PerturbedValue', obj.(perturbation.Property))]; %#ok<AGROW>
                end
            end
            setupInterpolants(obj);
            obj.CurrentTime = 0;
            setPose(obj, 0);
            obj.IsDoneStatus = false;
        end
    end
    
    methods (Access = protected)
        function setProperties(obj, varargin)
            switch numel(varargin)
                case 0
                    setWaypoints(obj, [0 0 0; 0 0 0]);
                    setTimeOfArrival(obj, [0; 1]);
                    obj.IsTimeOfArrivalSpecified = true;
                    obj.WaitTime = zeros(2,1);
                case 1
                    coder.internal.error('shared_sensorsim_trajectories:waypointTrajectory:NeedTimeOfArrivalOrSpeed');
                otherwise
                    codegenTOA = false;
                    param = varargin{1};
                    isValidParam = ( isa(param, 'char') && (size(param, 1) == 1) ) ...
                        || (isa(param, 'string') && isscalar(param) );
                    if ~isValidParam
                        obj.IsWaypointsSpecified = true;
                        setWaypoints(obj, param);
                        param = varargin{2};
                        isValidParam = ( isa(param, 'char') && (size(param, 1) == 1) ) ...
                            || (isa(param, 'string') && isscalar(param) );
                        if ~isValidParam
                            setTimeOfArrival(obj, param);
                            codegenTOA = true;
                            obj.IsTimeOfArrivalSpecified = true;
                            pvPairStartIdx = 3;
                        else
                            pvPairStartIdx = 2;
                        end
                    else
                        pvPairStartIdx = 1;
                    end
                    
                    numArgs = numel(varargin)-(pvPairStartIdx-1);
                    oddNumOfArgs = (rem(numArgs, 2) ~= 0);
                    coder.internal.errorIf(oddNumOfArgs, ...
                        'MATLAB:system:invalidPVPairs');
                    for i=pvPairStartIdx:2:numel(varargin)
                        param = varargin{i};
                        isValidParam = ( isa(param, 'char') && (size(param, 1) == 1) ) ...
                            || (isa(param, 'string') && isscalar(param) );
                        coder.internal.errorIf(~isValidParam, 'MATLAB:system:invalidPVPairs');
                        val = varargin{i+1};
                        switch param
                            case 'Waypoints'
                                setWaypoints(obj, val);
                                obj.IsWaypointsSpecified = true;
                            case 'TimeOfArrival'
                                setTimeOfArrival(obj, val);
                                codegenTOA = true;
                                obj.IsTimeOfArrivalSpecified = true;
                            case 'Velocities'
                                setVelocities(obj, val);
                                obj.IsVelocitiesSpecified = true;
                            case 'Course'
                                setCourse(obj, val);
                                obj.IsCourseSpecified = true;
                            case 'GroundSpeed'
                                setGroundSpeed(obj, val);
                                obj.IsGroundSpeedSpecified = true;
                            case 'ClimbRate'
                                setClimbRate(obj, val);
                                obj.IsClimbRateSpecified = true;
                            case 'JerkLimit'
                                setJerkLimit(obj, val);
                                obj.IsJerkLimitSpecified = true;
                            case 'InitialTime'
                                setInitialTime(obj, val);
                                obj.IsInitialTimeSpecified = true;
                            case 'WaitTime'
                                setWaitTime(obj, val);
                                obj.IsWaitTimeSpecified = true;
                            case 'Orientation'
                                setOrientation(obj, val);
                                obj.IsOrientationSpecified = true;
                            case 'AutoBank'
                                setAutoBank(obj, val);
                            case 'AutoPitch'
                                setAutoPitch(obj, val);
                            case 'ReferenceFrame'
                                setReferenceFrame(obj, val);
                            otherwise
                                % Set public property.
                                matlabshared.fusionutils.internal.setProperties(obj, 2, param, val);
                        end
                    end

                    % check required set.
                    if ~obj.IsWaypointsSpecified && ~codegenTOA && ~obj.IsVelocitiesSpecified && ~obj.IsGroundSpeedSpecified && ~obj.IsOrientationSpecified
                        % legacy constructor
                        setWaypoints(obj, [0 0 0; 0 0 0]);
                        setTimeOfArrival(obj, [0; 1]);
                        obj.IsTimeOfArrivalSpecified = true;
                    elseif ~obj.IsWaypointsSpecified
                        coder.internal.error('shared_sensorsim_trajectories:waypointTrajectory:WaypointsRequired');
                    elseif ~obj.IsTimeOfArrivalSpecified && ~obj.IsVelocitiesSpecified && ~obj.IsGroundSpeedSpecified
                        coder.internal.error('shared_sensorsim_trajectories:waypointTrajectory:NeedTimeOfArrivalOrSpeed');
                    elseif obj.IsTimeOfArrivalSpecified && obj.IsJerkLimitSpecified
                        coder.internal.error('shared_sensorsim_trajectories:waypointTrajectory:IncompatibleTimeOfArrivalJerkLimit')
                    elseif obj.IsTimeOfArrivalSpecified && obj.IsInitialTimeSpecified
                        coder.internal.error('shared_sensorsim_trajectories:waypointTrajectory:IncompatibleTimeOfArrivalInitialTime')
                    elseif obj.IsTimeOfArrivalSpecified && obj.IsWaitTimeSpecified
                        coder.internal.error('shared_sensorsim_trajectories:waypointTrajectory:IncompatibleTimeOfArrivalWaitTime')
                    end
                    validateWaypointSizes(obj);
                    validateWaitTime(obj);
                    validateJerkLimit(obj);
            end
        end
        
        % Private Set Methods 
        function setWaypoints(obj, val)
            validateattributes(val, {'double'}, ...
                {'ncols', 3, '2d', 'real', 'finite'}, ...
                '', ...
                'Waypoints');
            coder.internal.assert(size(val, 1) > 1, ...
                'shared_sensorsim_trajectories:waypointTrajectory:InsufficientWaypoints');

            obj.Waypoints = val;
        end
        
        function setTimeOfArrival(obj, val)
            validateattributes(val, ...
                {'double'}, ...
                {'finite', 'real', 'nonnegative', 'increasing', 'vector'}, ...
                '', ...
                'TimeOfArrival');
            % Ensure it is a column vector.
            obj.TimeOfArrival = val(:);
        end
        
        function setGroundSpeed(obj, val)
            validateattributes(val, ...
                {'double'}, ...
                {'finite', 'real', 'vector'}, ...
                '', ...
                'GroundSpeed');
            dir = sign(val);
            if any(dir(1:end-1)==-dir(2:end) & dir(1:end-1) ~= 0)
                coder.internal.error('shared_sensorsim_trajectories:waypointTrajectory:InvalidGroundSpeedSignChange')
            end
            obj.GroundSpeed = val(:);
        end
        
        function setClimbRate(obj, val)
            validateattributes(val, ...
                {'double'}, ...
                {'finite', 'real', 'vector'}, ...
                '', ...
                'ClimbRate');
            obj.ClimbRate = val(:);
        end
                
        function setJerkLimit(obj, val)
            validateattributes(val, ...
                {'double'}, ...
                {'finite', 'real', 'nonnegative', 'vector'}, ...
                '', ...
                'JerkLimit');
            obj.JerkLimit = val(:);
        end
                
        function setInitialTime(obj, val)
            validateattributes(val, ...
                {'double'}, ...
                {'finite', 'real', 'nonnegative', 'scalar'}, ...
                '', ...
                'InitialTime');
            obj.InitialTime = val;
        end

        function setWaitTime(obj, val)
            validateattributes(val, ...
                {'double'}, ...
                {'finite', 'real', 'nonnegative', 'vector'}, ...
                '', ...
                'WaitTime');
            coder.internal.errorIf(any(val(2:end)~=0 & val(1:end-1)~=0), ...
                'shared_sensorsim_trajectories:waypointTrajectory:WaitTimeNotAllowedAtImmediateWaypoints');
            obj.WaitTime = val(:);
        end
                
        function setVelocities(obj, val)
            validateattributes(val, ...
                {'double'}, ...
                {'ncols', 3, '2d', 'real', 'finite'}, ...
                '', ...
                'Velocities');
            obj.Velocities = val;
            obj.CurrentPoseValid = false;
        end
        
        function setCourse(obj, val)
            validateattributes(val, ...
                {'double'}, ...
                {'vector', 'real'}, ...
                '', ...
                'Course');
            obj.Course = val(:);
            obj.CurrentPoseValid = false;
        end            
        
        function setOrientation(obj, val)
            coder.internal.errorIf(obj.AutoBank, 'shared_sensorsim_trajectories:waypointTrajectory:IncompatibleOrientationAutoBank');
            coder.internal.errorIf(obj.AutoPitch, 'shared_sensorsim_trajectories:waypointTrajectory:IncompatibleOrientationAutoPitch');
            isQuat = isa(val, 'quaternion');
            if isQuat
                validateattributes(parts(val), ...
                    {'double'}, ...
                    {'ncols', 1, '2d'}, ...
                    '', ...
                    'Orientation');
                validateattributes(compact(val), ...
                    {'double'}, ...
                    {'real', 'finite'}, ...
                    '', ...
                    'Orientation');
                obj.Quaternions = val;
                obj.RotMats = rotmat(val, 'frame');
            else
                validateattributes(val, ...
                    {'double'}, ...
                    {'real','finite', 'size', [3 3 NaN]}, ...
                    '', ...
                    'Orientation');
                obj.Quaternions = quaternion(val, 'rotmat', 'frame');
                obj.RotMats = val;
            end
            obj.IsOrientationQuaternion = isQuat;
            obj.CurrentPoseValid = false;
        end
        
        function setAutoPitch(obj, val)
            coder.internal.errorIf(obj.IsOrientationSpecified, 'shared_sensorsim_trajectories:waypointTrajectory:IncompatibleOrientationAutoPitch');
            validateattributes(val,{'logical'},{'scalar'},'','AutoPitch');
            obj.AutoPitch = val;
            obj.CurrentPoseValid = false;
        end
        
        function setAutoBank(obj, val)
            coder.internal.errorIf(obj.IsOrientationSpecified, 'shared_sensorsim_trajectories:waypointTrajectory:IncompatibleOrientationAutoBank');
            validateattributes(val,{'logical'},{'scalar'},'','AutoBank');
            obj.AutoBank = val;
            obj.CurrentPoseValid = false;
        end
        
        function setReferenceFrame(obj, val)
            % System object provides own parameter validation
            obj.ReferenceFrame = val;
        end
        
        function validateWaypointSizes(obj)
            n = size(obj.Waypoints, 1);
            if obj.IsTimeOfArrivalSpecified
                validateattributes(obj.TimeOfArrival, ...
                    {'double'}, ...
                    {'numel', n}, ...
                    '', ...
                    'TimeOfArrival');
            end
            
            if obj.IsVelocitiesSpecified
                validateattributes(obj.Velocities, ...
                    {'double'}, ...
                    {'nrows', n}, ...
                    '', ...
                    'Velocities');
            end
            
            if obj.IsGroundSpeedSpecified
                validateattributes(obj.GroundSpeed, ...
                    {'double'}, ...
                    {'nrows', n}, ...
                    '', ...
                    'GroundSpeed');
            end
            
            if obj.IsClimbRateSpecified
                validateattributes(obj.ClimbRate, ...
                    {'double'}, ...
                    {'nrows', n}, ...
                    '', ...
                    'ClimbRate');
            end
            
            if obj.IsCourseSpecified
                validateattributes(obj.Course, ...
                    {'double'}, ...
                    {'nrows', n}, ...
                    '', ...
                    'Course');
            end
            
            if obj.IsOrientationSpecified
                if obj.IsOrientationQuaternion
                    validateattributes(parts(obj.Quaternions), ...
                        {'double'}, ...
                        {'nrows', n}, ...
                        '', ...
                        'Orientation');
                else
                    validateattributes(obj.RotMats, ...
                        {'double'}, ...
                        {'size', [NaN NaN n]}, ...
                        '', ...
                        'Orientation');
                end
            end

            if obj.IsWaitTimeSpecified
                validateattributes(obj.WaitTime, ...
                    {'double'}, ...
                    {'nrows', n}, ...
                    '', ...
                    'WaitTime');
            else
                obj.WaitTime = zeros(n,1);
            end                    
        end

        function validateWaitTime(obj)
            if obj.IsWaitTimeSpecified
                idx = find(obj.WaitTime ~= 0);
                if obj.IsGroundSpeedSpecified
                    coder.internal.errorIf(any(obj.GroundSpeed(idx) ~= 0), ...
                        'shared_sensorsim_trajectories:waypointTrajectory:CannotWaitAtNonZeroGroundSpeed');
                end
                if obj.IsClimbRateSpecified
                    coder.internal.errorIf(any(obj.ClimbRate(idx) ~= 0), ...
                        'shared_sensorsim_trajectories:waypointTrajectory:CannotWaitAtNonZeroClimbRate');
                end
                if obj.IsVelocitiesSpecified
                    coder.internal.errorIf(any(obj.Velocities(idx, :) ~= 0,'all'), ...
                        'shared_sensorsim_trajectories:waypointTrajectory:CannotWaitAtNonZeroVelocity');
                end                        
            end
        end

        function validateJerkLimit(obj)
            if ~obj.IsJerkLimitSpecified && ~obj.IsTimeOfArrivalSpecified
                obj.JerkLimit = Inf;
            end
        end

        function flag = isInactivePropertyImpl(obj, prop)
            flag = obj.IsTimeOfArrivalSpecified && ...
                any(strcmp(prop,{'JerkLimit','InitialTime','WaitTime'}));
        end

        function beginTrajectory(obj)
            obj.CurrentTime = 0;
            setPose(obj, 0);
            obj.IsDoneStatus = false;
        end

        function setupImpl(obj)
            beginTrajectory(obj);
        end
        
        function resetImpl(obj)
            beginTrajectory(obj);
        end
        
        function [position, orientation, velocity, acceleration, angularVelocity] = stepImpl(obj)
            t = obj.CurrentTime;
            dt = 1/obj.SampleRate;
            spf = obj.SamplesPerFrame;
            
            position = zeros(spf, 3);
            q = quaternion.ones(spf, 1);
            velocity = zeros(spf, 3);
            angularVelocity = zeros(spf, 3);
            acceleration = zeros(spf, 3);
            if ~isDone(obj)
                for i = 1:obj.SamplesPerFrame
                    t = t + dt;
                    [position(i,:), q(i,:), velocity(i,:), angularVelocity(i,:), acceleration(i,:)] = setPose(obj, t);
                end
                if ~isDone(obj)
                    obj.CurrentTime = t;
                    if (t+dt) > obj.PathDuration
                        obj.IsDoneStatus = true;
                    end
                end
            else
                position = nan(spf,3);
                q = nan * quaternion.ones(spf, 1);
                velocity = nan(spf,3);
                angularVelocity = nan(spf,3);
                acceleration = nan(spf,3);
                obj.CurrentPosition = nan(1,3);
                obj.CurrentVelocity = nan(1,3);
                obj.CurrentAcceleration = nan(1,3);
                obj.CurrentAngularVelocity = nan(1,3);
                obj.CurrentOrientation = nan * quaternion.ones;
            end
                
            if obj.IsOrientationQuaternion
                orientation = q;
            else
                orientation = rotmat(q, 'frame');
            end
        end
        
        function status = isDoneImpl(obj)
            status = obj.IsDoneStatus;
        end
        
        function setupInterpolants(obj)
            setupCourseAlignment(obj);
            setupPositionInterpolant(obj);
            setupOrientationInterpolant(obj);
            setupWaypointParams(obj);
            obj.CurrentPoseValid = true;
        end
        
        function setupCourseAlignment(obj)
            % by default align with course
            n = size(obj.Waypoints,1);
            obj.CourseAlignment = ones(n,1);

            if obj.IsGroundSpeedSpecified
                alignment = sign(obj.GroundSpeed);

                % ensure proper direction when starting from rest
                idx = find(alignment ~= 0,1,"first");
                if isempty(idx)
                    % use default alignment if no velocities used
                    alignment = ones(n,1);
                else
                    % provide hint to MATLAB Coder
                    alignment(1:idx(1)-1) = alignment(idx(1));
                end

                % place any cusp at the last zero
                idx = find(alignment(1:end-1)==0 & alignment(2:end)~=0);
                alignment(idx) = alignment(idx+1);

                initAlign = alignment(1);
                for i=1:n
                    if alignment(i) == 0
                        alignment(i) = initAlign;
                    else
                        initAlign = alignment(i);
                    end
                end
                obj.CourseAlignment = alignment;
            end
        end

        function [hpp, t] = getHorizontalDistancePolynomialViaTimeOfArrival(obj)
            t = obj.TimeOfArrival;
            hcd = obj.HorizontalCumulativeDistance;
            if obj.IsVelocitiesSpecified
                gndspeed = vecnorm(obj.Velocities(:,1:2), 2, 2);
                hpp = matlabshared.tracking.internal.scenario.chermite(t, hcd, gndspeed);
            elseif obj.IsGroundSpeedSpecified
                gndspeed = obj.GroundSpeed;
                hpp = matlabshared.tracking.internal.scenario.chermite(t, hcd, abs(gndspeed));
            else
                hpp = pchip(t, hcd);
            end
        end

        function [hpp, t] = getHorizontalDistancePolynomialViaTrapezodalAcceleration(obj)
            % Get the piecewise polynomial to evaluate d(t).
            if obj.IsVelocitiesSpecified
                gndspeed = vecnorm(obj.Velocities(:,1:2), 2, 2);
            else
                coder.internal.assert(obj.IsGroundSpeedSpecified,'shared_sensorsim_trajectories:waypointTrajectory:NeedTimeOfArrivalOrSpeed');
                gndspeed = abs(obj.GroundSpeed);
            end

            hl = obj.HorizontalPiecewiseLength;

            [hpp, segt] = matlabshared.tracking.internal.scenario.mktrapp(hl, gndspeed, obj.JerkLimit, obj.InitialTime, obj.WaitTime);
            t = cumsum([0;segt]) + obj.InitialTime;
        end

        function [hpp, t] = getHorizontalDistancePolynomialViaConstantAcceleration(obj)
            % constant acceleration paths
            hl = obj.HorizontalPiecewiseLength;

            % Get the piecewise polynomial to evaluate d(t).
            if obj.IsVelocitiesSpecified
                gndspeed = vecnorm(obj.Velocities(:,1:2), 2, 2);
            else
                coder.internal.assert(obj.IsGroundSpeedSpecified,'shared_sensorsim_trajectories:waypointTrajectory:NeedTimeOfArrivalOrSpeed');
                gndspeed = abs(obj.GroundSpeed);
            end
            [hpp, t] = matlabshared.tracking.internal.scenario.mkcapp(hl, gndspeed, obj.InitialTime, obj.WaitTime);
        end

        function setupHorizontalInterpolant(obj)
            setupHorizontalPath(obj);
            setupHorizontalSpeedProfile(obj);
        end

        function setCourseProperties(obj, exitCourse)
            % ExitCourse describes course as exiting from the corresponding
            % waypoint (but entering the last waypoint).
            obj.ExitCourse = exitCourse;
            cusps = 1+find(obj.CourseAlignment(1:end-1)==-obj.CourseAlignment(2:end));
            course = exitCourse;
            % Course describes the exit angle from the first waypoint, and
            % entrance angle of subsequent waypoints.
            course(cusps) = mod(course(cusps),360)-180;
            obj.Course = course;
        end

        function setupHorizontalPath(obj)
            
            % Find the course angles at the start of each segment.
            % mark missing course information with NaN
            if obj.IsVelocitiesSpecified
                z = complex(obj.Velocities(:,1), obj.Velocities(:,2));
                course = angle(z);
                course(z==0) = NaN;
            elseif obj.IsCourseSpecified
                course = deg2rad(obj.Course);
            else
                course = nan(size(obj.Waypoints,1),1);
            end
            
            % get any ground reversals
            cusps = 1+find(obj.CourseAlignment(1:end-1)==-obj.CourseAlignment(2:end));

            % compute the arclength parameterization
            waypoints = obj.Waypoints;
            [k0, k1, hl, hip, hcd, course] = matlabshared.tracking.internal.scenario.mkpcc(waypoints, course, cusps);

            % Save results.
            obj.HorizontalCumulativeDistance = hcd;
            obj.HorizontalCurvatureInitial = k0;
            obj.HorizontalCurvatureFinal = k1;
            obj.HorizontalInitialPosition = hip;
            obj.HorizontalPiecewiseLength = hl;
            setCourseProperties(obj, rad2deg(course));
        end

        function setupHorizontalSpeedProfile(obj)
            if obj.IsTimeOfArrivalSpecified
                [hpp, t] = getHorizontalDistancePolynomialViaTimeOfArrival(obj);
                % codegen prohibits TimeOfArrival from being set more than once.
                pathDuration = t(end);
            elseif obj.IsJerkLimitSpecified
                [hpp, t] = getHorizontalDistancePolynomialViaTrapezodalAcceleration(obj);
                coder.internal.errorIf(any(isnan(t)), ...
                    'shared_sensorsim_trajectories:waypointTrajectory:OverconstrainedSpeedProfile');
                obj.TimeOfArrival = t;
                pathDuration = t(end) + obj.WaitTime(end);
            else
                [hpp, t] = getHorizontalDistancePolynomialViaConstantAcceleration(obj);
                obj.TimeOfArrival = t;
                pathDuration = t(end) + obj.WaitTime(end);
            end

            % Cache the piecewise polynomial derivatives with respect to length.
            hspp = matlabshared.tracking.internal.scenario.derivpp(hpp);
            happ = matlabshared.tracking.internal.scenario.derivpp(hspp);
            hjpp = matlabshared.tracking.internal.scenario.derivpp(happ);

            % save to object
            obj.HorizontalDistancePiecewisePolynomial = hpp;
            obj.HorizontalSpeedPiecewisePolynomial = hspp;
            obj.HorizontalAccelerationPiecewisePolynomial = happ;
            obj.HorizontalJerkPiecewisePolynomial = hjpp;
            obj.PathDuration = pathDuration;
        end

        function setupPositionInterpolant(obj)
            setupHorizontalInterpolant(obj);
            setupVerticalInterpolant(obj);
        end

        function setupVerticalInterpolant(obj)
            % Get the piecewise polynomial for elevation.
            waypoints = obj.Waypoints;
            t = obj.TimeOfArrival;

            if obj.IsVelocitiesSpecified
                vpp = matlabshared.tracking.internal.scenario.chermite(t, waypoints(:,3), obj.Velocities(:,3));
            elseif obj.IsClimbRateSpecified
                if strcmp(obj.ReferenceFrame,'NED')
                    rate = -obj.ClimbRate;
                else
                    rate = obj.ClimbRate;
                end
                vpp = matlabshared.tracking.internal.scenario.chermite(t, waypoints(:,3), rate);
            else
                vpp = pchip(t, waypoints(:,3));
            end
            
            % Cache the piecewise polynomial derivatives with respect
            % to length.
            vspp = matlabshared.tracking.internal.scenario.derivpp(vpp);
            vapp = matlabshared.tracking.internal.scenario.derivpp(vspp);
            vjpp = matlabshared.tracking.internal.scenario.derivpp(vapp);
            
            % Save results.
            obj.VerticalDistancePiecewisePolynomial = vpp;
            obj.VerticalSpeedPiecewisePolynomial = vspp;
            obj.VerticalAccelerationPiecewisePolynomial = vapp;
            obj.VerticalJerkPiecewisePolynomial = vjpp;
        end
        
        function setupOrientationInterpolant(obj)
            if obj.IsOrientationSpecified
                q = obj.Quaternions;
                t = obj.TimeOfArrival;
                wi = [0 0 0];
                wf = [0 0 0];
                maxit = 10;
                tol = 1e-9;
                [h,dtheta,e,w] = fusion.scenario.internal.quaternionC2fit(q,t,wi,wf,maxit,tol);
                
                % Save results.
                obj.SegmentTimes = h;
                obj.RadianSlewAngles = dtheta;
                obj.AxesOfRotation = e;
                obj.RadianAngularVelocities = w;
            end
        end
        
        function setupWaypointParams(obj)
            t = obj.TimeOfArrival;
            if ~obj.IsVelocitiesSpecified
                course = obj.Course;
                gndspeed = ppval(obj.HorizontalSpeedPiecewisePolynomial,t);
                rate = ppval(obj.VerticalSpeedPiecewisePolynomial,t);
                obj.Velocities = horzcat(cosd(course).*gndspeed, sind(course).*gndspeed, rate);
            end
            
            if ~obj.IsGroundSpeedSpecified
                gndspeed = ppval(obj.HorizontalSpeedPiecewisePolynomial,t);
                obj.GroundSpeed = gndspeed;
            end
            
            if ~obj.IsClimbRateSpecified
                velocity = obj.Velocities;
                if strcmp(obj.ReferenceFrame,'NED')
                    obj.ClimbRate = -velocity(:,3);
                else
                    obj.ClimbRate = velocity(:,3);
                end
            end
           
            if ~obj.IsOrientationSpecified
                [~, orientation] = lookupPoses(obj, t);
                obj.Quaternions = orientation;
                obj.RotMats = rotmat(orientation,'frame');
            end
        end
        
        function [position, orientation, velocity, acceleration, angularVelocity, jerk] = lookupPoses(obj, simulationTimes)
            % pre-initialize to NaN
            n = length(simulationTimes);
            position = nan(n,3);
            orientation = nan * quaternion.ones(n,1);
            velocity = nan(n,3);
            angularVelocity = nan(n,3);
            acceleration = nan(n,3);
            jerk = nan(n,3);

            % filter out times beyond given range
            ivalid = find(obj.TimeOfArrival(1) <= simulationTimes & simulationTimes <= obj.TimeOfArrival(end));

            if ~isempty(ivalid)
                if ~obj.IsOrientationSpecified
                    L_1 = nan(n,1); % 1st deriv of longitudinal distance
                    L_2 = nan(n,1); % 2nd
                    L_3 = nan(n,1); % 3rd
                    V_1 = nan(n,1); % 1st deriv of vertical elevation
                    V_2 = nan(n,1); % 2nd
                    V_3 = nan(n,1); % 3rd 
                    T_0 = nan(n,1,'like',1i); % unit tangent in (horizontal) complex plane
                    T_1 = nan(n,1,'like',1i); % derivative of unit tangent
                    segIdx = zeros(n,1);      % index of active clothoid segment

                    % get positioning
                    % provide hints to MATLAB Coder
                    [position(ivalid,:), velocity(ivalid,:), acceleration(ivalid,:), jerk(ivalid,:), ...
                        segIdx(ivalid,:), ...
                        ~, L_1(ivalid,:), L_2(ivalid,:), L_3(ivalid,:), ...
                        ~, V_1(ivalid,:), V_2(ivalid,:), V_3(ivalid,:), ...
                        T_0(ivalid,:), T_1(ivalid,:)] = fetchPosition(obj, simulationTimes(ivalid));
    
                    % get orientation with differentially-flat model
                    % provide hints to MATLAB Coder
                    [orientation(ivalid,:), angularVelocity(ivalid,:)] = fetchOrientationFromPath(obj, ...
                        velocity(ivalid,:), acceleration(ivalid,:), jerk(ivalid,:), ...
                        segIdx(ivalid,:), ...
                            T_0(ivalid,:), T_1(ivalid,:), ...
                            V_1(ivalid,:), L_1(ivalid,:), ...
                            V_2(ivalid,:), L_2(ivalid,:), ...
                            V_3(ivalid,:), L_3(ivalid,:));
                    
                else
                    % get positioning
                    [position(ivalid,:), velocity(ivalid,:), acceleration(ivalid,:), jerk(ivalid,:)] = fetchPosition(obj, simulationTimes(ivalid));

                    % get orientation via cubic quaternion spline
                    [orientation(ivalid), angularVelocity(ivalid,:)] = fetchOrientationFromQuaternions(obj, simulationTimes(ivalid));
                end
            end
        end

        
        function [position, orientation, velocity, angularVelocity, acceleration, jerk] = setPose(obj, simulationTime)
            % interpolate motion from piecewise model
            if obj.TimeOfArrival(1) <= simulationTime && simulationTime <= obj.TimeOfArrival(end)
                
                if ~obj.IsOrientationSpecified
                    % get positioning
                    [position, velocity, acceleration, jerk, segIdx, ~, L_1, L_2, L_3, ~, V_1, V_2, V_3, T_0, T_1] = fetchPosition(obj, simulationTime);

                    % get orientation via differentially-flat model
                    [orientation, angularVelocity] = fetchOrientationFromPath(obj, velocity, acceleration, jerk, segIdx, ...
                            T_0, T_1, V_1, L_1, V_2, L_2, V_3, L_3);
                else
                    % get positioning
                    [position, velocity, acceleration, jerk] = fetchPosition(obj, simulationTime);

                    % get orientation via cubic quaternion spline
                    [orientation, angularVelocity] = fetchOrientationFromQuaternions(obj, simulationTime);
                end
            else
                position = nan(1,3);
                orientation = nan * quaternion.ones;
                velocity = nan(1,3);
                angularVelocity = nan(1,3);
                acceleration = nan(1,3);
                if simulationTime > obj.TimeOfArrival(end)
                    obj.IsDoneStatus = true;
                end
            end
            
            obj.CurrentPosition = position;
            obj.CurrentVelocity = velocity;
            obj.CurrentAcceleration = acceleration;
            obj.CurrentAngularVelocity = angularVelocity;
            obj.CurrentOrientation = orientation;
        end
        
        function [position, velocity, acceleration, jerk, ...
                segIdx, L_0, L_1, L_2, L_3, pz, vz, az, jz, T_0, T_1] = fetchPosition(obj, simulationTime)
            hcd = obj.HorizontalCumulativeDistance;
            hpp = obj.HorizontalDistancePiecewisePolynomial;
            hspp = obj.HorizontalSpeedPiecewisePolynomial;
            happ = obj.HorizontalAccelerationPiecewisePolynomial;
            hjpp = obj.HorizontalJerkPiecewisePolynomial;
            k0 = obj.HorizontalCurvatureInitial;
            k1 = obj.HorizontalCurvatureFinal;
            hip = obj.HorizontalInitialPosition;
            hl = obj.HorizontalPiecewiseLength;
            vpp = obj.VerticalDistancePiecewisePolynomial;
            vspp = obj.VerticalSpeedPiecewisePolynomial;
            vapp = obj.VerticalAccelerationPiecewisePolynomial;
            vjpp = obj.VerticalJerkPiecewisePolynomial;
            course = deg2rad(obj.ExitCourse);

            % interpolate in the complex plane:
            %   horizontal position, velocity, acceleration, and jerk.
            %   longitudinal distance (curvelength), velocity, acceleration, and jerk.
            %   unit tangent vector and its derivative.
            [ph, vh, ah, jh, segIdx, L_0, L_1, L_2, L_3, T_0, T_1] ...
                = matlabshared.tracking.internal.scenario.evaltpcc( ...
                hcd, hip, hl, k0, k1, course, hpp, hspp, happ, hjpp, simulationTime);

            % interpolate vertical z-position and derivatives based upon
            % simulation time
            pz = ppval(vpp, simulationTime);
            vz = ppval(vspp, simulationTime);
            az = ppval(vapp, simulationTime);
            jz = ppval(vjpp, simulationTime);

            % assemble the 3D positions
            position = [real(ph) imag(ph) pz];
            velocity = [real(vh) imag(vh) vz];
            acceleration = [real(ah) imag(ah) az];
            jerk = [real(jh) imag(jh) jz];
        end
        
        function [q, radianAngularVelocity] = fetchOrientationFromQuaternions(obj,t)
            y = obj.Quaternions;
            h = obj.SegmentTimes;
            dtheta = obj.RadianSlewAngles;
            e = obj.AxesOfRotation;
            w = obj.RadianAngularVelocities;
            x = obj.TimeOfArrival;
            [q, angularVelocityBodyFrame] = fusion.scenario.internal.getOrientationState(t, x, y, h, dtheta, e, w);
            m = rotmat(q, 'frame');
            radianAngularVelocity = angularVelocityBodyFrame;
            for i=1:length(q)
               radianAngularVelocity(i,:) = angularVelocityBodyFrame(i,:)*m(:,:,i);
            end
        end
        
        function [orientation, angularVelocity] = fetchOrientationFromPath(obj, velocity, acceleration, jerk, segIdx, ...
                hut, dhut, vs, hs, va, ha, vj, hj)
            %  segIdx     - index into corresponding clothoid segment
            %  hut, dhut, - horizontal unit tangent in complex plane.  its derivative.
            %  vs, hs,    - vertical speed (climbrate) and horizontal speed in complex plane.  
            %  va, ha,    - vertical and horizontal sign-magnitude acceleration
            %  vj, hj,    - vertical and horizontal sign-magnitude jerk

            if strcmp(obj.ReferenceFrame,'NED')
                g = [ 0 0 obj.GravitationalAcceleration];
            else
                g = [ 0 0 -obj.GravitationalAcceleration];
            end
            
            [orientation, angularVelocity] = fusion.scenario.internal.getOrientationFromPath( ...
                        velocity, acceleration, jerk, obj.AutoPitch, obj.AutoBank, g, ...
                        obj.CourseAlignment(segIdx), hut, dhut, vs, hs, va, ha, vj, hj);
        end
        
        function s = saveObjectImpl(obj)
            % Save public properties.
            s = saveObjectImpl@matlab.System(obj);
            
            % Save perturbation related properties
            s = savePerts(obj, s);
            
            % Save private properties created during construction.
            s.Waypoints = obj.Waypoints;
            s.TimeOfArrival = obj.TimeOfArrival;
            s.Velocities = obj.Velocities;
            s.RotMats = obj.RotMats;
            s.Quaternions = obj.Quaternions;
            s.ReferenceFrame = obj.ReferenceFrame;
            s.AutoBank = obj.AutoBank;
            s.AutoPitch = obj.AutoPitch;
            s.GroundSpeed = obj.GroundSpeed;
            s.ClimbRate = obj.ClimbRate;
            s.JerkLimit = obj.JerkLimit;
            s.InitialTime = obj.InitialTime;
            s.WaitTime = obj.WaitTime;
            
            s.IsWaypointsSpecified = obj.IsWaypointsSpecified;
            s.IsTimeOfArrivalSpecified = obj.IsTimeOfArrivalSpecified;
            s.IsVelocitiesSpecified = obj.IsVelocitiesSpecified;
            s.IsCourseSpecified = obj.IsCourseSpecified;
            s.IsGroundSpeedSpecified = obj.IsGroundSpeedSpecified;
            s.IsClimbRateSpecified = obj.IsClimbRateSpecified;
            s.IsJerkLimitSpecified = obj.IsJerkLimitSpecified;
            s.IsInitialTimeSpecified = obj.IsInitialTimeSpecified;
            s.IsWaitTimeSpecified = obj.IsWaitTimeSpecified;
            s.IsOrientationSpecified = obj.IsOrientationSpecified;
            s.IsOrientationQuaternion = obj.IsOrientationQuaternion;
            
            s.CurrentPoseValidStatus = obj.CurrentPoseValid;
            
            % Save private properties. 
            s.HorizontalCumulativeDistance = obj.HorizontalCumulativeDistance;
            s.HorizontalDistancePiecewisePolynomial = obj.HorizontalDistancePiecewisePolynomial;
            s.HorizontalSpeedPiecewisePolynomial = obj.HorizontalSpeedPiecewisePolynomial;
            s.HorizontalAccelerationPiecewisePolynomial = obj.HorizontalAccelerationPiecewisePolynomial;
            s.HorizontalJerkPiecewisePolynomial = obj.HorizontalJerkPiecewisePolynomial;
            s.HorizontalCurvatureInitial = obj.HorizontalCurvatureInitial;
            s.HorizontalCurvatureFinal = obj.HorizontalCurvatureFinal;
            s.HorizontalInitialPosition = obj.HorizontalInitialPosition;
            s.HorizontalPiecewiseLength = obj.HorizontalPiecewiseLength;
            s.VerticalDistancePiecewisePolynomial = obj.VerticalDistancePiecewisePolynomial;
            s.VerticalSpeedPiecewisePolynomial = obj.VerticalSpeedPiecewisePolynomial;
            s.VerticalAccelerationPiecewisePolynomial = obj.VerticalAccelerationPiecewisePolynomial;
            s.VerticalJerkPiecewisePolynomial = obj.VerticalJerkPiecewisePolynomial;
            s.Course = obj.Course;
            s.ExitCourse = obj.ExitCourse;
            s.CourseAlignment = obj.CourseAlignment;
            s.PathDuration = obj.PathDuration;

            s.SegmentTimes = obj.SegmentTimes;
            s.RadianSlewAngles = obj.RadianSlewAngles;
            s.AxesOfRotation = obj.AxesOfRotation;
            s.RadianAngularVelocities = obj.RadianAngularVelocities;

            s.CurrentTime = obj.CurrentTime;
            s.IsDoneStatus = obj.IsDoneStatus;
            
            s.CurrentPosition = obj.CurrentPosition;
            s.CurrentVelocity = obj.CurrentVelocity;
            s.CurrentAcceleration = obj.CurrentAcceleration;
            s.CurrentOrientation = obj.CurrentOrientation;
            s.CurrentAngularVelocity = obj.CurrentAngularVelocity;
            s.CurrentPoseValid = obj.CurrentPoseValid;
        end
        
        function loadObjectImpl(obj, s, wasLocked)
            % Load public properties. 
            loadObjectImpl@matlab.System(obj, s, wasLocked);
            
            % Load perturbation related properties
            loadPerts(obj, s);
            
            % Load private properties created during construction.
            obj.Waypoints = s.Waypoints;
            obj.TimeOfArrival = s.TimeOfArrival;
            obj.Velocities = s.Velocities;
            obj.RotMats = s.RotMats;
            obj.Quaternions = s.Quaternions;
            loadprop(obj,s,'ReferenceFrame');
            loadprop(obj,s,'AutoBank');
            loadprop(obj,s,'AutoPitch');
            loadprop(obj,s,'GroundSpeed');
            loadprop(obj,s,'ClimbRate');
            loadprop(obj,s,'JerkLimit');
            loadprop(obj,s,'InitialTime');
            loadprop(obj,s,'WaitTime');

            obj.IsWaypointsSpecified = s.IsWaypointsSpecified;

            % are we after R2023a?
            if isfield(s,'IsJerkLimitSpecified')
                % use new definition of is time of arrival
                obj.IsTimeOfArrivalSpecified = s.IsTimeOfArrivalSpecified;
            else
                % redefine to always be true for the older versions
                obj.IsTimeOfArrivalSpecified = true;
            end

            obj.IsVelocitiesSpecified = s.IsVelocitiesSpecified;
            loadprop(obj,s,'IsCourseSpecified');
            loadprop(obj,s,'IsGroundSpeedSpecified');
            loadprop(obj,s,'IsClimbRateSpecified');
            loadprop(obj,s,'IsJerkLimitSpecified');
            loadprop(obj,s,'IsWaitTimeSpecified');
            obj.IsOrientationSpecified = s.IsOrientationSpecified;
            obj.IsOrientationQuaternion = s.IsOrientationQuaternion;
                
            s.CurrentPoseValidStatus = obj.CurrentPoseValid;
            
            if isfield(s,'IsCourseSpecified') || wasLocked

                if isfield(s,'CourseAlignment')
                    % R2022b has course-alignment
                    obj.CourseAlignment = s.CourseAlignment;
                else
                    % R2022a and earlier have only forward-alignment
                    obj.CourseAlignment = ones(size(s.Waypoints,1),1);
                end

                if isfield(s,'IsCourseSpecified')
                    % R2020a has course as read-only, public
                    course = s.Course;
                else
                    % R2019b and earlier specifies course as private property in radians
                    course = rad2deg(s.Course);
                end

                if isfield(s,'ExitCourse')
                    % R2023a uses 'ExitCourse' as an internal property.
                    obj.Course = course;
                    obj.ExitCourse = s.ExitCourse;
                else
                    % in R2022b and earlier releases 'course' was used
                    % for both the internal and visible property.  For
                    % trajectories with reversal, this reported course
                    % reported back with respect to exiting the waypoint
                    % (not entering).  We copy over the course to the 
                    % ExitCourse field, and then fix the course so that
                    % it is consistent with entering the waypoint.
                    setCourseProperties(obj, course);
                end
            
                % Load private properties.
                obj.HorizontalCumulativeDistance = s.HorizontalCumulativeDistance;
                obj.HorizontalDistancePiecewisePolynomial = s.HorizontalDistancePiecewisePolynomial;
                obj.HorizontalSpeedPiecewisePolynomial = s.HorizontalSpeedPiecewisePolynomial;
                obj.HorizontalAccelerationPiecewisePolynomial = s.HorizontalAccelerationPiecewisePolynomial;
                obj.HorizontalJerkPiecewisePolynomial = s.HorizontalJerkPiecewisePolynomial;
                obj.HorizontalCurvatureInitial = s.HorizontalCurvatureInitial;
                obj.HorizontalCurvatureFinal = s.HorizontalCurvatureFinal;
                obj.HorizontalInitialPosition = s.HorizontalInitialPosition;
                obj.HorizontalPiecewiseLength = s.HorizontalPiecewiseLength;
                obj.VerticalDistancePiecewisePolynomial = s.VerticalDistancePiecewisePolynomial;
                obj.VerticalSpeedPiecewisePolynomial = s.VerticalSpeedPiecewisePolynomial;
                obj.VerticalAccelerationPiecewisePolynomial = s.VerticalAccelerationPiecewisePolynomial;
                obj.VerticalJerkPiecewisePolynomial = s.VerticalJerkPiecewisePolynomial;
                
                obj.PathDuration = s.PathDuration;

                obj.SegmentTimes = s.SegmentTimes;
                obj.RadianSlewAngles = s.RadianSlewAngles;
                obj.AxesOfRotation = s.AxesOfRotation;
                obj.RadianAngularVelocities = s.RadianAngularVelocities;

                obj.CurrentTime = s.CurrentTime;
                obj.IsDoneStatus = s.IsDoneStatus;

                loadprop(obj,s,'CurrentPosition');
                loadprop(obj,s,'CurrentVelocity');
                loadprop(obj,s,'CurrentAcceleration');
                loadprop(obj,s,'CurrentOrientation');
                loadprop(obj,s,'CurrentAngularVelocity');
                loadprop(obj,s,'CurrentPoseValid');
            else
                % R2019b relies upon setupImpl to setup interpolants
                % R2020a performs setup in the constructor
                setupInterpolants(obj);
            end
        end
    end

    % methods for platform trajectories
    methods (Hidden)
        function restart(obj)
            if isLocked(obj)
                % just reset if already setup
                reset(obj);
            else
                % call setup (and lock)
                obj.SamplesPerFrame = 1;
                setup(obj);
            end
        end
        
        function initTrajectory(obj)
            release(obj);
            obj.SamplesPerFrame = 1;
            setup(obj);
        end
        
        function initUpdateRate(obj, newUpdateRate)
            if obj.SampleRate ~= newUpdateRate
                obj.SampleRate = newUpdateRate;
            end
            if obj.SamplesPerFrame ~= 1
                release(obj);
                obj.SamplesPerFrame = 1;
            end
        end
        
        function status = move(obj, ~)
            status = ~obj.IsDoneStatus;
            step(obj);
        end
        
        function time = trajectoryLifetime(obj)
            time = obj.TimeOfArrival(end);
        end
        
        function time = startTime(obj)
            time = obj.TimeOfArrival(1);
        end
        
        function time = stopTime(obj)
            time = obj.TimeOfArrival(end);
        end
    end
    
    % debug methods
    methods (Hidden)
        function wpTable = waypointInfo(obj)
            %WAYPOINTINFO Get waypoint information table
            %
            %   WPTABLE = WAYPOINTINFO(TRAJ) returns a table of waypoints,
            %   times of arrival, velocities, and orientation for the 
            %   System object, TRAJ.
            
            valsCell = {obj.TimeOfArrival, obj.Waypoints};
            varsCell = {'TimeOfArrival', 'Waypoints'};
            
            if obj.IsVelocitiesSpecified
                valsCell{end+1} = obj.Velocities;
                varsCell{end+1} = 'Velocities';
            end
            
            if obj.IsOrientationSpecified
                orient = obj.Orientation;
                if ~obj.IsOrientationQuaternion
                    for i = size(orient, 3):-1:1
                        orientCell{i,:} = orient(:,:,i);
                    end
                else
                    for i = size(orient, 1):-1:1
                        orientCell{i,:} = orient(i,:);
                    end
                end
                valsCell{end+1} = orientCell;
                varsCell{end+1} = 'Orientation';
            end
            wpTable = table(valsCell{:}, 'VariableNames', varsCell);
        end
    end
    
    methods(Access = protected)
        function perts = defaultPerturbations(obj)
            wpp = struct(...
                'Property', "Waypoints", ...
                'Type', "None", ...
                'Value', {{NaN, NaN}}...
                );
            if obj.IsTimeOfArrivalSpecified
                toap = struct(...
                    'Property', "TimeOfArrival", ...
                    'Type', "None", ...
                    'Value', {{NaN, NaN}}...
                    );
            else
                toap = struct(...
                    'Property', "InitialTime", ...
                    'Type', "None", ...
                    'Value', {{NaN, NaN}}...
                    );
            end
            perts = [wpp;toap];
        end
    end
    
    methods(Static, Hidden)
        function flag = isAllowedInSystemBlock
            flag = false;
        end
    end
    
    methods (Access = private)
        function loadprop(obj,s,propname)
            % set property if it exists in both object and specifier
            if isfield(s,propname) && isprop(obj,propname)
                obj.(propname) = s.(propname);
            end
        end
    end
end

