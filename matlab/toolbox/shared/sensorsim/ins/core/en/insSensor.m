classdef insSensor< fusion.internal.INSSENSORBaseMATLAB & fusion.internal.UnitDisplayer & scenario.internal.mixin.Perturbable
%INSSENSOR INS/GPS position, velocity, and orientation emulator
%   INS = INSSENSOR returns a System object, INS, that models an inertial 
%   navigation and global navigation satellite system (INS/GNSS).
%
%   INS = INSSENSOR('Name', Value, ...) returns an INSSENSOR System object 
%   with each specified property name set to the specified value. You can 
%   specify additional name-value pair arguments in any order as 
%   (Name1,Value1,...,NameN, ValueN).
%   
%   Step method syntax:
%
%   INSMEAS = step(INS, GROUNDTRUTH) models an inertial navigation and
%   global navigation satellite system (INS/GNSS) reading, INSMEAS, from an
%   inertial input GROUNDTRUTH.
%   
%   INSMEAS = step(INS, GROUNDTRUTH, SIMTIME) returns an INS/GNSS reading 
%   at simulation time SIMTIME.
%
%   GROUNDTRUTH and INSMEAS are structs with the following fields:
% 
%        Position           Position of the INS, specified as an N-by-3 
%                           array of [x, y, z] vectors in local Cartesian 
%                           coordinates. Units are in meters. N is the 
%                           number of samples in the current frame.
% 
%        Velocity           Velocity of the INS, specified as an N-by-3 
%                           array of [x, y, z] vectors in local Cartesian 
%                           coordinates. Units are in meters per second. N 
%                           is the number of samples in the current frame.
%
%       Orientation         Orientation of the INS with respect to the 
%                           local coordinate system. It can be specified in
%                           any of these formats:
%                           - N-element column vector of quaternion objects
%                           - 3-by-3-by-N array of rotation matrices
%                           - N-by-3 array of [roll, pitch, yaw] angles in
%                             degrees
%                           N is the number of samples in the current 
%                           frame.
%
%        Acceleration       Acceleration of the INS, specified as an N-by-3
%                           array of [x, y, z] vectors in local Cartesian 
%                           coordinates. Units are in meters per second 
%                           squared. N is the number of samples in the 
%                           current frame.
%
%        AngularVelocity    Angular velocity of the INS, specified as an 
%                           N-by-3 array of [x, y, z] vectors in local 
%                           Cartesian coordinates. Units are in degrees per
%                           second. N is the number of samples in the 
%                           current frame.
%
%   GROUNDTRUTH fields must be double or single. The output INSMEAS has the
%   same field types as the input GROUNDTRUTH. The Position, Velocity, and 
%   Orientation fields are required, the other fields are optional.
%
%   SIMTIME is the current simulation time in seconds.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%
%   INSSENSOR methods:
%
%   step           - See above description for use of this method
%   perturbations  - Define perturbations to the INSSENSOR
%   perturb        - Apply perturbations to the INSSENSOR
%   release        - Allow property value and input characteristics to 
%                    change, and release INSSENSOR resources
%   clone          - Create INSSENSOR object with same property values
%   isLocked       - Display locked status (logical)
%   <a href="matlab:help matlab.System/reset   ">reset</a>          - Reset the states of the INSSENSOR
%
%   INSSENSOR properties:
%
%   MountingLocation        - [x, y, z] location of sensor on vehicle (m)
%   RollAccuracy            - Roll accuracy (deg)
%   PitchAccuracy           - Pitch accuracy (deg)
%   YawAccuracy             - Yaw accuracy (deg)
%   PositionAccuracy        - Position accuracy (m)
%   VelocityAccuracy        - Velocity accuracy (m/s)
%   AccelerationAccuracy    - Acceleration accuracy (m/s^2)
%   AngularVelocityAccuracy - Angular velocity accuracy (deg/s)
%   TimeInput               - Time input
%   HasGNSSFix              - Indicator of GNSS fix
%   PositionErrorFactor     - Drift rate of position with no GNSS fix
%   RandomStream            - Source of random number stream 
%   Seed                    - Initial seed of mt19937ar random number 
%   
%   % Example 1: Generate INS measurements from stationary input.
%   -------------------------------------------------------------
%
%   Fs = 100;
%   numSamples = 1000;
%   t = 0:1/Fs:(numSamples-1)/Fs;
%
%   ins = insSensor;
%
%   motion = struct( ...
%       'Position', [0 0 0], ...
%       'Velocity', [0 0 0], ...
%       'Orientation', quaternion(1, 0, 0, 0));
%
%   loggedData = struct( ...
%       'Position', zeros(numSamples, 3), ...
%       'Velocity', zeros(numSamples, 3), ...
%       'Orientation', quaternion.zeros(numSamples, 1));
%
%   for i = 1:numSamples
%       insMeas = ins(motion);
%       loggedData.Position(i, :) = insMeas.Position;
%       loggedData.Velocity(i, :) = insMeas.Velocity;
%       loggedData.Orientation(i, :) = insMeas.Orientation;
%   end
%
%   subplot(3, 1, 1)
%   plot(t, loggedData.Position)
%   title('Position')
%   xlabel('s')
%   ylabel('m')
%   legend('N', 'E', 'D')
%
%   subplot(3, 1, 2)
%   plot(t, loggedData.Velocity)
%   title('Velocity')
%   xlabel('s')
%   ylabel('m/s')
%   legend('N', 'E', 'D')
%
%   subplot(3, 1, 3)
%   eulerAngs = eulerd(loggedData.Orientation, 'ZYX', 'frame');
%   plot(t, eulerAngs)
%   title('Orientation')
%   xlabel('s')
%   ylabel('degrees')
%   legend('Roll', 'Pitch', 'Yaw')
%
%   % Example 2: Generate INS measurements with acceleration and angular 
%   % velocity inputs.
%   --------------------------------------------------------------------
%
%   Fs = 100;
%   numSamples = 1000;
%   t = 0:1/Fs:(numSamples-1)/Fs;
%
%   ins = insSensor;
%
%   motion = struct( ...
%       'Position', [0 0 0], ...
%       'Velocity', [0 0 0], ...
%       'Orientation', quaternion(1, 0, 0, 0), ...
%       'Acceleration', [0 0 0], ...
%       'AngularVelocity', [0 0 0]);
%
%   loggedData = struct( ...
%       'Position', zeros(numSamples, 3), ...
%       'Velocity', zeros(numSamples, 3), ...
%       'Orientation', quaternion.zeros(numSamples, 1), ...
%       'Acceleration', zeros(numSamples, 3), ...
%       'AngularVelocity', zeros(numSamples, 3));
%
%   for i = 1:numSamples
%       insMeas = ins(motion);
%       loggedData.Position(i, :) = insMeas.Position;
%       loggedData.Velocity(i, :) = insMeas.Velocity;
%       loggedData.Orientation(i, :) = insMeas.Orientation;
%       loggedData.Acceleration(i, :) = insMeas.Acceleration;
%       loggedData.AngularVelocity(i, :) = insMeas.AngularVelocity;
%   end
%
%   subplot(2, 1, 1)
%   plot(t, loggedData.Acceleration)
%   title('Acceleration')
%   xlabel('s')
%   ylabel('m/s^2')
%   legend('N', 'E', 'D')
%
%   subplot(2, 1, 2)
%   plot(t, loggedData.AngularVelocity)
%   title('Angular Velocity')
%   xlabel('s')
%   ylabel('deg/s')
%   legend('N', 'E', 'D')

 
%   Copyright 2017-2022 The MathWorks, Inc.

    methods
        function out=insSensor
        end

        function out=defaultPerturbations(~) %#ok<STOUT>
        end

        function out=displayScalarObject(~) %#ok<STOUT>
        end

        function out=getPropertyGroups(~) %#ok<STOUT>
        end

        function out=isInputSizeMutableImpl(~) %#ok<STOUT>
        end

        function out=loadObjectImpl(~) %#ok<STOUT>
            % Set properties in object obj to values in structure s
        end

        function out=saveObjectImpl(~) %#ok<STOUT>
            % Set properties in structure s to values in object obj
        end

    end
end
