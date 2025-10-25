function setenv(names, values)
narginchk(1, 2);
dInput = false;
if nargin == 1
    dict = names;
    if isa(dict, "dictionary")
        % Builtin uses dInput to throw dictionary-specific errors.
        dInput = true;
        if ~isConfigured(dict)
            return
        end
        names = dict.keys;
        values = dict.values;
    else
        % On Windows, setenv(names) unsets the listed environment
        % variables. On all other platforms, setenv(names) sets the
        % listed environment variables to "".
        values = "";
    end
end

names = convertCharsToStrings(names);
values = convertCharsToStrings(values);

if isempty(names) 
    return
end

if isa(values, "missing")
    values = string(missing);
end

try
    matlab.oss.internal.setenv(names, values, dInput);
catch ME
    throw(ME)
end
end

%   Copyright 2022 The MathWorks, Inc.
