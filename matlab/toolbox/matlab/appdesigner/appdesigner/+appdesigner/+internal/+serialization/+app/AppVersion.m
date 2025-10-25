classdef AppVersion < handle
    % This class contains a property for version info
    
    % Copyright 2015-2020 The MathWorks, Inc.
    
    properties
        ToolboxVer = version('-release');
        FullVersion = version;
        MinimumSupportedVersion = 'R2016a';
    end
    
    properties (Constant)
        % Standard app type
        StandardApp = 'Standard';
        
        % Responsive app type
        ResponsiveApp = 'Responsive';
        
        % MLAPPVersion 1 - initial file format
        MLAPPVersionOne = '1';

        % MLAPPVersion 2 - file format from 18a onward
        MLAPPVersionTwo = '2';
    end
    
end
