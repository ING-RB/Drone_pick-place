% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents an Import Rule for excluding rows with unimportable
% cells.

% Copyright 2018 The MathWorks, Inc.
classdef ExcludeUnimportableRowRule < internal.matlab.importtool.server.rules.ImportRule 
    
    methods
        function this = ExcludeUnimportableRowRule()
            this = this@internal.matlab.importtool.server.rules.ImportRule();
            this.rowExcludeRule = true;
            this.ID = "excludeUnimportableRows";
            this.ExclusionStrategy = internal.matlab.importtool.server.rules.UnimportableExclusionStrategy;
        end        
    end
end
