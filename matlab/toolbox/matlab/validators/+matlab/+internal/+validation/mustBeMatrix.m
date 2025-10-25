function mustBeMatrix(input)
% mustBeMatrix is for internal use only and may be removed or
% modified at any time

% mustBeMatrix works with numeric data checks if it is a matrix. An error
% is issued if the input is not a matrix.

%   Copyright 2019-2020 The MathWorks, Inc.
    if ~ismatrix(input)
        throwAsCaller(MException('MATLAB:class:RequireMatrix','%s',message('MATLAB:class:RequireMatrix').getString));
    end
end
