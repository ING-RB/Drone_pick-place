classdef insGyroscope < positioning.internal.insGyroscope
%INSGYROSCOPE Model gyroscope reading for sensor fusion 
%   S = INSGYROSCOPE creates an object which models a gyroscope
%   reading and allows an INS Filter to fuse data from a gyroscope.
%   Pass S to the insEKF function to enable gyroscope data fusion. When
%   fusing data with the INS Filter fuse() function pass S as the second
%   argument to identify data as coming from a gyroscope.
%
%   INSGYROSCOPE models the gyroscope reading as angular velocity in
%   the body frame plus a constant bias. The measurement function is
%       h(x) = AngularVelocityBody + bias
%   The INSGYROSCOPE requires a motion model which tracks angular velocity
%   in the body frame.  The INS Filter will track the three-element bias
%   term in the State vector.
%
%   Example:
%   acc = insAccelerometer;
%   gyro = insGyroscope;
%   mag = insMagnetometer;
%   filtAHRS = insEKF(acc, gyro, mag);
%   filtGyroOnly = insEKF(insGyroscope);
%
%   See also: insEKF, insOptions, insAccelerometer

%   Copyright 2021 The MathWorks, Inc.      


%#codegen


    %%%% Required methods %%%%
    methods 
        %MEASUREMENT Sensor measurement estimate from states
        %  MEASUREMENT returns an M-by-1 array of predicted measurements
        %  for this SENSOR based on the current state of filter FILT. Here
        %  M is the number of elements in a measurement from this sensor.
        %  The FILT input is an instance of the insEKF filter.
        %
        %   This function is called internally by FILT when its FUSE or
        %   RESIDUAL methods are invoked.
        %
        %   See also: insEKF
        function z = measurement(sensor, filt)
            angvelBody = stateparts(filt, 'AngularVelocity');
            biasBody = stateparts(filt, sensor, 'Bias');

            % vectorized version of what comes out of our 
            % insEKF.gyroscope.generate
            z = angvelBody + biasBody; 
        end
    end
    
    %%%% Optional Methods %%%%
    methods 
        function s = sensorstates(~, opts) 
            %SENSORSTATES Define the tracked states for this sensor
            %  SENSORSTATES returns a scalar struct which describes the
            %  states used by this sensor model and tracked by the insEKF
            %  filter. The field names describe the individual state
            %  quantities and allow access to the estimates of those
            %  quantities through the statesparts function. The values of
            %  the struct determine the size and default values of the
            %  state vector. The input OPTS is the insOptions used to build
            %  the filter. 
            %
            %  Implementing this method is only required if sensor-specific
            %  states, such as biases, need to be estimated during
            %  filtering.
            %
            %  See also: insEKF, insEKF/stateparts
            
            s = struct('Bias', zeros(1,3, opts.Datatype)); 
        end
    end
    
    methods
        function statesdot = stateTransition(~, filt, dt, varargin)
            %STATETRANSITION State transition function for sensor states
            %  STATETRANSITION returns a struct with identical fields, and
            %  field sizes, as the output of sensorstates. The returned
            %  struct should describe the per-state transition function for
            %  the sensor states.
            %
            %  This function is called by the insEKF filter FILT when the
            %  PREDICT method of the FILT function is called. The FILT
            %  input is a handle to the calling insEKF. The DT and varargin
            %  inputs are the corresponding inputs to the predict method.
            %
            %  Implementing this method is optional. If this method is not
            %  implemented, it is assumed that all states defined in
            %  sensorstates should be modeled as a constant over time.
            %
            %   See also: positioning.INSSensorModel/sensorstates
            
            statesdot = struct('Bias', zeros(1,3, 'like', filt.State));
        end
        
        function  dhdx = measurementJacobian(sensor, filt)
            %MEASUREMENTJACOBIAN Jacobian of the measurement method
            %  MEASUREMENTJACOBIAN returns an M-by-NS array which is the
            %  Jacobian of the MEASUREMENT method relative to the State
            %  property of filter FILT. The FILT input is an instance of
            %  the insEKF filter. Here M is the number of elements in a
            %  sensor measurement and NS is the number of elements in the
            %  State property of FILT.
            %
            %   This function is called internally by FILT when its FUSE or
            %   RESIDUAL methods are invoked.
            %
            %   Implementing this method is optional. If this method is not
            %   implemented, a numerical Jacobian will be used instead.
            %
            %   See also: insEKF

            states = filt.State;
            dhdx = zeros(3, numel(states), 'like', states);
            avidx = stateinfo(filt, 'AngularVelocity');
            bidx = stateinfo(filt, sensor, 'Bias');
            
            dhdx(1,avidx) = [1, 0, 0];
            dhdx(1,bidx) = [1, 0, 0];

            dhdx(2,avidx) = [0, 1, 0];
            dhdx(2,bidx) = [0, 1, 0];

            dhdx(3,avidx) = [0, 0, 1];
            dhdx(3,bidx) = [0, 0, 1];
        end
        
        function dfdx = stateTransitionJacobian(~, filt, dt, varargin)
            %STATETRANSITIONJACOBIAN Jacobian of sensor stateTransition function
            %  STATETRANSITIONJACOBIAN returns a struct with identical
            %  fields as sensorStates and describes the Jacobian of the
            %  per-state transition function relative to the State property
            %  of filter FILT. Each field value of STATESDOT should be a
            %  M-by-numel(FILT.State) row vector of partial derivatives of
            %  that field's state transition function relative to the state
            %  vector. Here M is the number of elements in a measurement
            %  from this sensor.
            %
            %  This function is called by the insEKF filter FILT when the
            %  PREDICT method of the FILT function is called. The FILT
            %  input is a handle to the calling insEKF. The DT and varargin
            %  inputs are the corresponding inputs to the predict method.
            %
            %  Implementing this method is optional. If this method is not
            %  implemented, a numerical Jacobian will be used instead.
            %
            %  See also: insEKF
            
            s = filt.State;
            z = zeros(3, numel(s), 'like', s);
            dfdx = struct('Bias', z);
        end
    end

end



