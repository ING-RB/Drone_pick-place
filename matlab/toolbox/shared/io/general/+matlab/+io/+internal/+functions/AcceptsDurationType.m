classdef AcceptsDurationType < matlab.io.internal.FunctionInterface
    %ACCEPTSDURATIONTYPE An interface for functions which accept a
    %DURATIONTYPE.
    
    % Copyright 2018 The MathWorks, Inc.
    properties (Parameter) % Properties Supported by text files
        DurationType = 'duration';
    end
    
    methods
        function func = set.DurationType(func,rhs)
            func.DurationType = validatestring(rhs,{'duration','text'});
        end
    end
end