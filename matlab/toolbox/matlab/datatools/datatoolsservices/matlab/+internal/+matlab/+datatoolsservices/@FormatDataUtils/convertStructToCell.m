% the behaviour of vector structure arrays in the variable editor is similar to
% cell arrays.

% Copyright 2015-2024 The MathWorks, Inc.

function structDataAsCell = convertStructToCell(structData)
    % case0 : 0x1 or 1x0 struct
    % case1 : mx1 structure array
    % case2 : 1xm structure array
    % case3 : mxn structure array
    import internal.matlab.datatoolsservices.FormatDataUtils;
    s = size(structData);

    if s(1) == 0 || s(2) == 0
        structDataAsCell = repmat({''}, 1, length(fields(structData)));
    elseif s(1) > 1 && s(2) > 1
        % case 3 -- still need to return a cell array
        structDataAsCell = cell(s);
        for row = 1:s(1)
            for col = 1:s(2)
                structDataAsCell{row, col} = FormatDataUtils.convertStructToCell(structData(row, col));
            end
        end
    else
        % case 1 & 2
        if s(1) == 1 && s(2) > 1
            structData = structData';
        end
        structDataAsCell = (struct2cell(structData))';
    end
end