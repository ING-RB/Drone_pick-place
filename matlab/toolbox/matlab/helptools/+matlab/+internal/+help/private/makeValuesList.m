function valuesList = makeValuesList(argument, prefix)
    arguments
        argument (1,1);
        prefix   (1,1) string = "";
    end
    values = argument.Values;
    if isprop(argument, 'DefaultValue')
        defaultIndex = values==argument.DefaultValue;
        values(defaultIndex) = values(defaultIndex) + " " + getString(message('MATLAB:introspective:helpParts:Default'));
    end
    valuesList = joinWithSpacesOrWrap(values, " |", prefix=prefix);
end

%   Copyright 2021-2022 The MathWorks, Inc.
