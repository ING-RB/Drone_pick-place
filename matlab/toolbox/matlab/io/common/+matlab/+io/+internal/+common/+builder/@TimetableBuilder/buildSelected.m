function TT = buildSelected(obj, varargin)
%TimetableBuilder.buildSelected   Construct a timetable from the current
%   TimetableBuilder options.
%
%   Unlike TimetableBuilder.build(), you only have to specify selected
%   variables in the input to this function.
%
%   So the number of input variables should match the number of
%   SelectedVariableNames/SelectedVariableIndices.
%
%   NOTE: SelectedVariableIndices isn't necessarily in ascending order!
%   Make sure that your inputs are in the same order as
%   SelectedVariableIndices.

%   Copyright 2022 The MathWorks, Inc.

    % Build the table.
    T = obj.Options.TableBuilder.buildSelected(varargin{:});

    % Convert to a timetabel.
    TT = table2timetable(T, RowTimes=obj.RowTimesVariableName);
end
