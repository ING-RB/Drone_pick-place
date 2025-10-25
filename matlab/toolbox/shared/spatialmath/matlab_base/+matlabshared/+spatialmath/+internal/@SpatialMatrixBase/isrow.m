function tf = isrow(obj)
%ISROW True if input is a row vector
%   ISROW(V) returns logical 1 (true) if V is a 1-by-n vector, and
%   logical 0 (false) otherwise.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    tf = isrow(obj.MInd);

end
