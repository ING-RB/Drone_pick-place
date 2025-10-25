function out = length(x)
%LENGTH Length of vector.
%
%   See also tall/size, tall.

% Copyright 2016-2019 The MathWorks, Inc.

% table explicitly forbids access to LENGTH, and throws a specific error.
if any(strcmp(tall.getClass(x), {'table', 'timetable'}))
    error(message('MATLAB:table:UndefinedLengthFunction', tall.getClass(x)));
end

% Make sure we return a known answer if all sizes are known or we already
% know it is empty or scalar.
if x.Adaptor.isSizeKnown
    out = tall.createGathered(iLength(x.Adaptor.Size), getExecutor(x));
elseif x.Adaptor.isKnownEmpty
    out = tall.createGathered(0, getExecutor(x));
else
    % We need to wait until we know the sizes. Use deferred client-side op.
    out = clientfun(@iLength, size(x));
    % Output is guaranteed scalar-double.
    out.Adaptor = matlab.bigdata.internal.adaptors.getScalarDoubleAdaptor();
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LENGTH picks the max out of the size vector, unless the array is empty.
function len = iLength(szVec)
if prod(szVec) == 0
    len = 0;
else
    len = max(szVec);
end
end
