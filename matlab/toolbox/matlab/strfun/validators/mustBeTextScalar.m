function mustBeTextScalar(text)
%
    
% Copyright 2020-2023 The MathWorks, Inc.

    if ~isCharRowVector(text) && ~(isstring(text) && isscalar(text))
        throwAsCaller(MException(message("MATLAB:validators:mustBeTextScalar")))
    end

end
