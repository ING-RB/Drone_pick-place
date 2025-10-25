classdef (Abstract) FrameworkContext
    
    properties (SetAccess = immutable)
        IsClientApp
        IsHwmgrApp
    end
    
    methods
        
        function obj = FrameworkContext(clientAppFlag, hwmgrAppFlag)
            obj.IsClientApp = clientAppFlag;
            obj.IsHwmgrApp = hwmgrAppFlag;
        end
        
    end
end