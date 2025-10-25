% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents an Import Rule for replacing a string with a value.

% Copyright 2018 The MathWorks, Inc.
classdef StringReplaceRule < internal.matlab.importtool.server.rules.ImportRule 
    properties
        replaceText string;
        replaceValue double;
    end
    
    methods
        function this = StringReplaceRule(txt, value)
            this = this@internal.matlab.importtool.server.rules.ImportRule();
            this.stringReplaceRule = true;
            this.ID = "stringReplace";
            
            this.replaceText = txt;
            this.replaceValue = value;
        end
    end
end
