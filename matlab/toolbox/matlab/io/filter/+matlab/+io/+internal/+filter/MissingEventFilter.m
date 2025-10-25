classdef (InferiorClasses = {?datetime, ...
        ?duration, ...
        ?categorical}) ...
        MissingEventFilter < matlab.io.internal.filter.MissingRowFilter
    %MissingEventFilter   Represents no filtering operations on the input
    %timetable's attached events.
    %   All event rows from the timetable are selected.
    

    %   Copyright 2022-2023 The MathWorks, Inc.

    methods (Hidden)
        function tf = filterIndices(obj, TT)
            % All rows are selected.
            if class(TT) == "timetable"
                tf = eventIndices2timetableIndices(TT);
            else % eventtable
                tf = obj.filterIndices@matlab.io.internal.filter.MissingRowFilter(TT);
            end
        end
    end

    methods (Access = protected)
        function ef = buildUnconstrainedFilter(obj, variableName, possibleVariableNames)

            import matlab.io.internal.filter.UnconstrainedEventFilter;
            import matlab.io.internal.filter.properties.UnconstrainedRowFilterProperties;

            props = UnconstrainedRowFilterProperties(variableName, possibleVariableNames);
            ef = UnconstrainedEventFilter(props);
        end
    end

    methods (Static, Hidden)
        function rf = loadobj(S)
            import matlab.io.internal.filter.*;
            import matlab.io.internal.filter.util.*;

            loadobjCommon(S);
            rf = MissingEventFilter(S.Properties);
        end
    end
end
