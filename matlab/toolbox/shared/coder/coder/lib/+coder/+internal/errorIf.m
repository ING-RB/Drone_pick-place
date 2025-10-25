function errorIf(cond, msgID, varargin)
%MATLAB Code Generation Private Function

%   Copyright 2011-2019 The MathWorks, Inc.

%MATLAB execution

if cond
    try
        coder.internal.assert(false, msgID, varargin{:});
    catch ME
        ME.throwAsCaller();
    end
end
