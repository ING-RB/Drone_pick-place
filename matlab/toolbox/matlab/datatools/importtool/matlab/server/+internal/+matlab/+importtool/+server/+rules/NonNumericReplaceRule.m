% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents an Import Rule for replacing non-numeric values.

% Copyright 2018 The MathWorks, Inc.
classdef NonNumericReplaceRule < internal.matlab.importtool.server.rules.ImportRule 
    properties
        replaceValue double;
    end
    
    methods
        function this = NonNumericReplaceRule(value)
            % Creates a non-numeric replacement rule.  
            this = this@internal.matlab.importtool.server.rules.ImportRule();
            this.nonNumericReplaceRule = true;
            this.ID = "nonNumericReplaceRule";
            
            % If the value is provided, use it.  Otherwise default to NaN as the
            % replacement value.
            if nargin < 1
                this.replaceValue = NaN;
            else
                this.replaceValue = value;
            end
        end
    end
end
