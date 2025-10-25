function N = numel_colonvector(val)
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.

% Copyright 2024 The MathWorks, Inc.

% N = numel_colonvector(A,[S,]D) returns the number of elements in an array formed from A:[S:]D
% without forming A:[S:]D.

arguments (Repeating)
    % Use this to coerce already-validated arguments to builtin doubles.
    val (1,1) double
end

colonDesc = matlab.internal.ColonDescriptor(val{:});
N = colonDesc.numel();
end
