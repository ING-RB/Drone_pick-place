classdef Estimating < matlab.unittest.measurement.internal.looping.KeepMeasuringState
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2018 The MathWorks, Inc.
    
    methods(Access = {?matlab.unittest.measurement.internal.looping.Unused})
        function state = Estimating
        end
    end 
    
    methods
        
        function state = switchToNext(~)
            import matlab.unittest.measurement.internal.looping.Measuring;
            state = Measuring;
        end
        
    end
    
end