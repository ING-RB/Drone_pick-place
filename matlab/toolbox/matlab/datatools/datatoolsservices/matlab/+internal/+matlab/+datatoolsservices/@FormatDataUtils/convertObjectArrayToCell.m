% the behaviour of vector object arrays in the variable editor is similar to
% cell arrays. if the value of a property in a vector object consists of the
% following use cases (see below)

% Copyright 2015-2023 The MathWorks, Inc.

function objDataAsCell = convertObjectArrayToCell(objArray, props)
    arguments
        objArray
        props = properties(objArray)
    end
    % case0 : 0x1 or 1x0 object case1 : mx1 object array case2 : 1xm object
    % array case3 : mxn object array
    import internal.matlab.datatoolsservices.FormatDataUtils;
    s = size(objArray);

    if s(1) == 0 || s(2) == 0
        objDataAsCell = repmat({''}, 1, length(props));
    elseif s(1) > 1 && s(2) > 1
        % case 3 -- still need to return a cell array
        objDataAsCell = cell(s);
        for row = 1:s(1)
            for col = 1:s(2)
                objDataAsCell{row, col} = FormatDataUtils.convertObjectArrayToCell(objArray(row, col), props);
            end
        end
    else
        % case 1 & 2
        if s(1) == 1 && s(2) > 1
            objArray = objArray';
        end
        objDataAsCell = (FormatDataUtils.obj2cell(objArray, props));
    end
end
