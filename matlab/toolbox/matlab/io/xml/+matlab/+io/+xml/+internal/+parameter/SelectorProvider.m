classdef SelectorProvider < matlab.io.internal.FunctionInterface ...
                          & matlab.io.xml.internal.parameter.SelectorProviderShared
%

% Copyright 2019-2024 The MathWorks, Inc.

    properties (Parameter)
        %VariableSelectors
        %    XPath expressions that select the XML Element nodes to be
        %    treated as variables of the output table.
        VariableSelectors = string(missing)

        %VariableUnitsSelector
        %    XPath expression that selects the XML Element node containing
        %    the variable units.
        VariableUnitsSelector (1,:) = string(missing)

        %VariableDescriptionSelector
        %    XPath expression that selects the XML Element node containing
        %    the variable descriptions.
        VariableDescriptionsSelector (1,:) = string(missing)

        %RowNamesSelector
        %   XPath expression that selects the XML Element nodes containing
        %   the row names.
        RowNamesSelector (1,:) = string(missing);
    end

    methods(Abstract, Access = protected)
        validateVariableSelectorsSize(obj, numSelectors);
    end
    
    methods
        function obj = set.VariableSelectors(obj, rhs)
        % check that the number of variable selectors provided is
        % equivalent to the number of variable names
            rhs = obj.convertToString(rhs);
            numSelectors = numel(rhs);
            validateVariableSelectorsSize(obj, numSelectors);
            
            % only reshape rhs if the number of existing variables is
            % greater than 0 to avoid creating a 1 by 0 string array.
            if numSelectors > 0
                rhs = reshape(rhs, 1, []);
            else
               rhs = string.empty(0, 0); 
            end

            for selector = rhs
                obj.validateSelectors(selector,...
                    "MATLAB:io:xml:readtable:InvalidSelectorArrayDatatype",...
                    "VariableSelectors");
            end
            
            obj.VariableSelectors = rhs;
        end

        function obj = set.VariableUnitsSelector(obj, rhs)
            rhs = obj.convertToString(rhs);
            obj.validateSelectors(rhs,...
                "MATLAB:io:xml:readtable:InvalidScalarSelectorDatatype",...
                "VariableUnitsSelector");
            obj.VariableUnitsSelector = rhs;
        end

        function obj = set.VariableDescriptionsSelector(obj, rhs)
            rhs = obj.convertToString(rhs);
            obj.validateSelectors(rhs,...
                "MATLAB:io:xml:readtable:InvalidScalarSelectorDatatype",...
                "VariableDescriptionsSelector");
            obj.VariableDescriptionsSelector = rhs;
        end

        function obj = set.RowNamesSelector(obj, rhs)
            rhs = obj.convertToString(rhs);
            obj.validateSelectors(rhs,...
                "MATLAB:io:xml:readtable:InvalidScalarSelectorDatatype",...
                "RowNamesSelector");            
            obj.RowNamesSelector = rhs;
        end
    end
end
