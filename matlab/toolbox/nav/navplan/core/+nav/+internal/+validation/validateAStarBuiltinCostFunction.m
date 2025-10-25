function [strVal,idx,validStringsDist] = validateAStarBuiltinCostFunction(costFuncStr)
%This function is for internal use only. It may be removed in the future.

%validateNavPath Validate a navPath object

%   Copyright 2020-2022 The MathWorks, Inc.

%#codegen

    coder.varsize('strVal');
    validStringsDist = {'Euclidean','Manhattan','Chebyshev','EuclideanSquared'};
    strVal = validatestring(costFuncStr,validStringsDist,'');
    maxLen = 16;
    coder.internal.assert(strlength(strVal)<=maxLen,...
                          'nav:navalgs:plannerastargrid:AssertionFailedLessThan',...
                          'BuiltinCostFunctionLength',16);
    idxTemp = find(strcmp(validStringsDist,strVal));
    idx = idxTemp(1);
end
