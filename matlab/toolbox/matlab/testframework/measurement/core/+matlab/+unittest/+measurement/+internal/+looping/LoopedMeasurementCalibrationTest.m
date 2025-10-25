classdef LoopedMeasurementCalibrationTest < matlab.unittest.TestCase & matlab.unittest.measurement.internal.Measurable
    %

    % Copyright 2024 The MathWorks, Inc.

    methods(Test)        
        function emptyTest(testCase)
            for i = 1:testCase.loopCount()
            end
        end
    end
    
end
