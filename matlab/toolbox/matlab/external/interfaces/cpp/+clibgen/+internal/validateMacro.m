function validateMacro(macroVal,isDefinedMacro)
% Validate defined or undefined macro names

%   Copyright 2024 The MathWorks, Inc.

% The name should have characters 1-9, a-z, A-Z and '_'
% and should not begin with a numeral
validateattributes(macroVal,{'string','char'},{'nonempty'});
macroStrings = string(macroVal);
for macro = macroStrings
    if(~isscalar(split(macro)))
        error(message('MATLAB:CPP:SpaceInMacro',macro));
    end
    macroName = split(macro,'=');
    macroName = macroName(1);
    if ~isDefinedMacro && ~(macro==macroName)
        % assignment not allowed for UndefinedMacros
        error(message('MATLAB:CPP:UndefineAssignmentNotAllowed',macroName));
    end    
    macroName=char(macroName);
    if(~isnan(str2double(macroName(1))))
        error(message('MATLAB:CPP:LeadingNumberInMacro',macroName));
    end
    for m = macroName
        % Check for allowed character (see comment above)
        if(~((m>64&&m<123) || (m=='_') || ~isnan(str2double(m))))
            error(message('MATLAB:CPP:InvalidCharacterInMacro', m, macroName));
        end
    end
    
end

end

