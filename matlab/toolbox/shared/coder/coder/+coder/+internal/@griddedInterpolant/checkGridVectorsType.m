function checkGridVectorsType(gridVectorsCellInput)
    % helper function for checkQueryGridVectorsCountAndType

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen
    

    X0 = gridVectorsCellInput{1};
    clsX0 = class(X0);
    n = numel(gridVectorsCellInput);
    for i = 1:n
        Xi = gridVectorsCellInput{i};
        coder.internal.griddedInterpolant.checkFullRealCoords(Xi);
        coder.internal.assert(isa(Xi, clsX0), 'MATLAB:griddedInterpolant:GridOfMixedDataTypesErrId');
    end
end
