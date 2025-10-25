classdef MLAPPWarning < handle
    % Represents a warning during the loading process    
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties
        % String identifier
        Id
        
        % Struct holding information, specific to the warning        
        Info
    end
    
    methods
        function obj = MLAPPWarning(id, warningInfo)
            narginchk(2,2)
            
            obj.Id = id;
            obj.Info = warningInfo;
        end                
    end
end

