classdef (InferiorClasses = {?datetime, ...
                             ?duration, ...
                             ?categorical}) ...
        NegationRowFilter < matlab.io.internal.AbstractRowFilter
%NegationRowFilter   Represents negation of a table/timetable filter.
%
%   See also: rowfilter

%   Copyright 2021-2022 The MathWorks, Inc.

    methods
        function obj = NegationRowFilter(props)
            arguments
                props (1, 1) matlab.io.internal.filter.properties.NegationRowFilterProperties
            end

            obj.Properties = props;
        end
    end

    methods (Hidden)
        function tf = filterIndices(obj, T)
            tf = ~filterIndices(obj.Properties.UnderlyingFilter, T);
        end

        function obj = traverse(obj, fcn)
            matlab.io.internal.filter.validators.validateTraversalFcn(fcn);

            obj.Properties.UnderlyingFilter = traverse(obj.Properties.UnderlyingFilter, fcn);
            obj = fcn(obj);
        end

        function variableNames = constrainedVariableNames(obj)
            % Just forward the constrained variable names from the
            % underlying filters.
            variableNames = constrainedVariableNames(obj.Properties.UnderlyingFilter);
        end

        function str = string(obj)
            import matlab.io.internal.filter.util.parenthesize;

            str = "~" + parenthesize(string(obj.Properties.UnderlyingFilter));
        end
    end

    methods (Static, Hidden)
        function rf = loadobj(S)
            import matlab.io.internal.filter.*;
            import matlab.io.internal.filter.util.*;

            loadobjCommon(S);
            rf = NegationRowFilter(S.Properties);
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
