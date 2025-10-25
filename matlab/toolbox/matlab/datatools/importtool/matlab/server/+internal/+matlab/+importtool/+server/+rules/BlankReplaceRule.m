% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents an Import Rule for replacing blanks.

% Copyright 2018 The MathWorks, Inc.
classdef BlankReplaceRule < internal.matlab.importtool.server.rules.ImportRule 
    properties
        replaceValue double;
    end
    
    methods
        function this = BlankReplaceRule(varargin)
            this = this@internal.matlab.importtool.server.rules.ImportRule();
            this.stringReplaceRule = true;
            this.ID = "blankReplace";
            if nargin == 1
                this.replaceValue = varargin{1};
            else
                this.replaceValue = NaN;
            end
        end        
    end
end
