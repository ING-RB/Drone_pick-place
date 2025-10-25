classdef (InferiorClasses = {?datetime, ...
                             ?duration, ...
                             ?categorical}) ...
        UnconstrainedRowFilter < matlab.io.internal.AbstractRowFilter
%UnconstrainedRowFilter   Represents a filtering operation on a specific table
%   or timetable variable, but without any constraints.
%
%   All rows will be returned if this filter is applied to an input table
%   or timetable. But the input table/timetable will be checked to verify
%   that the VariableName is present, and an error will be thrown if it is
%   not present.

%   Copyright 2021-2022 The MathWorks, Inc.

    methods
        function obj = UnconstrainedRowFilter(props)
            arguments
                props (1, 1) matlab.io.internal.filter.properties.UnconstrainedRowFilterProperties;
            end

            obj.Properties = props;
        end
    end

    methods (Hidden)
        function tf = filterIndices(obj, T)
        % Verify that the input table/timetable contains the selected
        % variable name.
            import matlab.io.internal.filter.validators.validateVariableName;
            validateVariableName(obj.Properties.VariableName, T);

            % All rows are returned.
            tf = true(height(T), 1);
        end

        function obj = traverse(obj, fcn)
            matlab.io.internal.filter.validators.validateTraversalFcn(fcn);

            obj = fcn(obj);
        end

        function newFilter = applyRelationalOperator(unconstrainedFilter, operator, operand)
            import matlab.io.internal.filter.SingleVariableRowFilter;
            import matlab.io.internal.filter.properties.SingleVariableRowFilterProperties;

            selectedVariableName = unconstrainedFilter.Properties.VariableName;
            allVariableNames = unconstrainedFilter.Properties.VariableNames;

            props = SingleVariableRowFilterProperties(selectedVariableName, operator, operand, allVariableNames);
            newFilter = SingleVariableRowFilter(props);
        end

        function variableNames = constrainedVariableNames(~)
            % No constraints defined on this RowFilter yet, so return empty
            % string.
            variableNames = string.empty(1, 0);
        end

        function str = string(obj)
            str = obj.Properties.VariableName + " <unconstrained>";
        end
    end

    methods (Static, Hidden)
        function rf = loadobj(S)
            import matlab.io.internal.filter.*;
            import matlab.io.internal.filter.util.*;

            loadobjCommon(S);
            rf = UnconstrainedRowFilter(S.Properties);
        end
    end

    methods (Hidden)
        function s = formatDisplayHeader(obj, classname)
            msg = message("MATLAB:io:filter:display:UnconstrainedRowFilterHeader").getString();
            s = classname + " " + msg + " " + obj.Properties.VariableName;

            % Use truncateLine (source in the ioWrapString function
            % in matlab/src/services/io/iofun.cpp.) to truncate based
            % on display window width. Also, replace the special characters
            % in variable names in Header:
            % Newline with knuckle "return arrow ↵",
            % CR with "backarrow ←" ("ellipsis ..." for both in nodesktop),
            % and tab with "right arrow →".
            s = matlab.internal.display.truncateLine(s);
        end

        function s = formatDisplayBody(obj)
            s = string(obj);

            % Use truncateLine (source in the ioWrapString function
            % in matlab/src/services/io/iofun.cpp.) to truncate based
            % on display window width. Also, replace the special characters
            % in variable names alongside "<unconstrained>" in body:
            % Newline with knuckle "return arrow ↵",
            % CR with "backarrow ←" ("ellipsis ..." for both in nodesktop),
            % and tab with "right arrow →".
            s = matlab.internal.display.truncateLine(s);
        end
    end
end
