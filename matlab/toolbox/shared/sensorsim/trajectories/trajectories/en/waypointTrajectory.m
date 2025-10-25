classdef waypointTrajectory< matlab.System & matlab.system.mixin.FiniteSource & fusion.scenario.internal.mixin.PlatformTrajectory & scenario.internal.mixin.Perturbable
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
%   <a href="matlab:help matlab.System/reset   ">reset</a>              - Reset the states of the WAYPOINTTRAJECTORY
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

    methods
        function out=waypointTrajectory
        end

        function out=beginTrajectory(~) %#ok<STOUT>
        end

        function out=defaultPerturbations(~) %#ok<STOUT>
        end

        function out=fetchOrientationFromPath(~) %#ok<STOUT>
            %  segIdx     - index into corresponding clothoid segment
            %  hut, dhut, - horizontal unit tangent in complex plane.  its derivative.
            %  vs, hs,    - vertical speed (climbrate) and horizontal speed in complex plane.  
            %  va, ha,    - vertical and horizontal sign-magnitude acceleration
            %  vj, hj,    - vertical and horizontal sign-magnitude jerk
        end

        function out=fetchOrientationFromQuaternions(~) %#ok<STOUT>
        end

        function out=fetchPosition(~) %#ok<STOUT>
        end

        function out=getHorizontalDistancePolynomialViaConstantAcceleration(~) %#ok<STOUT>
            % constant acceleration paths
        end

        function out=getHorizontalDistancePolynomialViaTimeOfArrival(~) %#ok<STOUT>
        end

        function out=getHorizontalDistancePolynomialViaTrapezodalAcceleration(~) %#ok<STOUT>
            % Get the piecewise polynomial to evaluate d(t).
        end

        function out=isDoneImpl(~) %#ok<STOUT>
        end

        function out=isInactivePropertyImpl(~) %#ok<STOUT>
        end

        function out=loadObjectImpl(~) %#ok<STOUT>
            % Load public properties.
        end

        function out=lookupPose(~) %#ok<STOUT>
            %LOOKUPPOSE - return pose information for a given set of times
            %   [POS, ORIENT, VEL, ACC, ANGVEL] = lookupPose(TRAJ, SAMPTIMES)
            %   returns the pose information for the specified sampleTimes.  
            %   Specify SAMPTIMES as a real-valued vector.  If any individual 
            %   sample time is beyond the valid timerange of the trajectory, 
            %   then the corresponding pose information is returned as NaN.
        end

        function out=lookupPoses(~) %#ok<STOUT>
            % pre-initialize to NaN
        end

        function out=perturb(~) %#ok<STOUT>
            %PERTURB Apply perturbations to the object
            % OFFSETS = PERTURB(OBJ) apply the perturbations defined for
            % the object. Object properties will be perturbed by an offset
            % as defined in the perturbations. See the perturbations
            % method. OFFSETS is a struct with fields Property and Offset,
            % which provide the offset value in this call to perturb.
        end

        function out=resetImpl(~) %#ok<STOUT>
        end

        function out=saveObjectImpl(~) %#ok<STOUT>
            % Save public properties.
        end

        function out=setAutoBank(~) %#ok<STOUT>
        end

        function out=setAutoPitch(~) %#ok<STOUT>
        end

        function out=setClimbRate(~) %#ok<STOUT>
        end

        function out=setCourse(~) %#ok<STOUT>
        end

        function out=setCourseProperties(~) %#ok<STOUT>
            % ExitCourse describes course as exiting from the corresponding
            % waypoint (but entering the last waypoint).
        end

        function out=setGroundSpeed(~) %#ok<STOUT>
        end

        function out=setInitialTime(~) %#ok<STOUT>
        end

        function out=setJerkLimit(~) %#ok<STOUT>
        end

        function out=setOrientation(~) %#ok<STOUT>
        end

        function out=setPose(~) %#ok<STOUT>
            % interpolate motion from piecewise model
        end

        function out=setProperties(~) %#ok<STOUT>
        end

        function out=setReferenceFrame(~) %#ok<STOUT>
            % System object provides own parameter validation
        end

        function out=setTimeOfArrival(~) %#ok<STOUT>
        end

        function out=setVelocities(~) %#ok<STOUT>
        end

        function out=setWaitTime(~) %#ok<STOUT>
        end

        function out=setWaypoints(~) %#ok<STOUT>
        end

        function out=setupCourseAlignment(~) %#ok<STOUT>
            % by default align with course
        end

        function out=setupHorizontalInterpolant(~) %#ok<STOUT>
        end

        function out=setupHorizontalPath(~) %#ok<STOUT>
            % Find the course angles at the start of each segment.
            % mark missing course information with NaN
        end

        function out=setupHorizontalSpeedProfile(~) %#ok<STOUT>
        end

        function out=setupImpl(~) %#ok<STOUT>
        end

        function out=setupInterpolants(~) %#ok<STOUT>
        end

        function out=setupOrientationInterpolant(~) %#ok<STOUT>
        end

        function out=setupPositionInterpolant(~) %#ok<STOUT>
        end

        function out=setupVerticalInterpolant(~) %#ok<STOUT>
            % Get the piecewise polynomial for elevation.
        end

        function out=setupWaypointParams(~) %#ok<STOUT>
        end

        function out=stepImpl(~) %#ok<STOUT>
        end

        function out=validateJerkLimit(~) %#ok<STOUT>
        end

        function out=validateWaitTime(~) %#ok<STOUT>
        end

        function out=validateWaypointSizes(~) %#ok<STOUT>
        end

    end
    properties
        % AutoBank Align orientation (roll) to counteract centripetal force
        % Set AutoBank to true to automatically align the roll of the
        % trajectory to counteract centripetal acceleration.  If set to 
        % false, then roll is set to zero (flat orientation).  
        %
        % This property may only be set in the constructor when
        % 'Orientation' is unspecified.
        AutoBank;

        % AutoPitch Align orientation (pitch) with direction of travel.
        % Set AutoPitch to true to automatically align the pitch of the
        % trajectory to the direction of travel.  If set to false, then
        % pitch is set to zero (level orientation).  
        %
        % This property may only be set in the constructor when
        % 'Orientation' is unspecified.
        AutoPitch;

        % ClimbRate Climbrate at each waypoint (m/s)
        % Specify the climbrate at the corresponding waypoints as an
        % N-element matrix. If it is not specified, then it is inferred from
        % each waypoint.
        %
        % This property may only be set in the constructor when
        % 'Velocities' is unspecified.
        ClimbRate;

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

        % InitialTime Duration before trajectory starts (s)
        % InitialTime is the amount of time before the trajectory begins.
        % Positions, orientations, and their respective derivatives
        % encountered before this time are reported as NaN (not-a-number).
        %
        % This property cannot be used while specifying the time-of-arrival
        % instants at each waypoint.
        InitialTime;

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
        JerkLimit;

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

        % ReferenceFrame Axes convention ('NED' or 'ENU')
        % Specify the axes convention used as either 'NED' (north-east-down)
        % or 'ENU' (east-north-up).  
        % The default value is 'NED'.
        ReferenceFrame;

        % SampleRate Sampling rate (Hz)
        % Specify the sampling frequency of the trajectory as a positive
        % scalar. The default value is 100. This property is tunable.
        SampleRate;

        % SamplesPerFrame Number of samples per output frame
        % Specify the number of samples to buffer into each output frame.
        % The default value is 1.
        SamplesPerFrame;

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

        % Waypoints Positions in the navigation frame (m)
        % Specify the position at each waypoint as an N-by-3 matrix in
        % meters. The default value is [0 0 0; 0 0 0].
        %
        % This property may only be set in the constructor.
        Waypoints;

    end
end
