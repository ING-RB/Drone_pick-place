function valid = checkGridVectorsSize(gridVectorsCellInput, gridValues, matchAgainstGridValues, errorOut)
    % verifies size of grid vector against grid values
    
    %   Copyright 2022 The MathWorks, Inc.

    %#codegen
    
    coder.internal.prefer_const(matchAgainstGridValues);
    
    if nargin < 4
        errorOut = true;
    end

    valid = true;
    n = numel(gridVectorsCellInput);
    for i = 1:n
        Xi = gridVectorsCellInput{i};
        if (~matchAgainstGridValues)
            
            if errorOut
                coder.internal.assert(isvector(Xi), 'MATLAB::griddedInterpolant::NonVecCompVecErrId');
                coder.internal.assert(numel(Xi) >= 2,'MATLAB:griddedInterpolant:DegenerateGridErrId');
            else
                valid = valid && isvector(Xi);
                valid = valid && (numel(Xi) >= 2);
            end
            
        else 

            if isvector(gridValues)
                dims = numel(gridValues);
            else
                dims = size(gridValues);
            end
            
            if errorOut
                coder.internal.assert(isvector(Xi), ...
                    'MATLAB:griddedInterpolant:NonVecCompVecErrId');
                coder.internal.assert(dims(i) == numel(Xi), ...
                    'MATLAB:griddedInterpolant:CompVecValueMismatchErrId',i + 1, dims(i));
            else
                valid = valid && isvector(Xi);
                valid = valid && (dims(i) == numel(Xi));
            end
        end
    end

end
