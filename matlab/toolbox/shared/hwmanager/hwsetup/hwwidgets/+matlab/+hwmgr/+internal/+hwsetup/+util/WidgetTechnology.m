classdef WidgetTechnology < handle
    % matlab.hwmgr.internal.hwsetup.util.WidgetTechnology is a class that
    % defines the available technology options to define the HW Setup
    % widgets and exposes methods to find all available options as well as
    % the current technology option being used
    
    % Copyright 2016-2024 The MathWorks, Inc.
    
    properties(Constant)
        App = 'appdesigner';
    end
    
    methods(Static)
        function out = getAvailableTechnologies()
            out = {...
                matlab.hwmgr.internal.hwsetup.util.WidgetTechnology.App...
                };
        end
        
        function out = getTechnology()
            out = matlab.hwmgr.internal.hwsetup.util.WidgetTechnology.App;
        end
    end
end
