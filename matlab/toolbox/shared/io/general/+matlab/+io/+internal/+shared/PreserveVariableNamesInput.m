classdef PreserveVariableNamesInput < matlab.io.internal.FunctionInterface
    %
    
    %   Copyright 2019-2021 The MathWorks, Inc.
    
    properties (Parameter, Dependent)
        PreserveVariableNames(1,1) logical;
    end
    
    properties (Parameter)
        %VARIABLENAMINGRULE Controls the normalization of variable names.
        %
        %   "modify"   - Converts variable names to unique nonempty valid MATLAB
        %                identifiers.
        %
        %   "preserve" - Preserves variable names when importing. Will still
        %                make variable names unique and nonempty.
        %
        % See also READTABLE, PARQUETREAD
        VariableNamingRule = 'modify';
    end
    
    methods
        function obj = set.PreserveVariableNames(obj,rhs)
            if rhs
                obj.VariableNamingRule = 'preserve';
            else
                obj.VariableNamingRule = 'modify';
            end
        end
        
        function val = get.PreserveVariableNames(obj)
            val = (obj.VariableNamingRule == "preserve");
        end
        
        function obj = set.VariableNamingRule(obj,rhs)
            obj.VariableNamingRule = obj.validateNamingRule(rhs);
        end
        
        function val = get.VariableNamingRule(obj)
            val = obj.VariableNamingRule;
            if isa(obj,'matlab.io.internal.mixin.UsesStringsForPropertyValues')
                val = string(val);
            end
        end
    end
    
    methods (Static, Hidden)
        function rhs = validateNamingRule(rhs)
            rhs = validatestring(rhs,{'modify', 'preserve'});
        end
    end
end
