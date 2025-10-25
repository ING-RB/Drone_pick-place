classdef BuildContentOperatorReverseIterator < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    properties (Access = private)
        Operators (1,:) cell
        CurrentIndex {mustBeNumeric}
    end
    
    properties (Dependent, SetAccess = private)
        HasNext (1,1) logical
    end
    
    methods
        function iter = BuildContentOperatorReverseIterator(operators)
            iter.Operators = operators;
            iter.CurrentIndex = numel(operators);
        end
        
        function advance(iter)
            iter.CurrentIndex = iter.CurrentIndex - 1;
        end
        
        function bool = get.HasNext(iter)
            bool = iter.CurrentIndex > 1;
        end
        
        function operator = getCurrentOperator(iter)
            operator = iter.Operators{iter.CurrentIndex};
        end
    end
end

