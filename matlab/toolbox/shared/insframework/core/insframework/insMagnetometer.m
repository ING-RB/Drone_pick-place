classdef insMagnetometer < positioning.internal.insMagnetometer
%INSMAGNETOMETER Model magnetometer reading for sensor fusion 
%   S = INSMAGNETOMETER creates an object which models an magnetometer
%   reading and allows an INS Filter to fuse data from the magnetometer.
%   Passing S to the insEKF function to enable magnetometer data fusion.
%   When fusing data with the INS Filter fuse() function, pass S as the
%   second argument to identify data as coming from a magnetometer.
%
%   The INSMAGNETOMETER models the magnetometer reading as the summation of
%   two parts: geomagnetic vector rotated to the body frame and a constant
%   bias. The measurement function is
%       h(x) = rotateframe(Orientation, GeomagneticVector) + bias
%   with some normalization omitted. The INS Filter will track the
%   three-element bias term  and three-element geomagnetic vector term in
%   the State vector. Regardless of how many INSMAGNETOMETER models are
%   used in the INS Filter design, only a single geomagnetic vector is
%   tracked in the State vector and is shared across all magnetometers. 
%
%   Example:
%   acc = insAccelerometer;
%   gyro = insGyroscope;
%   mag = insMagnetometer;
%   filtAHRS = insEKF(acc, gyro, mag);
%   filtMagOnly = insEKF(insMagnetometer);
%
%   See also: insEKF, insOptions, insGyroscope

%   Copyright 2021 The MathWorks, Inc.      


%#codegen

    methods 
        function s = sensorstates(~, opts)
            %SENSORSTATES Define the tracked states for a magnetometer 
            %   SENSORSTATES returns a scalar struct which describes the
            %   states used by the insMagnetometer and tracked by the
            %   insEKF filter. The states used by the insMagnetometer are 
            %       3-element constant bias
            %       3-element geomagnetic vector.
            %   The default value of the geomagnetic vector varies based on
            %   whether the insOpts ReferenceFrame property is set to
            %   either a NED frame or ENU frame, whose origin is at the
            %   location of 0 degrees latitude, 0 degrees longitude, 0
            %   meters altitude.
            %
            %  See also: insEKF, insEKF/stateparts

            gvNED = fusion.internal.ConstantValue.MagneticFieldNED;
            if opts.ReferenceFrame == positioning.internal.ReferenceFrameChoices.ENU
                gv = [gvNED(2) gvNED(1) -gvNED(3)];
            else
                gv = gvNED;
            end
            s = struct('Bias', zeros(1,3, opts.Datatype), ...
                'GeomagneticVector', cast(gv, opts.Datatype));
        end
    end


    %%%% Required methods %%%%
    methods 
        %MEASUREMENT Sensor measurement estimate from states
        %   MEASUREMENT returns an 3-by-1 array of predicted measurements
        %   for a magnetometer based on the current state of filter FILT.
        %   The FILT input is an instance of the insEKF filter.
        %
        %   This function is called internally by FILT when its FUSE or
        %   RESIDUAL methods are invoked.
        %
        %   See also: insEKF
        function z = measurement(sensor, filt)
            magVec = stateparts(filt, 'GeomagneticVector');
            biasBody = stateparts(filt, sensor, 'Bias');
            orient = stateparts(filt, 'Orientation');
            biasBodyX = biasBody(1);
            biasBodyY = biasBody(2);
            biasBodyZ = biasBody(3);
            magVecNavX = magVec(1);
            magVecNavY = magVec(2);
            magVecNavZ = magVec(3);
            q0 = orient(1);
            q1 = orient(2);
            q2 = orient(3);
            q3 = orient(4);
          
            z = zeros(1,3, 'like', magVec);
            z(1) = biasBodyX + magVecNavX*(2*q0^2 + 2*q1^2 - 1) + magVecNavY*(2*q0*q3 + 2*q1*q2) - magVecNavZ*(2*q0*q2 - 2*q1*q3);
            z(2) = biasBodyY + magVecNavY*(2*q0^2 + 2*q2^2 - 1) - magVecNavX*(2*q0*q3 - 2*q1*q2) + magVecNavZ*(2*q0*q1 + 2*q2*q3);
            z(3) = biasBodyZ + magVecNavZ*(2*q0^2 + 2*q3^2 - 1) + magVecNavX*(2*q0*q2 + 2*q1*q3) - magVecNavY*(2*q0*q1 - 2*q2*q3);
        end
    end
    
    
    
    methods
        function statesdot = stateTransition(~, filt, ~, ~)
            %STATETRANSITION State transition function for sensor states
            %   STATETRANSITION returns a struct with the same fields and
            %   field sizes as the output of sensorstates. The returned
            %   struct describes the state transition functions for
            %   different parts of the sensor states.
            %
            %   This function is called by the insEKF filter FILT when the
            %   PREDICT method of the FILT function is called. The FILT
            %   input is a handle to the calling insEKF.
            % 
            %   Both the magnetometer bias state and the geomagnetic vector
            %   are modeled as constant over time. The stateTransition
            %   function returns their derivative which is zero.
            %
            %   See also: positioning.INSSensorModel/sensorstates
            
            statesdot = struct('Bias', zeros(1,3, 'like', filt.State), ...
                'GeomagneticVector', zeros(1,3, 'like', filt.State));
        end
        
        function  dhdx = measurementJacobian(sensor, filt)
            %MEASUREMENTJACOBIAN Jacobian of the measurement method
            %  MEASUREMENTJACOBIAN returns an 3-by-NS array which is the
            %  Jacobian of the MEASUREMENT method relative to the State
            %  property of filter FILT. The FILT input is an instance of
            %  the insEKF filter. Here M is the number of elements in a
            %  sensor measurement and NS is the number of elements in the
            %  State property of FILT.
            %
            %   This function is called internally by FILT when its FUSE or
            %   RESIDUAL methods are invoked.
            %
            %   See also: insEKF

            states = filt.State;
            dhdx = zeros(3, numel(states), 'like', states);
            idx = stateinfo(filt);
            bidx = stateinfo(filt, sensor, 'Bias');

            magVecNavX = states(idx.GeomagneticVector(1));
            magVecNavY = states(idx.GeomagneticVector(2));
            magVecNavZ = states(idx.GeomagneticVector(3));
            q0 = states(idx.Orientation(1));
            q1 = states(idx.Orientation(2));
            q2 = states(idx.Orientation(3));
            q3 = states(idx.Orientation(4));
            oidx = idx.Orientation;
            gvidx = stateinfo(filt, sensor, 'GeomagneticVector');
         
            dhdx(1,oidx) = [4*magVecNavX*q0 + 2*magVecNavY*q3 - 2*magVecNavZ*q2, 4*magVecNavX*q1 + 2*magVecNavY*q2 + 2*magVecNavZ*q3, 2*magVecNavY*q1 - 2*magVecNavZ*q0, 2*magVecNavY*q0 + 2*magVecNavZ*q1];
            dhdx(1,bidx) = [1, 0, 0];
            dhdx(1,gvidx) = [2*q0^2 + 2*q1^2 - 1, 2*q0*q3 + 2*q1*q2, 2*q1*q3 - 2*q0*q2];

            dhdx(2,oidx) = [4*magVecNavY*q0 - 2*magVecNavX*q3 + 2*magVecNavZ*q1, 2*magVecNavX*q2 + 2*magVecNavZ*q0, 2*magVecNavX*q1 + 4*magVecNavY*q2 + 2*magVecNavZ*q3, 2*magVecNavZ*q2 - 2*magVecNavX*q0];
            dhdx(2,bidx) = [0, 1, 0];
            dhdx(2,gvidx) = [2*q1*q2 - 2*q0*q3, 2*q0^2 + 2*q2^2 - 1, 2*q0*q1 + 2*q2*q3];


            dhdx(3,oidx) = [2*magVecNavX*q2 - 2*magVecNavY*q1 + 4*magVecNavZ*q0, 2*magVecNavX*q3 - 2*magVecNavY*q0, 2*magVecNavX*q0 + 2*magVecNavY*q3, 2*magVecNavX*q1 + 2*magVecNavY*q2 + 4*magVecNavZ*q3];
            dhdx(3,bidx) = [0, 0, 1];
            dhdx(3,gvidx) = [2*q0*q2 + 2*q1*q3, 2*q2*q3 - 2*q0*q1, 2*q0^2 + 2*q3^2 - 1];

        end
        
        function dfdx = stateTransitionJacobian(~, filt, ~, ~)
            %STATETRANSITIONJACOBIAN Jacobian of sensor stateTransition function
            %  STATETRANSITIONJACOBIAN returns a struct with the same
            %  fields as sensorstates and describes the Jacobians of the
            %  state transition function relative to the states of the sensor
            %  for different state parts.  Each field value of STATESDOT should
            %  be a 3-by-numel(FILT.State) row vector of partial derivatives of
            %  that field's state transition function relative to the state
            %  vector. 
            %  
            %  This function is called by the insEKF filter FILT when the
            %  PREDICT method of the FILT function is called. The FILT
            %  input is a handle to the calling insEKF. The DT and varargin
            %  inputs are the corresponding inputs to the predict method.
            %
            %   Both the bias and geomagnetic vector are constant
            %   over time, and their jacobians are all zero.
            %
            %  See also: insEKF
            
            s = filt.State;
            z = zeros(3, numel(s), 'like', s);
            dfdx = struct('Bias', z, 'GeomagneticVector', z);
        end
    end

end



