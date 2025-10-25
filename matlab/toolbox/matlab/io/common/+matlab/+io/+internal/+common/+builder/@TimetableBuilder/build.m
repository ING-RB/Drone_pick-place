function TT = build(obj, varargin)
%TimetableBuilder.build   Construct a timetable from the current
%   TimetableBuilder options.
%
%   The number of variables provided as input must match the number of VariableNames
%   in the object.

%   Copyright 2022 The MathWorks, Inc.

    % Build the table.
    T = obj.Options.TableBuilder.build(varargin{:});

    % Convert to a timetable.
    TT = table2timetable(T, RowTimes=obj.RowTimesVariableName);
end
