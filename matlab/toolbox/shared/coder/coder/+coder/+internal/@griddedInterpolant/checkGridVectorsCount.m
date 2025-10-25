function valid = checkGridVectorsCount(gridVectorsCellInput, ~, gridDim, ...
                matchAgainstGridValues, errorOut)
    % helper function for checkQueryGridVectorsCountAndType

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    if nargin < 5
        errorOut = true;
    end

    coder.internal.prefer_const(matchAgainstGridValues, gridDim);
    valid = true;
    if errorOut
        if (~matchAgainstGridValues)
            coder.internal.assert(numel(gridVectorsCellInput)>=1, ...
                'MATLAB:griddedInterpolant:DegenerateGridErrId')
        else
            numGridVectors = numel(gridVectorsCellInput);
            coder.internal.assert(gridDim == numGridVectors, ...
                'MATLAB:griddedInterpolant:NumCoordsGridNdimsMismatchErrId');
        end
    else
        if (~matchAgainstGridValues)
            valid = valid && (numel(gridVectorsCellInput)>=1);
        else
            numGridVectors = numel(gridVectorsCellInput);
            valid = valid && (gridDim == numGridVectors);
        end

    end

end
