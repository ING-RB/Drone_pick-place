function TT = buildEmpty(obj)
%TimetableBuilder.buildEmpty   Construct an empty timetable from the
%   current TimetableBuilder options.
%
%   If VariableTypes is supplied, then the generated empty timetable contains empty
%   data of the supplied type in each variable.
%
%   Note that the RowTimes variable must have its type specified so we can generate
%   the correct type of empty here.

%   Copyright 2022 The MathWorks, Inc.

    % Verify that the type of the RowTimes variable is specified.
    rowTimesType = obj.Options.TableBuilder.VariableTypes(obj.Options.RowTimesVariableIndex);
    if ismissing(rowTimesType)
        error(message("MATLAB:io:common:builder:BuildEmptyRequiresRowTimesType"));
    end

    % Build the table.
    T = obj.Options.TableBuilder.buildEmpty();

    % Convert to a timetable.
    TT = table2timetable(T, RowTimes=obj.RowTimesVariableName);
end
