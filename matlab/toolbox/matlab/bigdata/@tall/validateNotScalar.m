function tX = validateNotScalar(tX, err)
%validateNotScalar Possibly deferred check for ~isscalar attribute
%   TX = validateNotScalar(TX,ERR) validates that TX is not a scalar. If TX
%   is a scalar, the specified error will be thrown. ERR can be:
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A nullary function that will throw on call
%

% Copyright 2017-2018 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(2, 2);
assert(~istall(err), 'Assertion failed: validateNotScalar expects ERR not to be tall.');
assert(nargout >= 1, 'Assertion failed: validateNotScalar expects output to be captured.');
errFcn = matlab.bigdata.internal.util.getErrorFunction(err);

try
    adaptor = matlab.bigdata.internal.adaptors.getAdaptor(tX);
    if ~istall(tX)
        adaptor = setTallSize(adaptor, size(tX, 1));
    end
    if adaptor.isKnownScalar()
         errFcn();
    end
    if ~adaptor.isKnownNotScalar()
        % Must be a tall array to reach here.
        sz = size(head(tX, 2));
        tX = slicefun(@(x, s) iThrowIfNotScalar(x, s, errFcn), tX, sz);
        tX.Adaptor = adaptor;
    end
catch err
    throwAsCaller(err);
end

function x = iThrowIfNotScalar(x, sz, errFcn)
% Throw if the size input argument indicates the tall input is a scalar.
if isequal(sz, [1,1])
    errFcn();
end
