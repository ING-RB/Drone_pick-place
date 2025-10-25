classdef (InferiorClasses = ?matlab.unittest.measurement.DefaultMeasurementResult) ...
        TimeResult < matlab.unittest.measurement.internal.NumericMeasurementResult
    % TimeResult - Result from running a TimeExperiment
    %
    %   A matlab.perftest.TimeResult is an instance of the
    %   MeasurementResult class. It contains the result given as
    %   MeasuredTime from running a matlab.perftest.TimeExperiment on a
    %   test suite.
    %
    %   The test framework constructs instances of this class, so there
    %   is no need for test authors to construct this class directly.

    % Copyright 2018-2020 The MathWorks, Inc.
    
    properties(Hidden)
        CalibrationResult = matlab.perftest.TimeResult.empty;
        CalibrationValue = 0;
    end
    
    properties (Hidden, SetAccess = protected)
        MeasuredVariableName = 'MeasuredTime';
    end
    
    methods (Hidden)
        function result = TimeResult(input, varargin)
            import matlab.perftest.TimeResult;
            
            if nargin < 1
                return % Allow preallocation
            elseif nargin == 1 && isa(input, "matlab.unittest.measurement.DefaultMeasurementResult")
                result = TimeResult.convertFromDefault(input);
                result = reshape(result, size(input));
                return
            end
            
            result = TimeResult.empty;
            result = result.initializeMeasurementResult(input, varargin{:});
        end
    end

    methods(Hidden, Static, Access = private)
        function result = convertFromDefault(defaultMR)
            % Convert DefaultMeasurementResult to TimeResult
            import matlab.perftest.TimeResult;
            
            if isempty(defaultMR)
                result = TimeResult.empty;
                return;
            end
            
            % Initialize
            result = TimeResult({defaultMR.Name}, {defaultMR.MeasuredVariableName});
            
            % Convert CalibrationResult
            for i = 1:length(defaultMR)
                calibrationResult = defaultMR(i).CalibrationResult;
                result(i).CalibrationResult = TimeResult.convertFromDefault(calibrationResult);
            end
            
            % Convert other properties
            [result.RunIdentifier] = deal(defaultMR.RunIdentifier);
            [result.InternalTestActivity] = deal(defaultMR.InternalTestActivity);
            [result.CalibrationValue] = deal(defaultMR.CalibrationValue);
            [result.LastMeasurements] = deal(defaultMR.LastMeasurements);
            [result.LastMeasuredValues] = deal(defaultMR.LastMeasuredValues);
        end
    end
end

% LocalWords:  perftest preallocation
