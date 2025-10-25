classdef tmwSuppliedSensors
%   This class is for internal use only. It may be removed in the future.
%TMWSUPPLIEDSENSORS MathWorks supplied sensors for INS Filters

%   Copyright 2021 The MathWorks, Inc.


    methods (Static)
        function l = fullList
            l = cat(2, positioning.internal.tmwSuppliedSensors.orientation, ...
                {'insGPS'});
        end
        function l = orientation
            l = {'insAccelerometer', 'insGyroscope', 'insMagnetometer'};
        end
    end
end
