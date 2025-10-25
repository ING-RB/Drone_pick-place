function tX = validateTallSizeGtOne(tX, err)
%validateTallSizeGtOne Possibly deferred check for that size(t,1)>1
%   TX = validateTallSizeGtOne(TX,ERR) validates that TX has height of more than 1. If TX has height 0 or 1
%   the specified error will be thrown. ERR
%   can be:
%     * A fully constructed error nessage, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A nullary function that will throw on call
%
%   This may require a full pass of TX.

% Copyright 2018 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(2, 2);
assert(~istall(err), 'Assertion failed: validateTallSizeGtOne expects ERR not to be tall.');
assert(nargout >= 1, 'Assertion failed: validateTallSizeGtOne expects output to be captured.');
errorFcn = matlab.bigdata.internal.util.getErrorFunction(err);

try
    adaptor = matlab.bigdata.internal.adaptors.getAdaptor(tX);
    % Early out if we know it's OK.
    if adaptor.isTallSizeGuaranteedNonZero() && adaptor.isTallSizeGuaranteedNonUnity()
        return;
    end
    % Early error if we know the tall size and it is 1 or 0.
    if ~isempty(adaptor.TallSize.Size) && adaptor.TallSize.Size <= 1
        errorFcn();
    end    
    % Size is unknown and will need a lazy check (must be a tall array to
    % get here). 
    tX = tall.validateTrue(tX, size(tX,1)>1, errorFcn);
catch err
    throwAsCaller(err);
end

end
