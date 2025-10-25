classdef KeepMeasuringState
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2018 The MathWorks, Inc.
    
    methods (Abstract)
        B = switchToNext(A)
    end
    
    methods (Sealed)
        function state = reset(~)
            import matlab.unittest.measurement.internal.looping.Unused;
            state = Unused;
        end
    end
end