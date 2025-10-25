function [needsBanner, entityType] = entityTypeNeedsBanner(refItem)
    [isMATLABItem, entityType] = matlab.lang.internal.introspective.isMATLABItem(refItem);
    needsBanner = ~isMATLABItem && entityType ~= "Unknown";
end

%   Copyright 2024 The MathWorks, Inc.
