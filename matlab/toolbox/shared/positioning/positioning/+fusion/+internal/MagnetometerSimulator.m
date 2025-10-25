classdef (Hidden) MagnetometerSimulator < fusion.internal.IMUSensorSimulator
%   Internal class used by imuSensor. 
%
%   This class is used to calculate sensor output values based on ideal
%   input and model parameters.
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2017-2019 The MathWorks, Inc.
    
%#codegen
    
    methods
        % Constructor
        function obj = MagnetometerSimulator(varargin)
            obj = obj@fusion.internal.IMUSensorSimulator(varargin{:});
        end
    end
    
    methods (Access = protected)
        function setupImpl(obj, magneticfield, ~, ~)
            setupImpl@fusion.internal.IMUSensorSimulator(obj, magneticfield);
        end
        function out = stepImpl(obj, magneticfield, orientation, randNums)
            out = stepImpl@fusion.internal.IMUSensorSimulator(obj, magneticfield, orientation, randNums);
        end
    end 
end
