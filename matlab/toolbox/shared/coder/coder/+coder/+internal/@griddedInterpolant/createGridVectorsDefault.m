function X = createGridVectorsDefault(gridValues)
    % creates default grid vectors if input values are provided
    % this function is also called when no inputs are given

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    clsID = class(gridValues);
    
    if coder.internal.isConstTrue(isvector(gridValues))
        n = 1;
    else
        n = coder.internal.ndims(gridValues);
    end
    X = cell(1,n);
    doDefault = true;
    if (n == 1)
        for i = 1:n
            Xi = coder.internal.griddedInterpolant.createOneGridVector(numel(gridValues), clsID, doDefault);
            X{i} = Xi;
        end
        
    else
        dims = size(gridValues);
        for i = 1:n
            Xi = coder.internal.griddedInterpolant.createOneGridVector(dims(i), clsID, doDefault);
            X{i} = Xi;
        end
    end
    
end
