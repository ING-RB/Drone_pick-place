function out = strcmpCommon(fcn, s1, s2, varargin)
%STRCMPCOMMON Common implementation details for STRCMP family.

%   Copyright 2015-2019 The MathWorks, Inc.

% Both inputs must be valid single strings or tall arrays of strings
fcnName = upper(func2str(fcn));
try
    s1 = validateAndMaybeWrap(s1, 1, fcnName);
    s2 = validateAndMaybeWrap(s2, 2, fcnName);
catch E
    throwAsCaller(E);
end
isABroadcast = matlab.bigdata.internal.util.isBroadcast(s1);
isBBroadcast = matlab.bigdata.internal.util.isBroadcast(s2);
out = elementfun(@(a,b,flagA,flagB) iCallFcn(fcn, a, b, flagA, flagB, varargin{:}), s1, s2, isABroadcast, isBBroadcast);
out = setKnownType(out, 'logical');
end


function str = validateAndMaybeWrap(str, argIdx, fcn)
% Check a string input to make sure it is valid for STRCMP-style functions.
%
% Tall arrays must satisfy isValidStringArray
% Non-tall must satisfy isValidString and char arrays will be converted to strings.

if istall(str)
    % Tall inputs must be arrays of strings - no char arrays allowed
    str = tall.validateType(str, fcn, {'string', 'cellstr'}, argIdx);
else
    % Non-tall must first be validString...
    if ~isValidString(str)
        error(message('MATLAB:bigdata:array:InvalidStringInput', fcn));
    end
    
    % ... and char inputs must be row vectors (or '')
    if ischar(str)
        if ~isequal(str, '') && ~isrow(str)
            error(message('MATLAB:bigdata:array:CharArrayNotRow', fcn));
        end
        % We must treat char arrays as a single string, so wrap it
        str = string(str);
    end
end
end


function out = iCallFcn(fcn, a, b, isABroadcast, isBBroadcast, varargin)
% Check if the inputs are compatible and call fcn.
% Tall array inputs must have the same size or at least one of them must be
% a scalar. Here, we can identify tall scalars as broadcast scalars. Thus,
% A or B can be broadcast scalars. If none of them is a broadcast scalar,
% sizes of A and B must match.

isABroadcastScalar = isABroadcast && isscalar(a);
isBBroadcastScalar = isBBroadcast && isscalar(b);
sameSize = ndims(a) == ndims(b) && all(size(a) == size(b));

if ~isABroadcastScalar && ~isBBroadcastScalar && ~sameSize
    error(message('MATLAB:strcmp:InputsSizeMismatch'));
end

out = fcn(a, b, varargin{:});
end
