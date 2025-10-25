classdef KeepMeasuringCalibrationTest < matlab.unittest.TestCase & matlab.unittest.measurement.internal.Measurable
    %

    % Copyright 2018 The MathWorks, Inc.

    methods(Test)        
        function emptyTest(testCase)
            while(testCase.keepMeasuring)
            end
        end
    end
end