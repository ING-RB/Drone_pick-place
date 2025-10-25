classdef (InferiorClasses = {?datetime, ...
                             ?duration, ...
                             ?categorical}) ...
        MultipleVariableRowFilter < matlab.io.internal.AbstractRowFilter
%MultipleVariableRowFilter   Represents filtering operations on multiple
%   table or timetable variables.

%   Copyright 2021-2022 The MathWorks, Inc.

    methods
        function obj = MultipleVariableRowFilter(props)
            arguments
                props (1, 1) matlab.io.internal.filter.properties.MultipleVariableRowFilterProperties
            end

            obj.Properties = props;     
        end
    end

    methods (Hidden)
        function tf = filterIndices(obj, T)

            tf1 = filterIndices(obj.Properties.LHS, T);
            tf2 = filterIndices(obj.Properties.RHS, T);

            import matlab.io.internal.filter.operator.BinaryOperator;

            switch obj.Properties.Operator
              case BinaryOperator.And
                tf = tf1 & tf2;
              case BinaryOperator.Or
                tf = tf1 | tf2;
              otherwise
                error(message('MATLAB:io:filter:filter:OperatorNotSupported'));
            end
        end

        function obj = traverse(obj, fcn)
            matlab.io.internal.filter.validators.validateTraversalFcn(fcn);

            obj.Properties.LHS = traverse(obj.Properties.LHS, fcn);
            obj = fcn(obj);
            obj.Properties.RHS = traverse(obj.Properties.RHS, fcn);
        end

        function variableNames = constrainedVariableNames(obj)
            % MultipleVariableRowFilter's constraints are defined by the set-join of
            % all the underlying filter's constrained variable names.
            variableNames = union(constrainedVariableNames(obj.Properties.LHS), ...
                                  constrainedVariableNames(obj.Properties.RHS), 'stable');
        end

        function str = string(obj)
        % Parenthesize any underlying filter that is a multiple
        % variable row filter.
            lhsString = parenthesizeIfNecessary(obj.Properties.LHS);
            rhsString = parenthesizeIfNecessary(obj.Properties.RHS);
            str = lhsString + " " + string(obj.Properties.Operator) + " " + rhsString;
        end
    end

    methods (Access = protected)
        function f = buildUnconstrainedFilter(obj, variableName, possibleVariableNames)

            import matlab.io.internal.filter.UnconstrainedEventFilter;
            import matlab.io.internal.filter.UnconstrainedRowFilter;
            import matlab.io.internal.filter.properties.UnconstrainedRowFilterProperties;

            % The leaf filters of a MultipleVariableRowFilter will always
            % be either both eventfilters or rowfilters. Use them to build
            % the correct unconstrained filter.
            f = buildUnconstrainedFilter(obj.Properties.LHS,variableName, possibleVariableNames);
        end

    end

    methods (Static, Hidden)
        function rf = loadobj(S)
            import matlab.io.internal.filter.*;
            import matlab.io.internal.filter.util.*;

            loadobjCommon(S);
            rf = MultipleVariableRowFilter(S.Properties);
        end
    end

    methods (Hidden)
        function s = formatDisplayHeader(~, classname)
            msg = message("MATLAB:io:filter:display:MultipleVariableRowFilterHeader").getString();
            s = classname + " " + msg;
        end

        function s = formatDisplayBody(obj)
            % Stringify the binary operator constraint and display it.
            s = string(obj);

            % Use truncateLine (source in the ioWrapString function
            % in matlab/src/services/io/iofun.cpp.) to truncate based
            % on display window width. Also, replace the special characters
            % in Constraints and Selected Variables:
            % Newline with knuckle "return arrow ↵",
            % CR with "backarrow ←" ("ellipsis ..." for both in nodesktop),
            % and tab with "right arrow →".
            s = matlab.internal.display.truncateLine(s);
        end
    end
end

function str = parenthesizeIfNecessary(f)
    str = string(f);
    if isa(f, "matlab.io.internal.filter.MultipleVariableRowFilter")
        str = matlab.io.internal.filter.util.parenthesize(str);
    end
end
