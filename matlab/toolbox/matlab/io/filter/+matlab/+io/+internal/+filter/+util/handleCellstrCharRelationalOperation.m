function [x1, x2] = handleCellstrCharRelationalOperation(x1, x2)
%handleCellstrCharRelationalOperation   Converts one of the inputs to
%   a string if:
%    - The first input is a char row vector and the second input is a cellstr, or
%    - The first input is a cellstr and the second input is a char row vector, or
%    - The first input is a cellstr and the second input is a cellstr

%   Copyright 2022 The MathWorks, Inc.

    cellstrSupplied1 = iscellstr(x1);
    cellstrSupplied2 = iscellstr(x2);
    charSupplied1 = ischar(x1);
    charSupplied2 = ischar(x2);

    if charSupplied1 && cellstrSupplied2
        x2 = convertCharsToStrings(x2);
    elseif cellstrSupplied1 && charSupplied2
        x1 = convertCharsToStrings(x1);
    elseif cellstrSupplied1 && cellstrSupplied2
        x1 = convertCharsToStrings(x1);
    end
end
