classdef TableSelectorProvider < matlab.io.internal.FunctionInterface ...
                               & matlab.io.xml.internal.parameter.SelectorProviderShared
%

% Copyright 2021-2024 The MathWorks, Inc.

    properties (Parameter)
        %TableSelector
        %    XPath expression that selects the XML Element node containing
        %    the table data.
        TableSelector (1,:) = string(missing)
    end

    methods
        function obj = set.TableSelector(obj, rhs)
            rhs = obj.convertToString(rhs);
            obj.validateSelectors(rhs,...
                "MATLAB:io:xml:readtable:InvalidScalarSelectorDatatype",...
                "TableSelector");
            obj.TableSelector = rhs;
        end
    end
end
