classdef ReadTableInputs < matlab.io.internal.FunctionInterface
%

%   Copyright 2018 The MathWorks, Inc.

    properties (Parameter)
        ReadVariableNames(1,1) {mustBeNumericOrLogical} = true;
        ReadRowNames(1,1) {mustBeNumericOrLogical} = false;
    end
end