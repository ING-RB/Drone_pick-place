function is = isempty(tv)
%ISEMPTY True for empty array.
%   ISEMPTY(tv) returns 1 if tv is an empty tall array and 0 otherwise. An
%   empty tall array has no elements, that is prod(size(X))==0.

% Copyright 2016-2023 The MathWorks, Inc.

if tv.Adaptor().isKnownEmpty()
    is = tall.createGathered(true, getExecutor(tv));
    
elseif tv.Adaptor().isKnownNotEmpty()
    is = tall.createGathered(false, getExecutor(tv));
    
else
    % We don't know either way. Use HEAD to get 0 or 1 rows since HEAD
    % knows how to abort as soon as it has the data it needs.
    tmp = head(tv,1);
    is = clientfun(@isempty, tmp);
    is.Adaptor = matlab.bigdata.internal.adaptors.getScalarLogicalAdaptor();
end
end
