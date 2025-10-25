function out = isValidName(name, settingNodeType)
%isValidName Check whether given group/setting name is valid

%   Copyright 2018-2020 The MathWorks, Inc.

    out = ((ischar(name) && ~isempty(name)) || ...
        (isstring(name) && ~isempty(name) && ~ismissing(name) ...
        && ~isequal(name, ""))) && isvarname(name);
    
    if isequal(out, false)
        error(message(...
            'MATLAB:settings:config:NameMustBeValidMatlabIdentifier', ...
            settingNodeType));
    end
end

