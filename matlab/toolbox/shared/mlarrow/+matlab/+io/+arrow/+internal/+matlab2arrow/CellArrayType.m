classdef CellArrayType
    %CELLARRAYTYPE Enumeration which represents cell array
    % data contents.

    enumeration
        AllMissing          % The cell array only contains <missing> values.
        ContainsValidValue % The cell array has at least 1 valid (non-<missing>) value.
    end
end

