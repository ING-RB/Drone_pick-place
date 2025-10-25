% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents a Cell Array Output Data Type from Import.

% Copyright 2018-2022 The MathWorks, Inc.

classdef CellArrayOutputType < internal.matlab.importtool.server.output.OutputTypeAdapter
    methods
        function this = CellArrayOutputType
            this@internal.matlab.importtool.server.output.OutputTypeAdapter;
            
            outputStrategy = internal.matlab.importtool.server.output.SingleOutputColumnClassStrategy("string");
            this.setColumnClassStrategy(outputStrategy);
            
            classOptionsStrategy = internal.matlab.importtool.server.output.EmptyColumnClassOptionsStrategy();
            this.setColumnClassOptionsStrategy(classOptionsStrategy);
        end

        function [vars, varNames] = convertFromImportedData(~, tbl)
            % Convert from table to numeric array
            vars = table2cell(tbl);
            idx = cellfun(@(x) ~isnan(str2double(x)), vars);
            vars(idx) = cellfun(@(x) {str2double(x)}, vars(idx));
            varNames = [];
        end
        
        function [code, varsToClear] = getCodeToConvertFromImportedData(this, varName, ~)
            % Generates the code to convert from a table to a numeric array
            code = varName + " = table2cell(" + varName + ");";
            idxVar = matlab.lang.makeUniqueStrings("numIdx", varName);
            code(2) = idxVar + " = cellfun(@(x) ~isnan(str2double(x)), " + varName + ");";
            
            codeStr = varName + "(" + idxVar + ") = cellfun(@(x) {str2double(x)}, " + varName + "(" + idxVar + "))";
            if ~this.showLastOutput
                codeStr = codeStr + ";";
            end
            code(3) = codeStr;
            varsToClear = idxVar;
        end
        
        function code = getFunctionHeaderCode(~)
            % Returns the cell array header line for the function
            code = internal.matlab.importtool.server.ImportUtils.getImportToolMsgFromTag("Codgen_CellArrayHeader");
        end
        
%         function columnClasses = getColumnClassesForImport(~, initialColumnClasses)
%             % Convert any datetime or duration columns to string (Import
%             % Tool doesn't create cell arrays containing individual
%             % datetimes or durations)
%             columnClasses = strrep(initialColumnClasses, 'datetime', 'string');
%             columnClasses = strrep(columnClasses, 'duration', 'string');
%         end
        
        function opts = updateImportOptionsForOutputType(~, origOpts)
            % Cell array produces only 'char' output, not string.
            stringColumns = cellfun(@(x) x == "string", origOpts.VariableTypes);
            opts = setvartype(origOpts, find(stringColumns), 'char');
        end
    end
end
