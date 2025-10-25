classdef NameValuePair < matlab.mixin.Heterogeneous
%NAMEVALUEPAIR Object representing a name-value pair.

% Copyright 2023 The MathWorks, Inc.

    properties(GetAccess=public, SetAccess=private)
        Name
        DefaultValue
    end

    methods
        function obj = NameValuePair(name, defaultValue)
            arguments
                name (1, 1) string {mustBeNonmissing, mustBeNonzeroLengthText}
                defaultValue
            end
            obj.Name = name;
            obj.DefaultValue = defaultValue;
        end
    end

    methods(Abstract)
        rhs = validate(obj, rhs)
    end
end

