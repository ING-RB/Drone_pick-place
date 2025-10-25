% Returns true for containertypes that can hold heterogeneous data and false for
% homogeneous datatypes.

% Copyright 2020-2022 The MathWorks, Inc.

function isOfType = isContainerType(data)
    isOfType = istabular(data) || ...
        (iscell(data) && ~iscellstr(data)) || (isstruct(data) && ~isscalar(data) && (size(data,1)==1 || size(data,2)==1)); %#ok<ISCLSTR>
end