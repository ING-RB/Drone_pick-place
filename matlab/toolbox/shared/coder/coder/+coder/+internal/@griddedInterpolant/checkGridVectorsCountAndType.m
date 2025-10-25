function valid = checkGridVectorsCountAndType(gridVectorsCellInput, gridValues, matchAgainstGridValues, errorOut)
    % matches type and dimension of vectors and values

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    if nargin < 4
        errorOut = true;
    end

    coder.internal.prefer_const(matchAgainstGridValues);

    gridDim = coder.internal.griddedInterpolant.getGridDim(gridValues, numel(gridVectorsCellInput));
    valid = coder.internal.griddedInterpolant.checkQueryGridVectorsCountAndType(gridVectorsCellInput, ...
        gridValues, gridDim, matchAgainstGridValues,errorOut);

end
