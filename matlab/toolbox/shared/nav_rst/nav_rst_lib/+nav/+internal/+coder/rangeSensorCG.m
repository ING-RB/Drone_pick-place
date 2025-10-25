classdef (Hidden) rangeSensorCG < nav.internal.RangeSensorBase
%RANGESENSORCG Codegen class for rangeSensor
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2019 The MathWorks, Inc.

%#codegen

    methods
        function obj = rangeSensorCG(varargin)
            obj@nav.internal.RangeSensorBase(varargin{:});
        end
    end

    methods (Static, Hidden)
        function name = matlabCodegenUserReadableName
            name = 'rangeSensor';
        end
    end
end
