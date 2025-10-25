%LENGTH  Length of vector
%   LENGTH(obj) returns max(size(obj)) for non-empty arrays and 0 for
%   empty arrays.

%   Copyright 2020-2021 The MathWorks, Inc.

function L = length(obj)
    if isempty(obj)
        L = 0;
    else
        L = max(size(obj));
    end
end
