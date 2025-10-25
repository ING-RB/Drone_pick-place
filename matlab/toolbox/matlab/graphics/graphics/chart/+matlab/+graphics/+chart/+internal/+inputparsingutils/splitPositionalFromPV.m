function [posargs, pvpairs] = splitPositionalFromPV(args, numRequired, hasOptional)
% This function is undocumented and may change in a future release.

%   Copyright 2021 The MathWorks, Inc.

% [posargs, pvpairs] = SPLITPOSITIONALFROMPV(args, numRequired, hasOptional)
%   splits positional arguments from name-value pairs. This tool is intended 
%   for use in cases where there can be only n or n+1 positional arguments, 
%   and so the number of positional arguments can be determined based purely 
%   on whether the number of arguments is odd or even.
%
%   args should be specified as a cell and posargs/pvpairs are both
%   returned as cells. Exceptions are thrown if there are not enough args
%   or hasOptional is false and an even number of args does not remain
%   after removing positional args.
%
%   After splitting, the property in each PV pair is checked to make sure
%   that they are all char or string.

arguments
    args cell
    numRequired (1,1) double
    hasOptional (1,1) logical = false
end

nargs = numel(args);
if nargs < numRequired
    throwAsCaller(MException(message('MATLAB:narginchk:notEnoughInputs')))
end

nposargs = numRequired;
if mod(nargs,2) ~= mod(numRequired,2)
    if hasOptional
        nposargs = nposargs + 1;
    else
        throwAsCaller(MException(message('MATLAB:checkpvpairs:EvenPropValuePairs')));
    end
end

posargs = args(1:nposargs);
pvpairs = args(nposargs + 1:end);

for i = 1:2:numel(pvpairs)
    if ~matlab.graphics.internal.isCharOrString(pvpairs{i})
        throwAsCaller(MException(message('MATLAB:class:BadParamValuePairs')));
    end
end
