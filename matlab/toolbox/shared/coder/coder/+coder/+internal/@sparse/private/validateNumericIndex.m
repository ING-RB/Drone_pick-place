function validateNumericIndex(lowBound,upperBound,idx)
%MATLAB Code Generation Private Function

% Helper for indexing. Perform bounds check.

%   Copyright 2016-2018 The MathWorks, Inc.
%#codegen
coder.internal.assert(isreal(idx), 'Coder:MATLAB:badsubscript');
for k = 1:numel(idx)
    idxk = idx(k);
    coder.internal.assert(floor(idxk) == idxk && ~isinf(idxk) && idxk > 0, 'Coder:MATLAB:badsubscript');
    coder.internal.assert(idxk <= upperBound, 'Coder:builtins:IndexOutOfBounds', ...
                          idxk, lowBound, upperBound);
end

%--------------------------------------------------------------------------
