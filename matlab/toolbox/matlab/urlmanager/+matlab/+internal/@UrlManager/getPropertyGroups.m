function groups = getPropertyGroups(obj)
%

%   Copyright 2020 The MathWorks, Inc.

if ~isscalar(obj)
    groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
else
    groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
    groups.Title = 'Endpoints';
    groups.PropertyList = rmfield(groups.PropertyList, 'Environment');
end
end
