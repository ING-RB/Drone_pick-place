classdef Constants
    %CONSTANTS contains constant properties for the Code Log section.

    % Copyright 2021 The MathWorks, Inc.

    properties
        CodeLogLayout = matlabshared.transportapp.internal.utilities.forms.AppSpaceGridLayout(1, 1)
        CodeLogGrid = struct( ...
            'ColumnWidth', "1x", ...
            'RowHeight', "1x", ...
            'Padding', [0 0 0 0] ...
            )
    end
end