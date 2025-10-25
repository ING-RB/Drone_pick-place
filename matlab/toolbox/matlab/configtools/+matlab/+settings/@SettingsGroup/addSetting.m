function out = addSetting(obj,varargin)
    [results, defaultsUsed] = matlab.settings.internal.parseSettingPropertyValues(varargin);
    % parseSettingPropertyValues function parses and validates user-input for optional property-value pairs with inputParser.
    out = obj.addSettingHelper(results,defaultsUsed);
end

%   Copyright 2015-2022 The MathWorks, Inc.
