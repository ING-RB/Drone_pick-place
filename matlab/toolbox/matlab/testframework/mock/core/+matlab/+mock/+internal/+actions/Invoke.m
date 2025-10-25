classdef Invoke <  matlab.mock.actions.PropertyGetAction & ...
        matlab.mock.actions.PropertySetAction
    % This class is undocumented and may change in a future release.
    
    % Copyright 2016-2017 The MathWorks, Inc.
    
    properties (SetAccess=immutable)
        Function (1,1) function_handle = @()[];
    end
    
    methods
        function action = Invoke(fcn)
            action.Function = fcn;
        end
        
        function value = getProperty(action, ~, ~, object)
            value = action.Function(object);
        end
        
        function setProperty(action, ~, ~, object, value)
            action.Function(object, value);
        end
    end
end

