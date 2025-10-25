function N = numelindex(I)
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.

% Copyright 2019 The MathWorks, Inc.

% N = numelindex(A) returns the number of elements in an array formed from A(I).

if islogical(I)
    N = nnz(I);
else
    N = numel(I);
end

end