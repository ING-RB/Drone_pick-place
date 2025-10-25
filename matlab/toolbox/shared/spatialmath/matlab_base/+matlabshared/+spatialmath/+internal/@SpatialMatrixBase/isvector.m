function tf = isvector(obj)
%ISVECTOR True if input is a vector
%   ISVECTOR(V) returns logical 1 (true) if SIZE(V) returns [1 n] or [n 1]
%   with a nonnegative integer value n, and logical 0 (false) otherwise.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    tf = isvector(obj.MInd);
end
