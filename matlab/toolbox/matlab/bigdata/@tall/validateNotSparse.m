function tX = validateNotSparse(tX, err)
%validateNotSparse Possibly deferred check that input is not sparse.
%   TX1 = validateNotSparse(TX,ERR) validates that TX is not a sparse
%   matrix. TX can be a tall array or in-memory array. The check is
%   performed immediately where possible. ERR can be:
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A nullary function that will throw on call

% Copyright 2019 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(2, 2);
assert(~istall(err), 'Assertion failed: validateNotSparse expects ERR not to be tall.');
assert(nargout >= 1, 'Assertion failed: validateNotSparse expects output to be captured.');
errFcn = matlab.bigdata.internal.util.getErrorFunction(err);

try
    % At the moment tall arrays cannot be sparse so just check if in-memory.
    if ~istall(tX) && issparse(tX)
        errFcn();
    end
catch err
    throwAsCaller(err);
end
