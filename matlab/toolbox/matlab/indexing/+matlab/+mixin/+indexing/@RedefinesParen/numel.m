%NUMEL  Number of elements
%   NUMEL(obj) returns prod(size(obj)).

%   Copyright 2020-2021 The MathWorks, Inc.

function n = numel(obj)
    n = prod(size(obj)); %#ok<PSIZE>
end
