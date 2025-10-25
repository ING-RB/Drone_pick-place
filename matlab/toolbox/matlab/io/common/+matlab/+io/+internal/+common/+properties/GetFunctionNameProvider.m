classdef GetFunctionNameProvider < matlab.io.internal.FunctionInterface
%

% Copyright 2024 The MathWorks, Inc.

    properties (Abstract, Constant, Access = protected)
        FunctionName;
    end

    methods (Hidden)
        function func_name = getFunctionName(obj)
            func_name = obj.FunctionName;
        end
    end
end
