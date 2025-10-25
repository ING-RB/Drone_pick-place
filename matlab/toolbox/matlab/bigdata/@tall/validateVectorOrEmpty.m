function tX = validateVectorOrEmpty(tX, err)
%validateVectorOrEmpty Possibly deferred check for vector or empty attribute
%   TX = validateVectorOrEmpty(TX,ERR) validates that TX is a vector. If TX
%   is not a vector and not empty, the specified error will be thrown. ERR
%   can be:
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A nullary function that will throw on call
%
%   This requires a full pass of TX.

% Copyright 2017-2018 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(2, 2);
assert(~istall(err), 'Assertion failed: validateVectorOrEmpty expects ERR not to be tall.');
assert(nargout >= 1, 'Assertion failed: validateVectorOrEmpty expects output to be captured.');
errFcn = matlab.bigdata.internal.util.getErrorFunction(err);

try
    adaptor = matlab.bigdata.internal.adaptors.getAdaptor(tX);
    if ~istall(tX)
        adaptor = setTallSize(adaptor, size(tX, 1));
    end
    if adaptor.isKnownNotVector() && adaptor.isKnownNotEmpty()
         errFcn();
    end
    if adaptor.isKnownVector() || adaptor.isKnownEmpty()
        return;
    end
    
    % Must be a tall array to reach here.
    tSz = partitionfun(@(info, x) iValidatePartition(info, x, errFcn), tX);
    tSz = reducefun(@(sz) iValidateBetweenPartition(sz, errFcn), tSz);
    % The framework will assume tSz is partition dependent because it is
    % derived from partitionfun. It is not, so we must correct this.
    tSz = copyPartitionIndependence(tSz, tX);
    tX = slicefun(@(x, ~) x, tX, tSz);
    tX.Adaptor = adaptor;
catch err
    throwAsCaller(err);
end

function [isFinished, sz] = iValidatePartition(info, x, errFcn)
% Validate that a partition is a row or column or empty. The output is the
% size of the partition if it is a row or empty. This will also exit early
% if the array is a column or empty in a small dim.
isFinished = info.IsLastChunk;
sz = size(x);
if iscolumn(x) || any(sz(2 : end) == 0)
    isFinished = true;
    return;
end

if ~ismatrix(x) || sz(1) + info.RelativeIndexInPartition - 1 > 1
    errFcn();
end

function sz = iValidateBetweenPartition(sz, errFcn)
% Validate that the size between partitions indicate a row or column or
% empty. Empties include N-D empties.
sz = [sum(sz(:, 1)), sz(1, 2 : end)];
if (numel(sz) == 2 && sz(2) == 1) || any(sz(2 : end) == 0)
    return;
end

if (sz(1) > 1)
    errFcn();
end
