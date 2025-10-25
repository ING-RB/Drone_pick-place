classdef MissingRowFilterProperties < matlab.io.internal.filter.properties.Properties
%MissingRowFilterProperties    Properties object for MissingRowFilter.
%
%   See also: rowfilter

%   Copyright 2021 The MathWorks, Inc.

    properties
        StoredVariableNames (1, :) string {mustBeNonmissing};
    end

    methods
        function props = MissingRowFilterProperties(VariableNames)
            arguments
                VariableNames (1, :) string
            end

            props.StoredVariableNames = VariableNames;
        end

        function varNames = getVariableNames(props)
            varNames = props.StoredVariableNames;
        end

        function props = replaceVariableNames(props, oldVariableNames, newVariableNames)
            import matlab.io.internal.filter.util.replaceVariableNames;
            props.StoredVariableNames = replaceVariableNames(props.StoredVariableNames, oldVariableNames, newVariableNames);
        end
    end
end
