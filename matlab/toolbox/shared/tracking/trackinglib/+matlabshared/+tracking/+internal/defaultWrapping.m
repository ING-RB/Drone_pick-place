function wrapping = defaultWrapping(numElements,classToUse)
% This is an internal function and may be modified or removed in a future
% release.

%defaultWrapping Default measurement wrapping
% wrapping = matlabshared.tracking.internal.defaultWrapping(N,CLASS)
% returns the default residual wrapping. N is the number of elements in the
% residual and CLASS is either 'double' or 'single'.

% Copyright 2021 The MathWorks, Inc.
%#codegen

thisInf = Inf(1,1,classToUse);
wrapping = repmat([-thisInf thisInf], numElements, 1);