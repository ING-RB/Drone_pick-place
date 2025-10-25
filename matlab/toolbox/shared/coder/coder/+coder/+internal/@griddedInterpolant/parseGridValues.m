function parseGridValues(gridValues, numGridVectors)
    % values are tested for type and non emptiness
    % the testing with vectors is done by parseGridVectors function

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    coder.internal.griddedInterpolant.parseGridValuesTypes(gridValues)

    coder.internal.assert(~isempty(gridValues), ...
        'MATLAB:griddedInterpolant:DegenerateGridErrId')

    n = coder.internal.griddedInterpolant.getGridDim(gridValues, numGridVectors);
    if (n == 1 && isvector(gridValues))
        coder.internal.assert(numel(gridValues)>=2, ...
            'MATLAB:griddedInterpolant:DegenerateGridErrId')
    else
        dims = size(gridValues);
        coder.unroll(coder.internal.isConst(n));
        for i=1:n
            coder.internal.assert(dims(i)>=2, ...
                'MATLAB:griddedInterpolant:DegenerateGridErrId')
        end
    end

end
