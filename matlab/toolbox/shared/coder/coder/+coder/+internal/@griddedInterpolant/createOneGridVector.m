function Xi = createOneGridVector(numel, clsID, fillWithDefaultGridCoordinates) 
    % creates gridvectors if sample value is provided without sample points
    % eg, for G = griddedInterpolant(V) grid vectors are auto generated.

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    coder.internal.prefer_const(clsID, fillWithDefaultGridCoordinates)

    if isequal(clsID, 'double')  
        if (fillWithDefaultGridCoordinates)
            Xi = double(1:numel);
        else
            Xi = double.empty(numel, 0);
        end
    else
        if (fillWithDefaultGridCoordinates)
            Xi = single(1:numel);
        else
            Xi = single.empty(numel, 0);
        end
    end

end
