function tX = validateColumn(tX, err)
%validateType Possibly deferred check for column attribute
%   TX1 = validateColumn(TX,ERR) validates that TX is a column. If TX is
%   not a column, the specified error will be thrown. ERR can be:
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A nullary function that will throw on call

% Copyright 2017-2018 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(2, 2);
assert(~istall(err), 'Assertion failed: validateColumn expects ERR not to be tall.');
assert(nargout >= 1, 'Assertion failed: validateColumn expects output to be captured.');
errFcn = matlab.bigdata.internal.util.getErrorFunction(err);

try
    adaptor = matlab.bigdata.internal.adaptors.getAdaptor(tX);
    if adaptor.isKnownNotColumn()
         errFcn();
    end
    if ~adaptor.isKnownColumn()
        % Must be a tall array to reach here.
        tX = lazyValidate(tX, {@iscolumn, errFcn});
        tX.Adaptor = setSmallSizes(adaptor, 1);
    end
catch err
    throwAsCaller(err);
end
