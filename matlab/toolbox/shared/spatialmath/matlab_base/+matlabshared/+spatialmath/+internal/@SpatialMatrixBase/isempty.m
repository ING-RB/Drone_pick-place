function tf = isempty(obj)
%ISEMPTY True if input is an empty array
%   ISEMPTY(X) returns 1 if X is an empty array and 0 otherwise. An
%   empty array has no elements, that is prod(size(X))==0.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    tf = isempty(obj.MInd);

end
