function tf = iscolumn(obj)
%ISCOLUMN True if input is a column vector
%   ISCOLUMN(V) returns logical 1 (true) if V is an n-by-1 vector, and
%   logical 0 (false) otherwise.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    tf = iscolumn(obj.MInd);

end
