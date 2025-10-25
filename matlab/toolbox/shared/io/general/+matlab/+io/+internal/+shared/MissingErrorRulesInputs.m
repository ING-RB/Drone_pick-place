classdef MissingErrorRulesInputs <  matlab.io.internal.FunctionInterface
    %
    
    % Copyright 2016-2021 The MathWorks, Inc.
    properties (Parameter)
        %IMPORTERRORRULE The action to take when importing fails
        %
        %   'fill'    - replace the failure with the contents of 'FillValue'
        %
        %   'error'   - Stop importing and indicate the record and field which caused
        %               the failure.
        %
        %   'omitrow' - Rows where errors occur will not be imported.
        %
        %   'omitvar' - Variables where errors occur will not be imported.
        %
        % See also matlab.io.VariableImportOptions
        %   matlab.io.spreadsheet.SpreadsheetImportOptions/MissingRule
        %   matlab.io.VariableImportOptions/FillValue
        ImportErrorRule = 'fill';
        
        %MISSINGRULE The action to take when data is missing
        %
        %   'fill'    - replace the missing data with the contents of 'FillValue'
        %
        %   'error'   - Stop importing and indicate the record and field which was
        %               missing.
        %
        %   'omitrow' - Rows where missing data occur will not be imported.
        %
        %   'omitvar' - Variables where missing data occur will not be imported.
        %
        % See also matlab.io.VariableImportOptions
        %   matlab.io.spreadsheet.SpreadsheetImportOptions/ImportErrorRule
        %   matlab.io.VariableImportOptions/FillValue
        MissingRule = 'fill';
    end
    
    methods
        function obj = set.ImportErrorRule(obj,rhs)
            rules = matlab.io.internal.replacementRules;
            if isa(obj,'matlab.io.internal.mixin.UsesStringsForPropertyValues')
                rules = string(rules);
            end
            obj.ImportErrorRule = validatestring(rhs,rules);
        end
        
        function obj = set.MissingRule(obj,rhs)
            rules = matlab.io.internal.replacementRules;
            if isa(obj,'matlab.io.internal.mixin.UsesStringsForPropertyValues')
                rules = string(rules);
            end
            obj.MissingRule = validatestring(rhs, rules);
        end
    end
end
