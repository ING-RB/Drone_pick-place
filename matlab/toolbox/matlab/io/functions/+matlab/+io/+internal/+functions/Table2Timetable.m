classdef Table2Timetable < matlab.io.internal.FunctionInterface ...
    & matlab.io.internal.functions.HasAliases
    %
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    methods
        function v = getAliases(~)
            v =  matlab.io.internal.functions.ParameterAlias("SampleRate","SamplingRate");
        end
    end
    properties (Parameter)
        RowTimes
        StartTime = seconds(0);
        SampleRate
        TimeStep
    end
end
