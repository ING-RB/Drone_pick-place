function removeGroup(obj, varargin)
    results = matlab.settings.internal.parseGroupPropertyValues(varargin);
    % parseSettingPropertyValues function parses and validates user-input for optional property-value pairs with inputParser.
    obj.removeGroupHelper(results.Name);
end

%   Copyright 2015-2022 The MathWorks, Inc.

