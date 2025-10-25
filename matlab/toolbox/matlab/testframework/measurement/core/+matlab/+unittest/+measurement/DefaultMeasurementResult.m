classdef DefaultMeasurementResult < matlab.unittest.measurement.internal.NumericMeasurementResult
    % DefaultMeasurementResult - Default implementation of MeasurementResult
    % interface with no specification of the measured variable.
    %
    %   Any MeasurementResult object saved from previous releases will be 
    %   loaded as a DefaultMeasurementResult instance.
    %
    %   The test framework constructs instances of this class, so there
    %   is no need for test authors to construct this class directly.
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    properties(Hidden)
        CalibrationResult = matlab.unittest.measurement.DefaultMeasurementResult.empty;
        CalibrationValue = 0;
    end
    
    properties (Hidden, SetAccess = protected)
        MeasuredVariableName = 'MeasuredValue';
    end
    
    methods(Hidden)
        function result = DefaultMeasurementResult(names, varargin)
            import matlab.unittest.measurement.DefaultMeasurementResult;
            
            if nargin < 1
                return % Allow preallocation
            end
            
            result = DefaultMeasurementResult.empty;
            result = result.initializeMeasurementResult(names, varargin{:});
        end
    end
    
end

% LocalWords:  preallocation
