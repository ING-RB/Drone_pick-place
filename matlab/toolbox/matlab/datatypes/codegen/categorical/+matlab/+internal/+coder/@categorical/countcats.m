function c = countcats(a,dim) %#codegen
%COUNTCATS Count occurrences of categories in a categorical array's elements.

%   Copyright 2020 The MathWorks, Inc. 

if nargin < 2
    % Error here instead of the call to histc when DIM is selected
    % automatically, is variable-length, and has length 1 at run time.
    dim = coder.internal.constNonSingletonDim(a.codes);
    coder.internal.assert( ...
        ( coder.internal.isConst(size(a,dim)) || ...
          isscalar(a) || ...
          size(a,dim) ~= 1 ), ...
        'MATLAB:categorical:countcats:DimArgRequired');
    
    c = histc(a.codes,1:length(a.categoryNames)); %#ok<*HISTC>
else
    c = histc(a.codes,1:length(a.categoryNames),dim);
end
