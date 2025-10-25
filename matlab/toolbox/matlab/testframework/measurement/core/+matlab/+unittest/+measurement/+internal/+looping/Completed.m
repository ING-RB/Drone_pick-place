classdef Completed < matlab.unittest.measurement.internal.looping.KeepMeasuringState
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2018 The MathWorks, Inc.
    
    methods(Access = {?matlab.unittest.measurement.internal.looping.Measuring})
        function state = Completed
        end
    end
    
    methods
        
        function state = switchToNext(~)
            import matlab.unittest.measurement.internal.looping.Sink;
            state = Sink;
        end
        
    end
    
end