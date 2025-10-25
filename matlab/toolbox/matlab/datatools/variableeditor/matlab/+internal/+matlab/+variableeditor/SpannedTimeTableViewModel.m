classdef SpannedTimeTableViewModel < internal.matlab.variableeditor.SpannedTableViewModel & internal.matlab.variableeditor.TimeTableViewModel
    % Spanned Timetable ViewModel

    % Copyright 2023-2024 The MathWorks, Inc.
    
    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = SpannedTimeTableViewModel(dataModel, viewID)
            arguments
                dataModel
                viewID = ''
            end
            this@internal.matlab.variableeditor.SpannedTableViewModel(dataModel, viewID);
            this@internal.matlab.variableeditor.TimeTableViewModel(dataModel, viewID);
        end     
    end
end
