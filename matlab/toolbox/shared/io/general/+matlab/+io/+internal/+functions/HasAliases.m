classdef HasAliases < matlab.io.internal.FunctionInterface
% function interface for declaring aliases

% Copyright 2020 MathWorks, Inc.

    properties (Transient, Hidden, Access = {?matlab.io.internal.functions.ExecutableFunction})
        Aliases(1,:) matlab.io.internal.functions.ParameterAlias = matlab.io.internal.functions.ParameterAlias.empty(1,0);
    end
    
    methods (Abstract)
        v = getAliases(~);
    end

end

