% Returns the display edit value for given data.  For example: dataValue = 1/3:
% '0.333333333333333' dataValue = [1/3, pi]:
% '[0.333333333333333,3.141592653589793]' dataValue = "test":  'test'

% Copyright 2015-2023 The MathWorks, Inc.

function editValue = getDisplayEditValue(dataValue, format)
    arguments
        dataValue
        format = 'long'
    end

    if ischar(dataValue) && size(dataValue, 1) == 1
        editValue = ['''' dataValue ''''];
        return;
    end

    % Capture the class before scaling down to raw numeric value
    classVal = class(dataValue);
    dataValue = internal.matlab.datatoolsservices.FormatDataUtils.getNumericValue(dataValue);

    if ~isscalar(dataValue)
        if iscell(dataValue)
            editValue = '{';
        else
            editValue = '[';
        end
    else
        editValue = '';
    end

    % Loop through all the cells and get the disp values
    for drow=1:size(dataValue, 1)
        if drow > 1
            editValue = [editValue ';']; %#ok<*AGROW>
        end
        for dcol=1:size(dataValue, 2)
            if dcol > 1
                editValue = [editValue ','];
            end

            if iscell(dataValue) && isempty(dataValue{drow, dcol})
                editValue = [editValue ''''''];
            elseif isa(dataValue, 'function_handle')
                editValue = char(dataValue);
                if ~isempty(editValue) && ~startsWith(editValue, "@")
                    editValue = ['@' editValue];
                end
            else
                if iscell(dataValue(drow, dcol))
                    editValue = [editValue char(strtrim(matlab.display.internal.obsoleteCellDisp(dataValue(drow,dcol))))];
                elseif isnumeric(dataValue)
                    editValue = [editValue char(matlab.internal.display.numericDisplay(dataValue(drow,dcol), 'Format', format))];
                else
                    editValue = [editValue strtrim(evalc('disp(dataValue(drow,dcol))'))];
                end
            end
        end
    end
    if ~isscalar(dataValue)
        if iscell(dataValue)
            editValue = [editValue '}'];
        else
            editValue = [editValue ']'];
        end
    end

    % Non-double numerics should need to have their constructor put in so that
    % if the user edits the value can remains the same type
    if isnumeric(dataValue) && ~strcmp(classVal, 'double') %#ok<STISA>  We want to do a string comparison because the original class is altered
        editValue = [classVal '(' editValue ')'];
    end
end
