classdef kinematicTrajectory< matlab.System & fusion.scenario.internal.mixin.PlatformTrajectory & scenario.internal.mixin.Perturbable
%KINEMATICTRAJECTORY Rate-driven trajectory generator
%   TRAJ = KINEMATICTRAJECTORY returns a System object, TRAJ, that 
%   generates a trajectory based on acceleration and angular velocity.
%
%   TRAJ = KINEMATICTRAJECTORY('Name', Value, ...) returns a 
%   KINEMATICTRAJECTORY System object with each specified property name set
%   to the specified value. You can specify additional name-value pair 
%   arguments in any order as (Name1,Value1,...,NameN, ValueN).
%   
%   Step method syntax:
%
%   [POS, ORIENT, VEL, ACC, ANGVEL] = step(TRAJ, ACCBODY, ANGVELBODY) 
%   outputs the trajectory state based on acceleration (ACCBODY) and 
%   angular velocity (ANGVELBODY).
%
%   The inputs to KINEMATICTRAJECTORY are defined as follows:
%
%       ACCBODY       Driving acceleration in the body coordinate system 
%                     specified as a real finite N-by-3 array in meters per
%                     second squared. N is the number of samples in the 
%                     current frame. 
%
%       ANGVELBODY    Driving angular velocity in the body coordinate 
%                     system specified as a real finite N-by-3 array in 
%                     radians per second. N is the number of samples in the
%                     current frame. 
%
%   The outputs of KINEMATICTRAJECTORY are defined as follows:
%
%       POS           Position in the local navigation coordinate system 
%                     specified as a real finite N-by-3 array in meters. N
%                     is the number of samples in the current frame.
%
%       ORIENT        Orientation with respect to the local navigation 
%                     coordinate system specified as a quaternion N-element
%                     column vector or a 3-by-3-by-N rotation matrix. Each
%                     quaternion or rotation matrix is a frame rotation
%                     from the local navigation coordinate system to the
%                     current body coordinate system. N is the number of
%                     samples in the current frame.
%
%       VEL           Velocity in the local navigation coordinate system 
%                     specified as a real finite N-by-3 array in meters per
%                     second. N is the number of samples in the current
%                     frame.
%
%       ACC           Acceleration in the local navigation coordinate 
%                     system specified as a real finite N-by-3 array in
%                     meters per second squared. N is the number of samples
%                     in the current frame.
%
%       ANGVEL        Angular velocity in the local navigation coordinate 
%                     system specified as a real finite N-by-3 array in
%                     radians per second. N is the number of samples in the
%                     current frame.
%
%   Either single or double datatypes are supported for the inputs to 
%   KINEMATICTRAJECTORY. Outputs have the same datatype as the input.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   KINEMATICTRAJECTORY methods:
%
%   step           - See above description for use of this method
%   perturbations  - Define perturbations to the trajectory
%   perturb        - Apply perturbations to the trajectory
%   clone          - Create KINEMATICTRAJECTORY object with same property 
%                    values
%
%   KINEMATICTRAJECTORY properties:
%
%   SampleRate               - Sample rate of trajectory (Hz)
%   Position                 - Position state (m)
%   Orientation              - Orientation state
%   Velocity                 - Velocity state (m/s)
%   Acceleration             - Acceleration state (m/s^2)
%   AngularVelocity          - Angular velocity state (rad/s)
%   SamplesPerFrame          - Number of samples per output frame
%   AccelerationSource       - Source of acceleration state
%   AngularVelocitySource    - Source of angular velocity state
%
%   % EXAMPLE 1: Generate a circular trajectory with inputs.
%
%   N = 10000;
%   Fs = 100;
%   r = 10;
%   speed = 2.5;
%   initialYaw = 90;
% 
%   initPos = [r, 0, 0];
%   initVel = [0, speed, 0];
%   initAtt = quaternion([initialYaw, 0, 0], 'eulerd', 'ZYX', 'frame');
% 
%   traj = kinematicTrajectory('SampleRate', Fs, ...
%       'Position', initPos, ...
%       'Velocity', initVel, ...
%       'Orientation', initAtt);
% 
%   accBody = [0 speed^2/r 0];
%   angvelBody = [0 0 speed/r];
% 
%   pos = zeros(N, 3);
%   q = quaternion.zeros(N, 1);
% 
%   for i = 1:N
%       [pos(i,:), q(i)] = traj(accBody, angvelBody);
%   end
% 
%   plot3(pos(:,1), pos(:,2), pos(:,3))
%   title('Position')
%   xlabel('X (m)')
%   ylabel('Y (m)')
%   zlabel('Z (m)')
%
%   % EXAMPLE 2: Generate a spiraling circular trajectory with no inputs.
%
%   N = 10000;
%   Fs = 100;
%   r = 10;
%   speed = 2.5;
%   initialYaw = 90;
% 
%   initPos = [r 0 0];
%   initVel = [0 speed 0];
%   initOrient = quaternion([initialYaw 0 0], 'eulerd', 'ZYX', 'frame');
%
%   accBody = [0 speed^2/r 0.01];
%   angVelBody = [0 0 speed/r];
% 
%   traj = kinematicTrajectory('SampleRate', Fs, ...
%       'Position', initPos, ...
%       'Velocity', initVel, ...
%       'Orientation', initOrient, ...
%       'AccelerationSource', 'Property', ...
%       'Acceleration', accBody, ...
%       'AngularVelocitySource', 'Property', ...
%       'AngularVelocity', angVelBody);
% 
%   pos = zeros(N, 3);
%   for i = 1:N
%       pos(i,:) = traj();
%   end
% 
%   plot3(pos(:,1), pos(:,2), pos(:,3))
%   title('Position')
%   xlabel('X (m)')
%   ylabel('Y (m)')
%   zlabel('Z (m)')
%
%   See also WAYPOINTTRAJECTORY

 
%   Copyright 2018-2023 The MathWorks, Inc.

    methods
        function out=kinematicTrajectory
        end

        function out=defaultPerturbations(~) %#ok<STOUT>
        end

        function out=getNumInputsImpl(~) %#ok<STOUT>
        end

        function out=isInactivePropertyImpl(~) %#ok<STOUT>
        end

        function out=isInputComplexityMutableImpl(~) %#ok<STOUT>
        end

        function out=loadObjectImpl(~) %#ok<STOUT>
            % Load public properties.
        end

        function out=saveObjectImpl(~) %#ok<STOUT>
            % Save public properties.
        end

        function out=setupImpl(~) %#ok<STOUT>
        end

        function out=stepImpl(~) %#ok<STOUT>
        end

        function out=validateInputsImpl(~) %#ok<STOUT>
        end

    end
    properties
        % Acceleration Acceleration state (m/s^2)
        % Specify the acceleration in the body frame as a real 3-element
        % row vector. This property is tunable. The default initial value
        % is [0 0 0].
        Acceleration;

        % AccelerationSource Source of acceleration state
        % Specify the source of the acceleration as one of 'Input' |
        % 'Property'. The default value is 'Input'.
        AccelerationSource;

        % AngularVelocity Angular velocity state (rad/s)
        % Specify the angular velocity in the body frame as a real
        % 3-element row vector. This property is tunable. The default
        % initial value is [0 0 0].
        AngularVelocity;

        % AngularVelocitySource Source of angular velocity state
        % Specify the source of the angular velocity as one of 'Input' |
        % 'Property'. The default value is 'Input'.
        AngularVelocitySource;

        % Orientation Orientation state 
        % Specify the orientation as a scalar quaternion or a double or 
        % single 3-by-3 rotation matrix. The orientation is a frame 
        % rotation from the local navigation coordinate system to the 
        % current body frame. This property is tunable. The default initial
        % value is quaternion(1,0,0,0).
        Orientation;

        % Position Position state (m)
        % Specify the position in the local frame as a real 3-element row 
        % vector. This property is tunable. The default initial value is 
        % [0 0 0].
        Position;

        % SampleRate Sampling rate (Hz)
        % Specify the sampling frequency of the trajectory as a positive 
        % scalar. This property is tunable. The default value is 100.
        SampleRate;

        % SamplesPerFrame Number of samples per output frame
        % Specify the number of samples to buffer into each trajectory
        % output frame. The default value is 1.
        SamplesPerFrame;

        % Velocity Velocity state (m/s)
        % Specify the velocity in the navigation frame as a real 3-element 
        % row vector. This property is tunable. The default initial value
        % is [0 0 0].
        Velocity;

    end
end
