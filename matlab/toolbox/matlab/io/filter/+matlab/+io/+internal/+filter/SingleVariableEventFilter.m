classdef SingleVariableEventFilter < matlab.io.internal.filter.SingleVariableRowFilter
%SingleVariableEventFilter   Represents a filtering operation on a timetable variable based on event labels.

%   Copyright 2022-2023 The MathWorks, Inc.


    methods (Hidden)
        function tf = filterIndices(obj, TT) 
            import matlab.io.internal.filter.operator.RelationalOperator;
            
            if class(TT) == "timetable"
                ET = TT.Properties.Events;
            else
                ET = TT;
            end
            
            if isempty(obj.Properties.VariableNames)
                eventVarName = ET.Properties.EventLabelsVariable;
                if isnumeric(eventVarName) % [], i.e. an eventtable with no labels var tagged
                    error(message("MATLAB:eventfilter:NoEventLabelsForSubscripting"));
                end          
                eventLabels = ET.(eventVarName);
            else
                eventLabels = ET.(obj.Properties.VariableName);
                eventVarName = obj.Properties.VariableName;
            end

            eventIndices = obj.Properties.Operator.applyOperator(eventLabels, ...
                obj.Properties.Operand, ...
                eventVarName);

            if class(TT) == "timetable"
                % Ask the timetable which rows match each event time.
                % Return tf the same height as the timetable.
                tf = eventIndices2timetableIndices(TT,eventIndices);
            else
                % Return tf the same height as the eventtable.
                tf = eventIndices;
            end
        end


           function newFilter = applyRelationalOperator(singleVarFilter, operator, operand)
            import matlab.io.internal.filter.*;
            import matlab.io.internal.filter.properties.*;
            import matlab.io.internal.filter.operator.BinaryOperator;

            % Use the operator and operand to create a second filter on the same
            % variable name.
            props = SingleVariableRowFilterProperties(singleVarFilter.Properties.VariableName, operator, operand, ...
                                                      singleVarFilter.Properties.VariableNames);
            otherFilter = SingleVariableEventFilter(props);

            % Generate a multiple variable filter as an AND of the two supplied
            % filters.
            props = MultipleVariableRowFilterProperties(singleVarFilter, otherFilter, BinaryOperator.And);
            newFilter = MultipleVariableRowFilter(props);
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
            if isempty(S.Properties.VariableNames)
                % If the VariableNames property of a SingleVariableEventFilter
                % is empty then we are filtering on the event labels variable.
                % Since <Event Labels Variable> is only for display, overwrite
                % the saved value to make sure locale is correct.
                S.Properties.VariableName = getString(message("MATLAB:eventfilter:UIStringDispEventLabelsVariable"));
            end
            rf = SingleVariableEventFilter(S.Properties);
        end
    end
end