classdef RegisteredNamespacesProvider < matlab.io.internal.FunctionInterface
% REGISTEREDNAMESPACESPROVIDER An interface for functions that accept RegisteredNamespaces.

% Copyright 2020 The MathWorks, Inc.

    properties (Parameter)
        %RegisteredNamespaces
        %   The namespaces prefixes that are mapped to namespace URLs
        %   for use in selector expressions.
        RegisteredNamespaces = string.empty(0, 2);
    end

    methods
        function obj = set.RegisteredNamespaces(obj, rhs)
            rhs = convertCharsToStrings(rhs);
            if ~isstring(rhs)
                error(message("MATLAB:io:xml:xpath:InvalidRegisteredNamespacesSize"));
            end

            matlab.io.xml.internal.xpath.validate_namespaces(rhs);
            obj.RegisteredNamespaces = rhs;
        end
    end
end
