function n = getGridDim(gridValues, numGridVectors)
    % returns ndims as 1 for a vector
    % returns proper dims in case function is multi valued

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    coder.internal.prefer_const(numGridVectors);
    if (numGridVectors == 0)
        if isvector(gridValues)
            n = 1; 
        else
            n = coder.internal.ndims(gridValues);
        end
    else
        n = min(numGridVectors, coder.internal.ndims(gridValues));
    end
end
