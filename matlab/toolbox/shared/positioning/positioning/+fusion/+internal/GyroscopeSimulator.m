classdef (Hidden) GyroscopeSimulator < fusion.internal.IMUSensorSimulator
%   Internal class used by imuSensor. 
%
%   This class is used to calculate sensor output values based on ideal
%   input and model parameters.
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2017-2019 The MathWorks, Inc.
    
%#codegen

    properties
        % This property is tunable. 
        AccelerationBias = [0 0 0];
    end
    
    properties (Access = private)
        pAcceleration;
    end
    
    methods
        % Constructor
        function obj = GyroscopeSimulator(varargin)
            obj = obj@fusion.internal.IMUSensorSimulator(varargin{:});
        end
    end
    
    methods (Access = protected)
        function setupImpl(obj, angularvelocity, ~, ~, ~)
            setupImpl@fusion.internal.IMUSensorSimulator(obj,angularvelocity);
        end

        function out = stepImpl(obj, angularvelocity, acceleration, orientation, randNums)
            obj.pAcceleration = acceleration;

            out = stepImpl@fusion.internal.IMUSensorSimulator(obj, angularvelocity, orientation, randNums);
        end
        
        function envDrift = stepEnvironmentalDriftModel(obj, numSamples)
            envDrift = stepEnvironmentalDriftModel@fusion.internal.IMUSensorSimulator(obj, numSamples);
            accelerationDrift = bsxfun(@times, obj.pAcceleration, obj.AccelerationBias);
            envDrift = envDrift + accelerationDrift;
        end
        
        function s = saveObjectImpl(obj)
            % Save public properties.
            s = saveObjectImpl@fusion.internal.IMUSensorSimulator(obj);
            
            % Save private properties. 
            if isLocked(obj)
                s.pAcceleration = obj.pAcceleration;
            end
        end
        
        function loadObjectImpl(obj, s, wasLocked)
            % Load public properties. 
            loadObjectImpl@fusion.internal.IMUSensorSimulator(obj, s, wasLocked);
            
            % Load private properties.
            if wasLocked
                obj.pAcceleration = s.pAcceleration;
            end
        end
    end
end
