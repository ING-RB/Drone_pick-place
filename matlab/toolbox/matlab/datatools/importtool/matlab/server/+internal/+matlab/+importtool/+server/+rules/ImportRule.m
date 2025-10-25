% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents an Import Rule for importing.

% Copyright 2018 The MathWorks, Inc.

classdef ImportRule < handle & matlab.mixin.Heterogeneous
    properties
        % True if this is a non-numeric replacement rule
        nonNumericReplaceRule logical;
        
        % True if this is a string replacement rule
        stringReplaceRule logical;
        
        % True if this is a row exclusion rule
        rowExcludeRule logical;
        
        % True if this is a column exclusion rule
        colExcludeRule logical;
        
        % Unique ID representing the rule
        ID string;
        
        ExclusionStrategy = [];
    end
    
    methods
        function this = ImportRule()
            % Creates an ImportRule.
            this.nonNumericReplaceRule = false;
            this.stringReplaceRule = false;
            this.rowExcludeRule = false;
            this.colExcludeRule = false;
        end
        
        function strategy = getRuleStrategy(this)
            strategy = this.ExclusionStrategy;
        end
    end
end