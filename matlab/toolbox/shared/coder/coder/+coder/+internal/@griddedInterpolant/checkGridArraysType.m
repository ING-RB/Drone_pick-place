function checkGridArraysType(gridArrays, gridDim, ~, useQueryErrorMsg)
    % checks types and tests if the vectors are of the same type in
    % cell of grid vectors.

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    coder.internal.prefer_const(useQueryErrorMsg, gridDim);      

    X0 = gridArrays{1};
    clsX0 = coder.const(class(X0));
    
    coder.unroll(coder.internal.isConst(gridDim));
    for i = 1:gridDim
        coder.internal.griddedInterpolant.checkFullRealCoords(gridArrays{i});
        coder.internal.errorIf(~isa(gridArrays{i}, clsX0) && useQueryErrorMsg, 'MATLAB:griddedInterpolant:QueryOfMixedDataTypesErrId');
        coder.internal.errorIf(~isa(gridArrays{i}, clsX0) && ~useQueryErrorMsg, 'MATLAB:griddedInterpolant:GridOfMixedDataTypesErrId');
    end
end
