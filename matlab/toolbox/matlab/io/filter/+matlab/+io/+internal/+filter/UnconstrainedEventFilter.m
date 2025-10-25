classdef (InferiorClasses = {?datetime, ...
                             ?duration, ...
                             ?categorical}) ...
        UnconstrainedEventFilter < matlab.io.internal.filter.UnconstrainedRowFilter

%UnconstrainedEventFilter   Represents a filtering operation on a specific
% attached eventtable variable, but without any constraints.

%   Copyright 2022-2023 The MathWorks, Inc

    methods (Hidden)

        function tf = filterIndices(obj, TT)      
            if class(TT) == "timetable"
                tf = eventIndices2timetableIndices(TT);
            else % eventtable
                tf = obj.filterIndices@matlab.io.internal.filter.UnconstrainedRowFilter(TT);
            end
        end


        function newFilter = applyRelationalOperator(unconstrainedFilter, operator, operand)
            import matlab.io.internal.filter.SingleVariableEventFilter;
            import matlab.io.internal.filter.properties.SingleVariableRowFilterProperties;

            selectedVariableName = unconstrainedFilter.Properties.VariableName;
            allVariableNames = unconstrainedFilter.Properties.VariableNames;

            props = SingleVariableRowFilterProperties(selectedVariableName, operator, operand, allVariableNames);
            newFilter = SingleVariableEventFilter(props);
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
            rf = UnconstrainedEventFilter(S.Properties);
        end
    end

end