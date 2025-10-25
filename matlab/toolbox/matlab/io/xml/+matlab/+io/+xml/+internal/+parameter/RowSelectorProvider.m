classdef RowSelectorProvider < matlab.io.internal.FunctionInterface ...
                             & matlab.io.xml.internal.parameter.SelectorProviderShared
%

% Copyright 2024 The MathWorks, Inc.

    properties (Parameter)
        %RowSelector
        %    XPath expression that selects the XML Element nodes which
        %    delineate rows of the output table.
        RowSelector (1,:) = string(missing)
    end

    methods
        function obj = set.RowSelector(obj, rhs)
            rhs = obj.convertToString(rhs);
            obj.validateSelectors(rhs,...
                "MATLAB:io:xml:readtable:InvalidScalarSelectorDatatype",...
                "RowSelector");
            obj.RowSelector = rhs;
        end
    end
end
