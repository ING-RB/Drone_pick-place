classdef (Hidden) altimeterSensorCG < fusion.internal.AltimeterSensorBase
%ALTIMETERSENSORCG - Codegen class for altimeterSensor
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen
    
    methods
        function obj = altimeterSensorCG(varargin)
            obj@fusion.internal.AltimeterSensorBase(varargin{:});
        end
    end
    
    methods (Static, Hidden)
        function name = matlabCodegenUserReadableName
            name = 'altimeterSensor';
        end
    end
end
