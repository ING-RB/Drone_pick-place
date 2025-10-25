classdef CombinedParameterSet
    % CombinedParameterSet holds onto an array of Parameter objects operating at different scopes
        
    %  Copyright 2020 The MathWorks, Inc
    properties
        Parameters matlab.unittest.parameters.Parameter
    end
    
    methods
        function set = CombinedParameterSet(params)
            set.Parameters = params;
        end
    end
end