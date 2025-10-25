% Return the footer display string for matlab.mpm.Package

%   Copyright 2024 The MathWorks, Inc.
function ret = getFooter(obj, varName)
    if nargin < 2
        varName = '';
    end
    ret = getFooter@matlab.mixin.CustomDisplay(obj);
    if isempty(varName)
        return;
    end

    if ~isscalar(obj)
        methodToCall = "matlab.mpm.internal.displayPackagesAsTable";
        text = 'Display as table';
        arg = varName;
    else
        methodToCall = "help";
        text = "help " + obj.Name ;        
        arg = strcat('''',  convertStringsToChars(obj.Name), '''');
    end 

    cmd = sprintf('  <a href="%s">%s\n</a>', ...
     "matlab: try, " + methodToCall + "(" + arg + "); end", ...
    text);

    ret = [ret, cmd];
end

