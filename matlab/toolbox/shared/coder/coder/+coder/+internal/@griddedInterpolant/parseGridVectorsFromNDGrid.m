function X = parseGridVectorsFromNDGrid(ndgrid, nd, gridValues)
    % extracts the grid vectors if a full ndgrid is supplied. 

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen
    
    n = coder.internal.griddedInterpolant.getGridDim(gridValues, nd);
    coder.internal.assert(n==nd, 'MATLAB:griddedInterpolant:NumCoordsGridNdimsMismatchErrId');
    
    coder.internal.griddedInterpolant.checkGridArraysType(ndgrid, nd, gridValues, false);
            
    X0 = ndgrid{1};
    samplePointsShapeMatchesGridValuesSize = true;
    
    if (n == 1)
        coder.internal.assert(isvector(X0), 'MATLAB:griddedInterpolant:MixedGridCoordSizeErrId');
        if isvector(gridValues)
            numValues = numel(gridValues);
        else
            numValues = size(gridValues,1);
        end
        coder.internal.assert(numValues == numel(X0), ...
            'MATLAB:griddedInterpolant:CompVecValueMismatchErrId',1, numValues);
    else
        dimsV = size(gridValues);
        coder.unroll(coder.internal.isConst(n));
        for i=1:n
            dimsX = size(ndgrid{i});
            samplePointsShapeMatchesGridValuesSize = samplePointsShapeMatchesGridValuesSize & isequal(dimsV(1:n), dimsX);
        end
    end

    [X,isndgrid] = coder.internal.griddedInterpolant.createGridVectorsFromNDGrid(ndgrid, n);
    
    coder.internal.assert(isndgrid || ~coder.internal.griddedInterpolant.ismeshgrid(ndgrid, n) || n~=2, ...
        'MATLAB:griddedInterpolant:NdgridNotMeshgrid2DErrId');
    coder.internal.assert(isndgrid || ~coder.internal.griddedInterpolant.ismeshgrid(ndgrid, n) || n==2, ...
        'MATLAB:griddedInterpolant:NdgridNotMeshgrid3DErrId');
    coder.internal.assert(isndgrid || coder.internal.griddedInterpolant.ismeshgrid(ndgrid, n), ...
        'MATLAB:griddedInterpolant:BadGridErrId');
    
    coder.internal.assert(samplePointsShapeMatchesGridValuesSize, ...
        'MATLAB:griddedInterpolant:MixedGridCoordSizeErrId');

    coder.internal.griddedInterpolant.checkStrictlyIncreasingFinites(X);
end
