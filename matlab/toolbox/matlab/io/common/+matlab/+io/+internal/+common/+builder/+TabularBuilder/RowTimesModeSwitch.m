function [builder, outputType] = RowTimesModeSwitch(builder, outputType, paramName, paramValue)
%RowTimesModeSwitch   When setting a RowTimes-related property, there are
%   four possibilities:
%
%    - TableBuilder -> TableBuilder         (starts as missing and set to missing)
%    - TableBuilder -> TimetableBuilder     (starts as missing and set to nonmissing)
%    - TimetableBuilder -> TableBuilder     (starts as nonmissing and set to missing)
%    - TimetableBuilder -> TimetableBuilder (starts as nonmissing and set to nonmissing)
%
%   This function handles these four possibilities for
%   RowTimesVariableIndex, RowTimesVariableName, RowTimes, and
%   OriginalRowTimesVariableName.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        builder    (1, 1)        {matlab.io.internal.common.builder.TabularBuilder.validateUnderlyingBuilder}
        outputType (1, 1) string {matlab.io.internal.common.builder.TabularBuilder.validateOutputType}
        paramName  (1, 1) string {mustBeMember(paramName, ["RowTimesVariableIndex" "RowTimesVariableName" "OriginalRowTimesVariableName" "RowTimes"])}
        paramValue
    end

    import matlab.io.internal.common.builder.TabularBuilder.TableBuilder2TimetableBuilder
    import matlab.io.internal.common.builder.TabularBuilder.TimetableBuilder2TableBuilder

    if outputType == "table"
        if ismissing(paramValue)
            % TableBuilder -> TableBuilder.
            % RowTimesVariableIndex=nan or RowTimesVariableName=string(missing)
            % Nothing to be done.
            return;
        else
            % TableBuilder -> TimetableBuilder.
            builder = TableBuilder2TimetableBuilder(builder, paramName, paramValue);
            outputType = "timetable";
        end
    else
        if ismissing(paramValue)
            % TimetableBuilder -> TableBuilder.
            % RowTimesVariableIndex=nan or RowTimesVariableName=string(missing)
            builder = TimetableBuilder2TableBuilder(builder);
            outputType = "table";
        else
            % TimetableBuilder -> TimetableBuilder.
            % No mode switch, but set the param on the underlying builder.
            builder.(paramName) = paramValue;
        end
    end
end
