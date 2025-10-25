% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents an Import Rule for excluding columns with
% unimportable cells.

% Copyright 2018 The MathWorks, Inc.
classdef ExcludeUnimportableColumnRule < internal.matlab.importtool.server.rules.ImportRule 
    
    methods
        function this = ExcludeUnimportableColumnRule()
            this = this@internal.matlab.importtool.server.rules.ImportRule();
            this.colExcludeRule = true;
            this.ID = "excludeUnimportableColumns";
            this.ExclusionStrategy = internal.matlab.importtool.server.rules.UnimportableExclusionStrategy;
        end        
    end
end
