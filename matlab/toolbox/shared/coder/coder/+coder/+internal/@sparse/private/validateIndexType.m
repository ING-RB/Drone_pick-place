function validateIndexType(idx)
%MATLAB Code Generation Private Function

% Helper for sparse indexing. Validate type and value of index.

%   Copyright 2016-2018 The MathWorks, Inc.
%#codegen
coder.internal.allowHalfInputs;
coder.internal.assert(coder.internal.isBuiltInNumeric(idx) || ...
                      (ischar(idx) && strcmp(idx,':')), ...
                      'Coder:builtins:IndexNonNumeric', ...
                      class(idx));

% If the index is sparse, make sure it doesn't have any zeros
coder.internal.errorIf(issparse(idx) && ...
                       ~allNonzero(idx), ...
                       'Coder:MATLAB:badsubscript');
