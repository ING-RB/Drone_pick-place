function tX = validateVertcatConsistent(tX, err)
%validateVertcatConsistent Deferred check that a tall array is vertcat consistent
%   TX1 = validateVertcatConsistent(TX,ERR) validates that TX is vertcat
%   consistent. That all blocks can be vertically concatenated with other
%   blocks. If not, the specified error will be thrown. ERR can be:
%     * A fully constructed error message, e.g. message(ERRID,ARG1,...)
%     * An error ID string "ERRID"
%     * A cell array of arguments to pass to message {"ERRID", ARG1, ...}
%     * A binary function that will throw on call. This function will
%     receive an adaptor representing previous blocks as well as an adaptor
%     for the mismatched block.

% Copyright 2018-2024 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

narginchk(2, 2);
assert(~istall(err), 'Assertion failed: validateVertcatConsistent expects ERR not to be tall.');
assert(nargout >= 1, 'Assertion failed: validateVertcatConsistent expects output to be captured.');
errFcn = matlab.bigdata.internal.util.getErrorFunction(err);

if ~istall(tX)
    return;
end

% This is done as a chunkfun instead of elementfun as certain elementfun
% optimizations are conflicting with statefulness.
fh = @(state, x) iValidateVertcatConsistent(state, x, errFcn);
fh = matlab.bigdata.internal.util.StatefulFunction(fh, ...
    matlab.bigdata.internal.UnknownEmptyArray.build());
fh = matlab.bigdata.internal.FunctionHandle(fh);
adaptor = matlab.bigdata.internal.adaptors.getAdaptor(tX);
tX = chunkfun(fh, tX);
tX.Adaptor = adaptor;
end

function [state, x] = iValidateVertcatConsistent(state, x, errFcn)
% Validate that blocks can be vertically concatenated with everything
% that has come before in the same partition.
%
% This works by capturing a slice of previous data to compare the current
% block against. This has to be a slice and not an empty, as various
% concatenation (including string) doesn't error for empties of mismatching
% size.
flatX = x;
if size(flatX, 1) > 1
    flatX = matlab.bigdata.internal.util.indexSlices(flatX, 1);
end
try
    % State is initialized at the beginning to UnknownEmptyArray. This will
    % effectively be "state = flatX" for the very first block of each
    % partition. This must use cat instead of vertcat as vertcat allows
    % concateniation of empties with incompatible sizes.
    state = cat(1, state, flatX);
catch
    feval(errFcn, ...
        resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(state)), ...
        resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(flatX)));
end
if size(state, 1) > 1
    state = matlab.bigdata.internal.util.indexSlices(state, 1);
end
end
