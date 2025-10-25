classdef INSSensorModel < positioning.internal.INSSensorModelBase
%INSSENSORMODEL Base class for sensors used with INS filters
%   The INSSensorModel defines the interface for sensor classes that can be
%   used with an INS fusion filter, like the insEKF.
%
%   To define a new sensor : 
%       * Inherit from this class and implement at least a measurement method. 
%       * Optionally, if a higher fidelity simulation is needed, also 
%         implement a measurementJacobian (the Jacobian of the measurement
%         function). If the measurementJacobian is not implemented a numeric
%         Jacobian will be computed internally.
%
%   To define a sensor whose measurement function requires the use of a
%   tracked state, additionally:
%       * Implement the sensorstates method to define the tracked state.
%       * Optionally, implement the stateTransition method if the state is
%         not constant over time.
%       * Optionally, implement a stateTransitionJacobian method.
%         Alternatively, a numeric Jacobian will be computed internally.
%
%   See also: insEKF, insAccelerometer       
%
%

%   Copyright 2021 The MathWorks, Inc.      

%#codegen


    %%%% Required methods %%%%
    methods (Abstract)
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
        z = measurement(sensor, filt)
    end
    
    %%%% Optional Methods %%%%
    methods 
        function s = sensorstates(filt, opts) %#ok<*INUSD>
            %SENSORSTATES Define the tracked states for this sensor
            %  SENSORSTATES returns a scalar struct which describes the
            %  states used by this sensor model and tracked by the insEKF
            %  filter. The field names describe the individual state
            %  quantities and allow access to the estimates of those
            %  quantities through the statesparts function. The values of
            %  the struct determine the size and default values of the
            %  state vector. The input FILT is the insEKF object. The input
            %  OPTS is the insOptions used to build the filter. 
            %
            %  Implementing this method is only required if sensor-specific
            %  states, such as biases, need to be estimated during
            %  filtering.
            %
            %  See also: insEKF, insEKF/stateparts
            
            % Struct w/o fields. Track no states.
            s = struct;  
        end
    end
    
    methods
        function statesdot = stateTransition(sensor, filt, dt, varargin)
            %STATETRANSITION State transition function for sensor states
            %  STATETRANSITION returns a struct with identical fields
            %  as the output of sensorstates. The returned struct
            %  describes the per-state transition function for the sensor
            %  states.
            %
            %  This function is called by the insEKF filter FILT when the
            %  PREDICT method of the FILT function is called. The FILT input is
            %  a handle to the calling insEKF. The DT and varargin inputs are
            %  the corresponding inputs to the predict method.
            %
            %  Implementing this method is optional. If this method is not
            %  implemented, it is assumed that all states defined in
            %  sensorstates should be modeled as a constant over time.
            %
            %   See also: positioning.INSSensorModel/sensorstates
            
            statesdot = stateTransition@positioning.internal.INSSensorModelBase(sensor, filt, dt, varargin{:});
        end
        
        function  dhdx = measurementJacobian(sensor, filt)
            %MEASUREMENTJACOBIAN Jacobian of the measurement method
            %  MEASUREMENTJACOBIAN returns an M-by-NS array which is the
            %  Jacobian of the MEASUREMENT method relative to the State
            %  property of filter FILT. The FILT input is an instance of the
            %  insEKF filter. Here M is the number of elements in a sensor
            %  measurement and NS is the number of elements in the State
            %  property of FILT.
            %
            %   This function is called internally by FILT when its FUSE or
            %   RESIDUAL methods are invoked.
            %
            %   Implementing this method is optional. If this method is not
            %   implemented, a numerical Jacobian will be used instead.
            %
            %   See also: insEKF
            
            dhdx = measurementJacobian@positioning.internal.INSSensorModelBase(sensor, filt);
        end
        
        function dfdx = stateTransitionJacobian(sensor, filt, dt, varargin)
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
            
            dfdx = stateTransitionJacobian@positioning.internal.INSSensorModelBase(sensor, filt, dt, varargin{:});

        end
    end



end
