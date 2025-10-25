% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents an Import Rule for excluding columns.

% Copyright 2018 The MathWorks, Inc.
classdef ExcludeColumnsWithBlanksRule < internal.matlab.importtool.server.rules.ImportRule    
    methods
        function this = ExcludeColumnsWithBlanksRule()
            this = this@internal.matlab.importtool.server.rules.ImportRule();
            this.colExcludeRule = true;
            this.ID = "excludeColumnsWithBlanks";
            this.ExclusionStrategy = internal.matlab.importtool.server.rules.BlankExclusionStrategy;
        end        
    end
end
