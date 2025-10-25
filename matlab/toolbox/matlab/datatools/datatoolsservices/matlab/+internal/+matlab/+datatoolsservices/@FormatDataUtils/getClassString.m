% Gets the formatted class name string

% Copyright 2015-2025 The MathWorks, Inc.

function clazz = getClassString(value, useShortClassName, useParens)
    arguments
        value
        useShortClassName = true;
        useParens = false;
    end

    try
        clazz = class(value);
        isNumericClass = false;
        try
            isNumericClass = isnumeric(value);
        catch
        end

        isLogicalClass = false;
        try
            isLogicalClass = islogical(value);
        catch
        end

        if ~(isNumericClass || isLogicalClass)
            if useShortClassName
                n = regexp(clazz,'^(?<clazz>[^\.]*)$|^.*\.(?<clazz>.*)?','names');
                if ~isempty(n.clazz)
                    clazz = n.clazz;
                end
            end
        else
            clazz = internal.matlab.datatoolsservices.FormatDataUtils.addComplexSparseToClass(...
                clazz, isreal(value), issparse(value), useParens);
        end
    catch
        % Show '' for classes which error for some reason, for example if a class definition is changed
        % and an error is inserted, while the class exists as a variable in the workspace.
        clazz = '';
    end
end
