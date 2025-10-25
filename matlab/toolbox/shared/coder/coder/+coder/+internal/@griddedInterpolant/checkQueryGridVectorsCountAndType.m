function valid = checkQueryGridVectorsCountAndType(gridVectorsCellInput, gridValues, gridDim, ...
                matchAgainstGridValues, errorOut)
    % helper function for checkGridVectorsCountAndType
    
    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    if nargin < 5
        errorOut = true;
    end

    coder.internal.prefer_const(matchAgainstGridValues, gridDim);
    
    valid = coder.internal.griddedInterpolant.checkGridVectorsCount( ...
        gridVectorsCellInput, gridValues, gridDim, matchAgainstGridValues, errorOut);
    
    coder.internal.griddedInterpolant.checkGridVectorsType(gridVectorsCellInput);

end
