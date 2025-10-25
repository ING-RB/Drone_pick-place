% Get the variable name to use for the copy.  Given a variable name of 'x', it
% will return 'xCopy'.  If 'xCopy' already exists, it will append _<number> to
% find a unique variable name.  In addition, this function assures that the
% return variable name will not exceed namelengthmax.  The data type returned
% will be the same as varname (char or string)

% Copyright 2020-2022 The MathWorks, Inc.

function new = getVarNameForCopy(varname, fields)
    if iscell(varname)
        varname = varname{1};
    end
    counter = 0;
    if strlength(varname) + 4 > namelengthmax
        varname = extractBefore(varname, namelengthmax-4+1);
    end
    new_base = strcat(varname, 'Copy');
    new = new_base;
    while localAlreadyExists(new , fields)
        counter = counter + 1;
        proposed_number_string = num2str(counter);
        new = strcat(new_base, proposed_number_string);
        if strlength(new) > namelengthmax
            new = strcat(extractBefore(varname, namelengthmax - 4 - strlength(proposed_number_string) + 1), ...
                'Copy', proposed_number_string);
        end
    end
end

function result = localAlreadyExists(name, who_output)
    result = false;
    idx = 1;
    while ~result && idx <= length(who_output)
        result = strcmp(name, who_output{idx});
        idx = idx + 1;
    end
end
