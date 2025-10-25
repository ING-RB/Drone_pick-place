function tX = validateScalar(tX, err)
%validateType Possibly deferred check for scalar attribute
%   TX = validateScalar(TX,ERR) validates that TX is a scalar. If TX is not
%   a scalar, the specified error will be thrown. ERR can be: 
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A nullary function that will throw on call
%
% The output TX can be used in a scalar expanded operation, even if the
% input could not.

% Copyright 2017-2018 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(2, 2);
assert(~istall(err), 'Assertion failed: validateScalar expects ERR not to be tall.');
assert(nargout >= 1, 'Assertion failed: validateScalar expects output to be captured.');
errFcn = matlab.bigdata.internal.util.getErrorFunction(err);

try
    tX = tall.validateColumn(tX, errFcn);
    tX = tall.validateRow(tX, errFcn);
catch err
    throwAsCaller(err);
end
