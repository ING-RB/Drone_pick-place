% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is a factory which returns the appropriate ImportRule Matlab class
% based on the rule type, either in text or as a Java class name.

% Copyright 2018 The MathWorks, Inc.

classdef ImportRuleFactory
    methods(Static)
        function v = getImportRuleFromText(ruleType, varargin)
            % Returns the ImportRule class based on the input text
            switch lower(ruleType)
                case "blankreplace"
                    % Blank replacement rule require a replacement value
                    v = internal.matlab.importtool.server.rules.BlankReplaceRule(varargin{1});
                    
                case "excludecolumnswithblanks"
                    v = internal.matlab.importtool.server.rules.ExcludeColumnsWithBlanksRule;

                case "excluderowswithblanks"
                    v = internal.matlab.importtool.server.rules.ExcludeRowsWithBlanksRule;

                case "excludeunimportablecolumns"
                    v = internal.matlab.importtool.server.rules.ExcludeUnimportableColumnRule;

                case "excludeunimportablerows"
                    v = internal.matlab.importtool.server.rules.ExcludeUnimportableRowRule;

                case "nonnumericreplacerule"
                    % Non-numeric replacement may or may not have a replacement
                    % value.  By default it will be NaN.
                    if nargin > 1
                        v = internal.matlab.importtool.server.rules.NonNumericReplaceRule(varargin{1});
                    else
                        v = internal.matlab.importtool.server.rules.NonNumericReplaceRule;
                    end

                case "stringreplace"
                    % String replacement requires the string to replace, and its
                    % replacement value.
                    v = internal.matlab.importtool.server.rules.StringReplaceRule(varargin{1}, varargin{2});
            end
        end
        
        function v = getImportRuleFromJava(javaRule)
            % Returns the ImportRule class based on the Java string input text.
            % javaRule is a Java object representing the rule, which has an
            % applyFcn which uniquely identifies it.
            switch string(javaRule.getApplyFcn)
                case "internal.matlab.importtool.AbstractSpreadsheet.blankReplaceFcn"
                    v = internal.matlab.importtool.server.rules.BlankReplaceRule(javaRule.getReplacementNumber);
                case "internal.matlab.importtool.AbstractSpreadsheet.blankExcludeColumnFcn"
                    v = internal.matlab.importtool.server.rules.ExcludeColumnsWithBlanksRule;
                case "internal.matlab.importtool.AbstractSpreadsheet.blankExcludeRowFcn"
                    v = internal.matlab.importtool.server.rules.ExcludeRowsWithBlanksRule;
                case "internal.matlab.importtool.AbstractSpreadsheet.excludeColumnFcn"
                    v = internal.matlab.importtool.server.rules.ExcludeUnimportableColumnRule;
                case "internal.matlab.importtool.AbstractSpreadsheet.excludeRowFcn"
                    v = internal.matlab.importtool.server.rules.ExcludeUnimportableRowRule;
                case "internal.matlab.importtool.AbstractSpreadsheet.nonNumericReplaceFcn"
                    v = internal.matlab.importtool.server.rules.NonNumericReplaceRule(javaRule.getReplacementNumber);
                case "internal.matlab.importtool.AbstractSpreadsheet.stringReplaceFcn"
                    v = internal.matlab.importtool.server.rules.StringReplaceRule(javaRule.getTargetString, javaRule.getReplacementNumber);
            end
        end
    end
end
