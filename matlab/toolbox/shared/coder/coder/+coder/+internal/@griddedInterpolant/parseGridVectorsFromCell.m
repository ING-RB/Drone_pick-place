function valid = parseGridVectorsFromCell(gridVectorsCellInput, gridValues, matchAgainstGridValues, errorOut)
    % Used in testing if the assigned gridvectors 
    % are valid wrt gridvalues. 
    % Also parses gridvector inputs for sample points.

    %   Copyright 2022 The MathWorks, Inc.
    
    %#codegen

    if nargin < 4
        % Using this flag to test if object is in a valid state without
        % error out.
        errorOut = true;
    end
    
    valid = true;
    valid = valid && coder.internal.griddedInterpolant.checkGridVectorsCountAndType(gridVectorsCellInput, ...
        gridValues, matchAgainstGridValues, errorOut);
    
    valid = valid && coder.internal.griddedInterpolant.checkGridVectorsSize(gridVectorsCellInput, ...
        gridValues, matchAgainstGridValues, errorOut);

    coder.internal.griddedInterpolant.checkStrictlyIncreasingFinites(gridVectorsCellInput);

end
