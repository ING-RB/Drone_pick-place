classdef MultipleVariableRowFilterProperties < matlab.io.internal.filter.properties.Properties
%
%
%   See also: rowfilter

%   Copyright 2021 The MathWorks, Inc.

    properties
        LHS      (1, 1) matlab.io.internal.AbstractRowFilter = matlab.io.internal.filter.util.makeMissingRowFilter();
        RHS      (1, 1) matlab.io.internal.AbstractRowFilter = matlab.io.internal.filter.util.makeMissingRowFilter();
        Operator (1, 1) matlab.io.internal.filter.operator.BinaryOperator;
    end

    methods
        function props = MultipleVariableRowFilterProperties(lhs, rhs, op)
            props.LHS = lhs;
            props.RHS = rhs;
            props.Operator = op;
        end

        function varNames = getVariableNames(props)
            % Set the VariableNames to the union of the VariableNames on the
            % underlying filters.
            lhsProps = getProperties(props.LHS);
            rhsProps = getProperties(props.RHS);
            varNames = union(lhsProps.VariableNames, rhsProps.VariableNames, 'stable');
        end

        function props = replaceVariableNames(props, oldVariableNames, newVariableNames)
            % Just forward to the underlying filters.
            props.LHS = replaceVariableNames(props.LHS, oldVariableNames, newVariableNames);
            props.RHS = replaceVariableNames(props.RHS, oldVariableNames, newVariableNames);
        end
    end
end
