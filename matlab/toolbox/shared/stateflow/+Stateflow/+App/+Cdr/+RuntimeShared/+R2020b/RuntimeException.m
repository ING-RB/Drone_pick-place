classdef RuntimeException < MException
%

%   Copyright 2019 The MathWorks, Inc.

    properties
        modifiedStack
    end
    
    methods
        function ex = RuntimeException(originalEx)
            if isempty(originalEx.identifier)
                errId = 'MATLAB:UndefinedErrorIdentifier';
            else
                 errId = originalEx.identifier;
            end
            ex = ex@MException(errId, originalEx.message);
        end
    end
    methods (Access=protected)
        function stack = getStack(ex)
            %stack = getStack@MException(ex);
            instH = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.instance;
            stack = instH.runtimeExceptionStacks.pruned;
            instH.runtimeExceptionStacks = [];
        end
    end
end
