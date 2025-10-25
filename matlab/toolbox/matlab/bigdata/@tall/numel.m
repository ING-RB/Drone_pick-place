function out = numel(obj)
%NUMEL Number of elements in a tall array
%   N = NUMEL(A)
%
%   See also TALL/SIZE.

%   Copyright 2015-2019 The MathWorks, Inc.

% Make sure we return the actual answer if the size is known.
if obj.Adaptor.isSizeKnown
    out = tall.createGathered(prod(obj.Adaptor.Size), getExecutor(obj));
else
    out = aggregatefun(@numel, @sum, obj);
    out.Adaptor = matlab.bigdata.internal.adaptors.getScalarDoubleAdaptor();
end
end
