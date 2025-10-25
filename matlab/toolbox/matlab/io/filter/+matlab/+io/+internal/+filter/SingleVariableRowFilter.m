classdef (InferiorClasses = {?datetime, ...
                             ?duration, ...
                             ?categorical}) ...
        SingleVariableRowFilter < matlab.io.internal.AbstractRowFilter
%SingleVariableRowFilter   Represents a filtering operation on a table
%   or timetable variable.

%   Copyright 2021-2022 The MathWorks, Inc.

    methods
        function obj = SingleVariableRowFilter(props)
            arguments
                props (1, 1) matlab.io.internal.filter.properties.SingleVariableRowFilterProperties
            end

            obj.Properties = props;
        end
    end

    methods (Hidden)
        function tf = filterIndices(obj, T)

            import matlab.io.internal.filter.operator.RelationalOperator;

            data = T.(obj.Properties.VariableName);

            tf = obj.Properties.Operator.applyOperator(data, ...
                                                  obj.Properties.Operand, ...
                                                  obj.Properties.VariableName);
        end

        function obj = traverse(obj, fcn)
            matlab.io.internal.filter.validators.validateTraversalFcn(fcn);

            obj = fcn(obj);
        end

        function newFilter = applyRelationalOperator(singleVarFilter, operator, operand)
            import matlab.io.internal.filter.*;
            import matlab.io.internal.filter.properties.*;
            import matlab.io.internal.filter.operator.BinaryOperator;

            % Use the operator and operand to create a second filter on the same
            % variable name.
            props = SingleVariableRowFilterProperties(singleVarFilter.Properties.VariableName, operator, operand, ...
                                                      singleVarFilter.Properties.VariableNames);
            otherFilter = SingleVariableRowFilter(props);

            % Generate a multiple variable filter as an AND of the two supplied
            % filters.
            props = MultipleVariableRowFilterProperties(singleVarFilter, otherFilter, BinaryOperator.And);
            newFilter = MultipleVariableRowFilter(props);
        end

        function variableNames = constrainedVariableNames(obj)
            % SingleVariableRowFilter can only be constrained by one
            % variable name.
            variableNames = obj.Properties.VariableName;
        end

        function str = string(obj)
            import matlab.io.internal.filter.util.makeConstraintString

            str = makeConstraintString(obj.Properties.VariableName, ...
                obj.Properties.Operator, obj.Properties.Operand);
        end
    end

    methods (Static, Hidden)
        function rf = loadobj(S)
            import matlab.io.internal.filter.*;
            import matlab.io.internal.filter.util.*;

            loadobjCommon(S);
            rf = SingleVariableRowFilter(S.Properties);
        end
    end

    methods (Hidden)
        function s = formatDisplayHeader(~, classname)
            msg = message("MATLAB:io:filter:display:SingleVariableRowFilterHeader").getString();
            s = classname + " " + msg;
        end

        function s = formatDisplayBody(obj)
            % Stringify the relational operator constraint and display it.
            s = string(obj);

            % Use truncateLine (source in the ioWrapString function
            % in matlab/src/services/io/iofun.cpp.) to truncate based
            % on display window width.
            % Also, replace the special characters in Constraint:
            % Newline with knuckle "return arrow ↵",
            % CR with "backarrow ←" ("ellipsis ..." for both in nodesktop),
            % and tab with "right arrow →".
            s = matlab.internal.display.truncateLine(s);
        end
    end
end
