%SubsrefTabularRowOperation
% An operation that performs row subsref with a tall logical column vector
% as indices. This is an FilterOperation with special treatment in the tall
% lazy evaluation framework for optimization.

%   Copyright 2022 The MathWorks, Inc.

classdef LogicalRowSubsrefOperation < matlab.bigdata.internal.lazyeval.FilterOperation
    methods
        % SubsrefRowFilterOperation constructor
        function obj = LogicalRowSubsrefOperation(numInputs)
            obj = obj@matlab.bigdata.internal.lazyeval.FilterOperation(numInputs);
        end
    end
end
