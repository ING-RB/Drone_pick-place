% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents an Import Rule for excluding rows.

% Copyright 2018 The MathWorks, Inc.
classdef ExcludeRowsWithBlanksRule < internal.matlab.importtool.server.rules.ImportRule 
    
    methods
        function this = ExcludeRowsWithBlanksRule()
            this = this@internal.matlab.importtool.server.rules.ImportRule();
            this.rowExcludeRule = true;
            this.ID = "excludeRowsWithBlanks";
            this.ExclusionStrategy = internal.matlab.importtool.server.rules.BlankExclusionStrategy;
        end      
    end
end
