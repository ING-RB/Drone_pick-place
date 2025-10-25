function tX = validateNotEmpty(tX, err)
%validateNotEmpty Possibly deferred check for ~isempty attribute
%   TX = validateNotEmpty(TX,ERR) validates that TX is not an empty array 
%   or table. If TX is empty, the specified error will be thrown. ERR can 
%   be:
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A nullary function that will throw on call
%

% Copyright 2020 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(2, 2);
assert(~istall(err), 'Assertion failed: validateNotEmpty expects ERR not to be tall.');
assert(nargout >= 1, 'Assertion failed: validateNotEmpty expects output to be captured.');
errFcn = matlab.bigdata.internal.util.getErrorFunction(err);

try
    adaptor = matlab.bigdata.internal.adaptors.getAdaptor(tX);
    if ~istall(tX)
        adaptor = setTallSize(adaptor, size(tX, 1));
    end
    if adaptor.isKnownEmpty()
         errFcn();
    end
    if ~adaptor.isKnownNotEmpty()
        % Must be a tall array to reach here.
        sz = size(head(tX, 1));
        tX = slicefun(@(x, s) iThrowIfNotEmpty(x, s, errFcn), tX, sz);
        tX.Adaptor = adaptor;
    end
catch err
    throwAsCaller(err);
end

function x = iThrowIfNotEmpty(x, sz, errFcn)
% Throw if the size input argument indicates the tall input is a scalar.
if prod(sz)==0
    errFcn();
end
