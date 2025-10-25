function tX = validateRow(tX, err)
%validateType Possibly deferred check for row attribute
%   TX = validateRow(TX,ERR) validates that TX is a row. If TX is not a
%   row, the specified error will be thrown. ERR can be: 
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A nullary function that will throw on call
%
% The output TX can be used in a height singleton expanded operation, even
% if the input could not.

% Copyright 2017-2018 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(2, 2);
assert(~istall(err), 'Assertion failed: validateRow expects ERR not to be tall.');
assert(nargout >= 1, 'Assertion failed: validateRow expects output to be captured.');
errFcn = matlab.bigdata.internal.util.getErrorFunction(err);

try
    adaptor = matlab.bigdata.internal.adaptors.getAdaptor(tX);
    if ~istall(tX)
        adaptor = setTallSize(adaptor, size(tX, 1));
    end
    if adaptor.isKnownNotRow()
         errFcn();
    end
    if ~adaptor.isKnownRow() || ~matlab.bigdata.internal.util.isBroadcast(tX)
        % Must be a tall array to reach here. We explicitly reduce tX here
        % because that allows tX to be singleton expanded in the first
        % dimension for future operations. We could use clientfun for the
        % same effect, but this version also guards against out-of-memory
        % if tX is truly tall.
        tX = reducefun(@(x) iThrowIfNotRow(x, true, errFcn), tX);
        tX.Adaptor = adaptor;
        tX = clientfun(@(x) iThrowIfNotRow(x, false, errFcn), tX);
        tX.Adaptor = setTallSize(resetTallSize(adaptor), 1);
    end
catch err
    throwAsCaller(err);
end

function x = iThrowIfNotRow(x, allowEmpty, errFcn)
% Reduction function that asserts the given data is a single row.
height = size(x, 1);
if ~ismatrix(x) || (height > 1) || (~allowEmpty && (height == 0))
    errFcn();
end
