% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents a Numeric Array Output Data Type from Import.

% Copyright 2018-2019 The MathWorks, Inc.

classdef NumericArrayOutputType < internal.matlab.importtool.server.output.OutputTypeAdapter
    methods
        function this = NumericArrayOutputType
            this@internal.matlab.importtool.server.output.OutputTypeAdapter;
            
            outputStrategy = internal.matlab.importtool.server.output.SingleOutputColumnClassStrategy("double");
            this.setColumnClassStrategy(outputStrategy);
            
            classOptionsStrategy = internal.matlab.importtool.server.output.EmptyColumnClassOptionsStrategy();
            this.setColumnClassOptionsStrategy(classOptionsStrategy);
        end
        
        function [vars, varNames] = convertFromImportedData(~, tbl)
            % Convert from table to numeric array
            vars = table2array(tbl);
            varNames = [];
        end
        
        function [code, varsToClear] = getCodeToConvertFromImportedData(this, varName, ~)
            % Generates the code to convert from a table to a numeric array
            code = varName + " = table2array(" + varName + ")";
            if ~this.showLastOutput
                code = code + ";";
            end
            varsToClear = "";
        end
        
        function code = getFunctionHeaderCode(~)
            % Returns the numeric array header line for the function
            code = internal.matlab.importtool.server.ImportUtils.getImportToolMsgFromTag("Codgen_NumericArrayHeader");
        end
    end
end
