function tX = validateNumColumns(tX, N, err)
%validateNumColumns Possibly deferred check for number of columns equal to N.
%   TX1 = validateNumColumns(TX,N,ERR) validates that TX has N columns. If
%   TX is not a does not have N columns, the specified error will be
%   thrown. ERR can be:
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A nullary function that will throw on call
%
%   Examples:
%   >> tX = tall(ones(2,3,4));
%   >> tX = tall.validateNumColumns(tX, 12, "bigdata:array:MustHave12Columns")

% Copyright 2017-2018 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(3, 3);
nargoutchk(1, 1);
assert(~istall(err), 'Assertion failed: validateNumColumns expects ERR not to be tall.');
errFcn = matlab.bigdata.internal.util.getErrorFunction(err);

try
    if istall(N)
        [isGathered, gatheredN] = matlab.bigdata.internal.util.isGathered(N);
        if isGathered
            N = gatheredN;
        end
    end
    N = tall.validateScalar(N, 'MATLAB:bigdata:array:ValidateNumColumnsBadN');
    
    adaptor = matlab.bigdata.internal.adaptors.getAdaptor(tX);
    if ~istall(N)
        if ~isnan(adaptor.NDims) && ~any(isnan(adaptor.SmallSizes))
            numColumns = prod(adaptor.SmallSizes);
            if numColumns ~= N
                errFcn();
            end
            return;
        end
    end
    
    tX = slicefun(@(x, n) iCheckNumColumns(x, n, errFcn), tX, N);
    tX.Adaptor = adaptor;
catch err
    throwAsCaller(err);
end
end

function x = iCheckNumColumns(x, expectedN, errorFcn)
% Check that x has the expected number of columns.
sz = size(x);
actualN = prod(sz(2 : end));
if ~isequal(actualN, expectedN)
    errorFcn();
end
end
