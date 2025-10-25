function tX = validateMatrix(tX, err)
%validateType Possibly deferred check for matrix attribute
%   TX1 = validateMatrix(TX,ERR) validates that TX is a matrix. If TX is
%   not a matrix, the specified error will be thrown. ERR can be:
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A nullary function that will throw on call

% Copyright 2017-2018 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(2, 2);
assert(~istall(err), 'Assertion failed: validateMatrix expects ERR not to be tall.');
assert(nargout >= 1, 'Assertion failed: validateMatrix expects output to be captured.');
errFcn = matlab.bigdata.internal.util.getErrorFunction(err);

try
    adaptor = matlab.bigdata.internal.adaptors.getAdaptor(tX);
    if adaptor.isKnownNotMatrix()
         errFcn();
    end
    if ~adaptor.isKnownMatrix()
        % Must be a tall array to reach here.
        tX = lazyValidate(tX, {@ismatrix, errFcn});
        tX.Adaptor = setSmallSizes(adaptor, NaN);
    end
catch err
    throwAsCaller(err);
end
