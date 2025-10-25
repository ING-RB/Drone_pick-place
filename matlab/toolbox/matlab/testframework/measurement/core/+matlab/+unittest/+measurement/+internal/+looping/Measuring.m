classdef Measuring < matlab.unittest.measurement.internal.looping.KeepMeasuringState
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2018 The MathWorks, Inc.
    
    methods(Access = {?matlab.unittest.measurement.internal.looping.Estimating})
        function state = Measuring
        end
    end
    
    methods
        
        function state = switchToNext(~)
            import matlab.unittest.measurement.internal.looping.Completed;
            state = Completed;
        end
        
    end
    
end