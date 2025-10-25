classdef Unused < matlab.unittest.measurement.internal.looping.KeepMeasuringState
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2018 The MathWorks, Inc.
    
    methods
        function state = switchToNext(~)
            import matlab.unittest.measurement.internal.looping.Estimating;
            state = Estimating;
        end
    end
    
end