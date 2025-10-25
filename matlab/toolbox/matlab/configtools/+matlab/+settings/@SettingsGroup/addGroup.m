function out = addGroup(obj, varargin)
    [results, defaultsUsed] = matlab.settings.internal.parseGroupPropertyValues(varargin);
    % parseGroupPropertyValues function parses and validates user-input for optional property-value pairs with inputParser.
    out = obj.addGroupHelper(results,defaultsUsed);    
end

%   Copyright 2015-2022 The MathWorks, Inc.
