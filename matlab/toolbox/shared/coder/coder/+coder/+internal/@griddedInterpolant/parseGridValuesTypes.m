function parseGridValuesTypes(gridValues)
    % helper function to type test values
    % inline some of these helper functions ? most of them contain
    % only coder.internal.assert calls

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    coder.internal.assert(isfloat(gridValues), ...
        'MATLAB:griddedInterpolant:NonFloatValuesErrId');
    coder.internal.assert(~issparse(gridValues), ...
        'MATLAB:griddedInterpolant:SparseInterpValuesErrId');
    
end
