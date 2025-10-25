classdef insGPS < positioning.internal.insGPS
%INSGPS Model of a GPS for sensor fusion
%   S = INSGPS creates an object which models a GPS 
%   reading and allows an INS Filter to fuse data from a GPS.
%   Pass S to the insEKF function to enable GPS data fusion. When
%   fusing data with the INS Filter fuse() function, pass S as the second
%   argument to identify data as coming from a GPS.
%
%   INSGPS models the GPS reading as a direct measurement of position, and
%   optionally velocity. The position measurement is in
%   longitude-latitude-altitude (LLA) format. The velocity measurement is
%   in m/s in the reference frame of the filter, either NED or ENU.
%   The INSGPS should be used in a filter configured with a motion model 
%   that tracks position in the NED or ENU reference frame. If velocity
%   measurements are to be fused, then velocity should be tracked in the
%   filter's reference frame as well. The INSMOTIONPOSE motion model fills
%   these requirements and can be used with the INSGPS.
%
%   INSGPS Properties:
%   ReferenceLocation    -  Reference location (deg, deg, meters)
%
%   Example:
%   acc = insAccelerometer;
%   gyro = insGyroscope;
%   mag = insMagnetometer;
%   gps = insGPS;
%   filtpose = insEKF(acc, gyro, mag, gps);
%
%   See also: insEKF, insOptions, insMotionPose

%   Copyright 2021 The MathWorks, Inc.

%#codegen 

    properties
        % Specify the origin of the local reference frame as a 3-element
        %   row vector in geodetic coordinates (latitude, longitude, and
        %   altitude). Altitude is the height above the reference ellipsoid
        %   model, WGS84. The reference location is in
        %   [degrees degrees meters]. The default value is [0 0 0].
        ReferenceLocation = [0 0 0];
    end

    methods 
        function z = measurement(~, filt)
        %MEASUREMENT Sensor measurement estimate from states
        %  MEASUREMENT returns a 3-by-1 array of predicted position
        %  measurements in the reference frame of the filter FILT, if only
        %  position is tracked in the state vector.
        %
        %  MEASUREMENT returns a 6-by-1 array of predicted position and
        %  velocity measurements in the reference frame of the filter FILT,
        %  if both position and velocity are tracked in the state vector.
        %
        %  The FILT input is an instance of the insEKF filter.
        %
        %   This function is called internally by FILT when its FUSE or
        %   RESIDUAL methods are invoked.
        %
        %   See also: insEKF

            idx = stateinfo(filt);
            state = filt.State;
            pos = state(idx.Position);
            if isfield(idx, 'Velocity')
                vel = state(idx.Velocity);
                z = [pos(:); vel(:)].';
            else
                z = reshape(pos, 1,[]);
            end
        end

        function dhdx = measurementJacobian(~, filt)
        %MEASUREMENTJACOBIAN Jacobian of the measurement method
        %  MEASUREMENTJACOBIAN returns a 3-by-NS array if the filter FILT's
        %  motion model tracks position but not velocity.
        %
        %  MEASUREMENTJACOBIAN returns a 6-by-NS array if the filter FILT's
        %  motion model tracks both position and velocity.
        %
        %  The returned matrix is the Jacobian of the MEASUREMENT method
        %  relative to the State property of filter FILT. The FILT input is
        %  an instance of the insEKF filter. Here NS is the number of
        %  elements in the State property of FILT. 
        %
        %   This function is called internally by FILT when its FUSE or
        %   RESIDUAL methods are invoked.
        %
        %   See also: insEKF, insMotionPose
            idx = stateinfo(filt);
            state = filt.State;
            pidx = idx.Position;
            if isfield(idx, 'Velocity')
                vidx = idx.Velocity;
                dhdx = zeros(6, numel(state), 'like', state);
                dhdx(1,pidx) = [1 0 0];
                dhdx(2,pidx) = [0 1 0];
                dhdx(3,pidx) = [0 0 1];

                dhdx(4,vidx) = [1 0 0];
                dhdx(5,vidx) = [0 1 0];
                dhdx(6,vidx) = [0 0 1];
            else
                dhdx = zeros(3, numel(state), 'like', state);
                dhdx(1,pidx) = [1 0 0];
                dhdx(2,pidx) = [0 1 0];
                dhdx(3,pidx) = [0 0 1];
            end
        end
        function statesdot = stateTransition(~, ~, ~, varargin)
            %SENSORSTATES The INSGPS does not require tracking additional states
            statesdot = struct(); % no states
        end
        function dfdx = stateTransitionJacobian(~, ~, ~, varargin)
            %SENSORSTATES The INSGPS does not require tracking additional states
            dfdx = struct(); % no states, so no jacobian
        end
    end

end
