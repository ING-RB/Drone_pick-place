function tf = ismatrix(obj)
%ISMATRIX True if input is a matrix
%   ISMATRIX(M) returns logical 1 (true) if SIZE(M) returns [m n]
%   with nonnegative integer values m and n, and logical 0 (false) otherwise.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    tf = ismatrix(obj.MInd);

end
