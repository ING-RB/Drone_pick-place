%ISEMPTY  True for empty object
%   ISEMPTY(obj) returns true if obj is empty and false otherwise.

%   Copyright 2020-2021 The MathWorks, Inc.

function TF = isempty(obj)
    TF = any(size(obj) == 0);
end
