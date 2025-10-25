function mustBeVector(input)
% mustBeVector is for internal use only and may be removed or
% modified at any time

% mustBeVector works with numeric data and checks if the input numeric data is a 
% row or column vector. An error is issued if the input is not a vector.
% Empty values are permitted.

%   Copyright 2019-2022 The MathWorks, Inc.
    if ~isempty(input) && ~(isrow(input) || iscolumn(input))
        throwAsCaller(MException(message('MATLAB:class:RequireVector')));
    end
end
