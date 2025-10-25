classdef insAccelerometer < positioning.internal.insAccelerometer
%INSACCELEROMETER Model accelerometer reading for sensor fusion 
%   S = INSACCELEROMETER creates an object which models an accelerometer
%   reading and allows an INS Filter to fuse data from the accelerometer.
%   Passing S to the insEKF function to enable accelerometer data fusion.
%   When fusing data with the INS Filter fuse() function, pass S as the
%   second argument to identify data as coming from a accelerometer.
%
%   The INSACCELEROMETER uses two possible measurement models depending on
%   whether or not the acceleration is being tracked in the State vector.
%   If the acceleration is being tracked by the filter, the
%   INSACCELEROMETER models the accelerometer reading as  linear
%   acceleration and gravity, summed and rotated to the body frame, plus a
%   constant bias.  The measurement function is
%       h(x) = rotateframe(Orientation, Acceleration + gravity) + bias
%
%   If the acceleration is not being tracked by the filter, the
%   INSACCELEROMETER models the accelerometer reading as the summation of
%   two parts: gravity rotated to the body frame and a constant bias.  The
%   measurement function is
%       h(x) = rotateframe(Orientation, gravity) + bias
%   with some normalization omitted. The INS Filter will track the
%   three-element bias term in the State vector but will not track gravity.
%
%   Example:
%   acc = insAccelerometer;
%   gyro = insGyroscope;
%   mag = insMagnetometer;
%   filtAHRS = insEKF(acc, gyro, mag);
%   filtAccOnly = insEKF(insAccelerometer);
%
%   See also: insEKF, insOptions, insGyroscope

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
            grav = getGravity(sensor, filt);
            orient = stateparts(filt, 'Orientation');
            bias = stateparts(filt, sensor, 'Bias');

            biasBodyX = bias(1);
            biasBodyY = bias(2);
            biasBodyZ = bias(3);
            gravityNavX = grav(1);
            gravityNavY = grav(2);
            gravityNavZ = grav(3);
            q0 = orient(1);
            q1 = orient(2);
            q2 = orient(3);
            q3 = orient(4);

            z = zeros(1,3, 'like', filt.State);
            
            if isConstVel(sensor,filt) 
                z(1) = biasBodyX + gravityNavX*(2*q0^2 + 2*q1^2 - 1) + gravityNavY*(2*q0*q3 + 2*q1*q2) - gravityNavZ*(2*q0*q2 - 2*q1*q3);
                z(2) = biasBodyY + gravityNavY*(2*q0^2 + 2*q2^2 - 1) - gravityNavX*(2*q0*q3 - 2*q1*q2) + gravityNavZ*(2*q0*q1 + 2*q2*q3);
                z(3) = biasBodyZ + gravityNavZ*(2*q0^2 + 2*q3^2 - 1) + gravityNavX*(2*q0*q2 + 2*q1*q3) - gravityNavY*(2*q0*q1 - 2*q2*q3);
            else
                % Non-zero linear acceleration present in accelerometer
                % signal
                acceleration = stateparts(filt, 'Acceleration');     
                accelNavX = acceleration(1);
                accelNavY = acceleration(2);
                accelNavZ = acceleration(3);
                z(1) = biasBodyX - (accelNavX - gravityNavX)*(2*q0^2 + 2*q1^2 - 1) - (accelNavY - gravityNavY)*(2*q0*q3 + 2*q1*q2) + (accelNavZ - gravityNavZ)*(2*q0*q2 - 2*q1*q3);
                z(2) = biasBodyY - (accelNavY - gravityNavY)*(2*q0^2 + 2*q2^2 - 1) + (accelNavX - gravityNavX)*(2*q0*q3 - 2*q1*q2) - (accelNavZ - gravityNavZ)*(2*q0*q1 + 2*q2*q3);
                z(3) = biasBodyZ - (accelNavZ - gravityNavZ)*(2*q0^2 + 2*q3^2 - 1) - (accelNavX - gravityNavX)*(2*q0*q2 + 2*q1*q3) + (accelNavY - gravityNavY)*(2*q0*q1 - 2*q2*q3);
            end
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
            %  STATETRANSITION returns a struct with identical fields as
            %  the output of sensorstates. The returned struct describes
            %  the per-state transition function for the sensor states.
            %
            %  This function is called by the insEKF filter FILT when the
            %  PREDICT method of the FILT function is called. The FILT
            %  input is a handle to the calling insEKF. The DT and varargin
            %  inputs are the corresponding inputs to the predict method.
            %
            %  Implementing this method is optional. If this method is not
            %  implemented, it is assumed that all states defined in
            %  sensorstates should be modeled as constant over time.
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
            %  This function is called internally by FILT when its FUSE or
            %  RESIDUAL methods are invoked.
            %
            %  Implementing this method is optional. If this method is not
            %  implemented, a numerical Jacobian will be used instead.
            %
            %   See also: insEKF

            grav = getGravity(sensor, filt);
            orient = stateparts(filt, 'Orientation');         
            gravityNavX = grav(1);
            gravityNavY = grav(2);
            gravityNavZ = grav(3);
            q0 = orient(1);
            q1 = orient(2);
            q2 = orient(3);
            q3 = orient(4);

            oidx = stateinfo(filt, 'Orientation');
            bidx = stateinfo(filt, sensor, 'Bias');

            states = filt.State;
            dhdx = zeros(3, numel(states), 'like', states);
            
            
            if isConstVel(sensor, filt)
                dhdx(1,oidx) = [4*gravityNavX*q0 + 2*gravityNavY*q3 - 2*gravityNavZ*q2, 4*gravityNavX*q1 + 2*gravityNavY*q2 + 2*gravityNavZ*q3, 2*gravityNavY*q1 - 2*gravityNavZ*q0, 2*gravityNavY*q0 + 2*gravityNavZ*q1];
                dhdx(1,bidx) = [1, 0, 0];
                
                dhdx(2,oidx) = [4*gravityNavY*q0 - 2*gravityNavX*q3 + 2*gravityNavZ*q1, 2*gravityNavX*q2 + 2*gravityNavZ*q0, 2*gravityNavX*q1 + 4*gravityNavY*q2 + 2*gravityNavZ*q3, 2*gravityNavZ*q2 - 2*gravityNavX*q0];
                dhdx(2,bidx) = [0, 1, 0];
                
                dhdx(3,oidx) = [2*gravityNavX*q2 - 2*gravityNavY*q1 + 4*gravityNavZ*q0, 2*gravityNavX*q3 - 2*gravityNavY*q0, 2*gravityNavX*q0 + 2*gravityNavY*q3, 2*gravityNavX*q1 + 2*gravityNavY*q2 + 4*gravityNavZ*q3];
                dhdx(3,bidx) = [0, 0, 1];              
            else
                acceleration = stateparts(filt, 'Acceleration');     
                accelNavX = acceleration(1);
                accelNavY = acceleration(2);
                accelNavZ = acceleration(3);
                aidx = stateinfo(filt, 'Acceleration'); 

                dhdx(1,oidx) = [2*q2*(accelNavZ - gravityNavZ) - 2*q3*(accelNavY - gravityNavY) - 4*q0*(accelNavX - gravityNavX), - 4*q1*(accelNavX - gravityNavX) - 2*q2*(accelNavY - gravityNavY) - 2*q3*(accelNavZ - gravityNavZ), 2*q0*(accelNavZ - gravityNavZ) - 2*q1*(accelNavY - gravityNavY), - 2*q0*(accelNavY - gravityNavY) - 2*q1*(accelNavZ - gravityNavZ)];
                dhdx(1,aidx) = [1 - 2*q1^2 - 2*q0^2, - 2*q0*q3 - 2*q1*q2, 2*q0*q2 - 2*q1*q3];
                dhdx(1,bidx) = [1, 0, 0];
                
                dhdx(2,oidx) = [2*q3*(accelNavX - gravityNavX) - 4*q0*(accelNavY - gravityNavY) - 2*q1*(accelNavZ - gravityNavZ), - 2*q2*(accelNavX - gravityNavX) - 2*q0*(accelNavZ - gravityNavZ), - 2*q1*(accelNavX - gravityNavX) - 4*q2*(accelNavY - gravityNavY) - 2*q3*(accelNavZ - gravityNavZ), 2*q0*(accelNavX - gravityNavX) - 2*q2*(accelNavZ - gravityNavZ)];
                dhdx(2,aidx) = [2*q0*q3 - 2*q1*q2, 1 - 2*q2^2 - 2*q0^2, - 2*q0*q1 - 2*q2*q3];
                dhdx(2,bidx) = [0, 1, 0];
                
                dhdx(3,oidx) = [2*q1*(accelNavY - gravityNavY) - 2*q2*(accelNavX - gravityNavX) - 4*q0*(accelNavZ - gravityNavZ), 2*q0*(accelNavY - gravityNavY) - 2*q3*(accelNavX - gravityNavX), - 2*q0*(accelNavX - gravityNavX) - 2*q3*(accelNavY - gravityNavY), - 2*q1*(accelNavX - gravityNavX) - 2*q2*(accelNavY - gravityNavY) - 4*q3*(accelNavZ - gravityNavZ)];
                dhdx(3,aidx) = [- 2*q0*q2 - 2*q1*q3, 2*q0*q1 - 2*q2*q3, 1 - 2*q3^2 - 2*q0^2];
                dhdx(3,bidx) = [0, 0, 1];
            end
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

    % Not part of the public API. These methods may change in the future.
    methods (Access = protected)
        function tf = isConstVel(~,filt) 
            idx = stateinfo(filt);
            % If we are tracking acceleration, we cannot assume constant
            % velocity. (i.e. zero acceleration)
            tf = ~isfield(idx, 'Acceleration'); 
        end
        
        function grav = getGravity(~, filt)
            % Return gravity in the appropriate reference frame
            grav = zeros(1,3, 'like', filt.State);
            rf = getReferenceFrameObject(filt);
            grav(rf.GravityIndex) = rf.GravitySign * rf.GravityAxisSign * ...
                fusion.internal.UnitConversions.geeToMetersPerSecondSquared(1);
            
        end
    end
end



