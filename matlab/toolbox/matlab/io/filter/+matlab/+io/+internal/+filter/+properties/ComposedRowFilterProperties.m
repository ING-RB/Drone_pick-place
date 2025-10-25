classdef ComposedRowFilterProperties < matlab.io.internal.filter.properties.Properties
%ComposedRowFilterProperties   Properties object for AbstractRowFilter
%   subclasses that directly compose other RowFilters without modification.
%
%   See also: rowfilter

%   Copyright 2021 The MathWorks, Inc.

    properties
        UnderlyingFilter(1, 1) matlab.io.internal.AbstractRowFilter = matlab.io.internal.filter.util.makeMissingRowFilter();
    end

    methods
        function props = ComposedRowFilterProperties(filter)
            arguments
                filter (1, 1) matlab.io.internal.AbstractRowFilter
            end

            props.UnderlyingFilter = filter;
        end

        function varNames = getVariableNames(props)
            underlyingProps = getProperties(props.UnderlyingFilter);
            varNames = getVariableNames(underlyingProps);
        end

        function props = replaceVariableNames(props, oldVariableNames, newVariableNames)
            % Just forward to the underlying filter.
            props.UnderlyingFilter = replaceVariableNames(props.UnderlyingFilter, oldVariableNames, newVariableNames);
        end
    end
end