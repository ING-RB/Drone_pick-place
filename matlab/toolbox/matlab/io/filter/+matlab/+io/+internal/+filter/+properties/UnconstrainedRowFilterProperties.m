classdef UnconstrainedRowFilterProperties < matlab.io.internal.filter.properties.MissingRowFilterProperties
%
%
%   See also: rowfilter

%   Copyright 2021 The MathWorks, Inc.

    properties
        VariableName (1, 1) string {mustBeNonmissing}
    end

    methods
        function props = UnconstrainedRowFilterProperties(VariableName, VariableNames)
            props = props@matlab.io.internal.filter.properties.MissingRowFilterProperties(VariableNames);
            props.VariableName = VariableName;
        end

        function props = replaceVariableNames(props, oldVariableNames, newVariableNames)
            props = replaceVariableNames@matlab.io.internal.filter.properties.MissingRowFilterProperties(props, oldVariableNames, newVariableNames);

            % Also replace the VariableName property.
            import matlab.io.internal.filter.util.replaceVariableNames;
             varNames = replaceVariableNames(props.VariableName, oldVariableNames, newVariableNames);
             props.VariableName = varNames(1);
        end
    end
end
