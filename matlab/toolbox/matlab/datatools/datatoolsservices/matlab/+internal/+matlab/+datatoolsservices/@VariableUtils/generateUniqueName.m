% Generates a unique variable name from the given fields. If name 'x' already
% exists, it will return 'x1'. if varname is not a valid MATLAB name, then
% unique name will be generated on a valid MATLAB variable name. Varname can be
% a single string or it can be a string array. Takes in (x, {'x','y','z'}) and
% returns "x1" or Takes in ([x, y, x], {'x','y','z'}) and returns
% ["x1","y1","x2"].

% Copyright 2020-2022 The MathWorks, Inc.

function new = generateUniqueName(varName, variableNameList, prefixName)
    arguments
        varName string
        variableNameList
        prefixName = []
    end
    new = strings(1, length(varName));
    for i = 1:length(varName)
        name = varName(i);
        counter = 0;
        if ~isempty(prefixName)
            new_base =  matlab.lang.makeValidName(string(name), Prefix=prefixName);
        else
            new_base =  matlab.lang.makeValidName(string(name));
        end
        temp_new = new_base;
        while any(temp_new == variableNameList)
            counter = counter + 1;
            proposed_number_string = string(counter);
            temp_new = new_base + proposed_number_string;
        end
        variableNameList{end+1} = char(temp_new); %#ok<AGROW>
        new(i) = temp_new;
    end
end
