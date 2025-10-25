classdef ScalarLogicalPair < matlab.io.internal.common.arguments.NameValuePair
%SCALARLOGICALPAIR Class representing a name-value pair whose value must 
% be a scalar logical or numeric value convertible to a scalar logical.

% Copyright 2023 The MathWorks, Inc.

    methods
        function obj = ScalarLogicalPair(name, defaultValue)
            arguments
                name
                defaultValue(1, 1) logical
            end
            obj@matlab.io.internal.common.arguments.NameValuePair(name, defaultValue);
        end

        function rhs = validate(obj, rhs)
            import matlab.io.internal.common.validators.isScalarLogical
            if ~isScalarLogical(rhs)
                id = "MATLAB:io:common:arguments:ExpectedScalarLogical";
                error(message(id, obj.Name));
            end
            rhs = logical(rhs);
        end
    end
end
