classdef SingleVariableRowFilterProperties < matlab.io.internal.filter.properties.UnconstrainedRowFilterProperties
%
%
%   See also: rowfilter

%   Copyright 2021-2022 The MathWorks, Inc.

    properties
        Operator (1, 1) matlab.io.internal.filter.operator.RelationalOperator;
        Operand = "";
    end

    methods
        function props = SingleVariableRowFilterProperties(VariableName, Operator, Operand, VariableNames)
            % Call the superclass ctor.
            props = props@matlab.io.internal.filter.properties.UnconstrainedRowFilterProperties(VariableName, VariableNames);

            props.Operator = Operator;
            props.Operand = Operand;
        end
    end
end
