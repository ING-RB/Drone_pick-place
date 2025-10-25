% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents a Table Output Data Type from Import.

% Copyright 2018-2023 The MathWorks, Inc.

classdef TableOutputType < internal.matlab.importtool.server.output.OutputTypeAdapter
    methods
        function [vars, varNames] = convertFromImportedData(~, tbl)
            % No-op. Input is already a table.
            vars = tbl;
            varNames = [];
        end
        
        function [code, varsToClear] = getCodeToConvertFromImportedData(~, ~, ~)
            % No code necessary.  varName is already a table.
            code = "";
            varsToClear = "";
        end
        
        function code = getFunctionHeaderCode(~)
            % Returns the table header line for the function
            code = internal.matlab.importtool.server.ImportUtils.getImportToolMsgFromTag("Codgen_TableHeader");
        end

        function b = requiresOutputConversion(~) 
            % Requires no output conversion from table
            b = false;
        end

        function b = isTabular(~)
            b = true;
        end
    end
end
