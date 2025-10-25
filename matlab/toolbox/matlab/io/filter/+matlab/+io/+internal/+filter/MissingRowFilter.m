classdef (InferiorClasses = {?datetime, ...
                             ?duration, ...
                             ?categorical}) ...
        MissingRowFilter < matlab.io.internal.AbstractRowFilter
%MissingRowFilter   Represents no filtering operations on the input table
%   or timetable. All rows from the table are selected.
%
%   See also: rowfilter

%   Copyright 2022 The MathWorks, Inc.

    methods
        function obj = MissingRowFilter(props)
            arguments
                props (1, 1) matlab.io.internal.filter.properties.MissingRowFilterProperties
            end
            obj.Properties = props;
        end
    end

    methods (Hidden)
        function tf = filterIndices(~, T)
        % All rows are selected.
            tf = true(height(T), 1);
        end

        function obj = traverse(obj, fcn)
            matlab.io.internal.filter.validators.validateTraversalFcn(fcn);

            % Call the traversal function on this class itself.
            obj = fcn(obj);
        end

        function str = string(~)
            str = "<unconstrained>";
        end

        function variableNames = constrainedVariableNames(~)
            % No constrained variable names.
            variableNames = string.empty(1, 0);
        end
    end

    methods (Static, Hidden)
        function rf = loadobj(S)
            import matlab.io.internal.filter.*;
            import matlab.io.internal.filter.util.*;

            loadobjCommon(S);
            rf = MissingRowFilter(S.Properties);
        end
    end

    % Scalar object display logic.
    methods (Hidden)
        function s = formatDisplayHeader(~, classname)
            s = classname + " " + message("MATLAB:io:filter:display:MissingRowFilterHeader").getString();
        end

        function s = formatDisplayBody(obj)
            s = string(obj);
        end
    end
end
