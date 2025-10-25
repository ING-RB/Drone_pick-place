classdef BinaryOperator
%BinaryOperator   Represents an operation which combines two RowFilter objects.
%
%   See also: rowfilter

%   Copyright 2021 The MathWorks, Inc.

    enumeration
        And,
        Or,
        Missing
    end

    methods
        function str = string(op)
            import matlab.io.internal.filter.operator.BinaryOperator;

            switch op
                case BinaryOperator.And
                    str = "&";
                case BinaryOperator.Or
                    str = "|";
                otherwise
                    error(message('MATLAB:io:filter:filter:OperatorNotSupported'));
            end
        end
    end
end